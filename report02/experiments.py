import csv
import fnmatch
import json
import os
import time

import cv2
import numpy as np
from tqdm import tqdm


def create_detector(detector_type):
    """Create feature detector"""
    detectors = {
        "SIFT": cv2.SIFT_create(),
        "ORB": cv2.ORB_create(),
        "AKAZE": cv2.AKAZE_create(),
        "KAZE": cv2.KAZE_create(),
        "BRISK": cv2.BRISK_create()
    }
    return detectors[detector_type]


def create_matcher(matcher_type, detector_type):
    """Create feature matcher"""
    if matcher_type == "BF":
        if detector_type in ["ORB", "BRISK"]:
            return cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=False)
        else:
            return cv2.BFMatcher(cv2.NORM_L2, crossCheck=False)
    else:  # FLANN
        if detector_type in ["SIFT", "AKAZE", "KAZE"]:
            index_params = dict(algorithm=1, trees=5)
            search_params = dict(checks=50)
            return cv2.FlannBasedMatcher(index_params, search_params)
        else:
            index_params = dict(algorithm=6, table_number=6, key_size=12, multi_probe_level=1)
            search_params = dict(checks=50)
            return cv2.FlannBasedMatcher(index_params, search_params)


def prepare_descriptors(desc1, desc2, matcher_type, detector_type):
    """Prepare descriptors for FLANN if needed"""
    if matcher_type == "FLANN":
        if detector_type in ["SIFT", "AKAZE", "KAZE"]:
            desc1 = np.float32(desc1)
            desc2 = np.float32(desc2)
        else:
            desc1 = np.uint8(desc1)
            desc2 = np.uint8(desc2)
    return desc1, desc2


def perform_feature_matching(image1_path, image2_path, detector_type="SIFT", 
                            matcher_type="BF", ratio_thresh=0.75, output_dir=None):
    """Core feature matching function"""
    
    # Load images
    img1_color = cv2.imread(image1_path)
    img2_color = cv2.imread(image2_path)
    img1 = cv2.imread(image1_path, cv2.IMREAD_GRAYSCALE)
    img2 = cv2.imread(image2_path, cv2.IMREAD_GRAYSCALE)
    
    if img1 is None or img2 is None:
        return None
    
    # Feature detection
    detector = create_detector(detector_type)
    start_time = time.time()
    kp1, des1 = detector.detectAndCompute(img1, None)
    kp2, des2 = detector.detectAndCompute(img2, None)
    detection_time = time.time() - start_time
    
    if des1 is None or des2 is None or len(kp1) == 0 or len(kp2) == 0:
        return {
            "kp1_count": len(kp1) if kp1 else 0,
            "kp2_count": len(kp2) if kp2 else 0,
            "good_matches": 0, "detection_time": detection_time,
            "matching_time": 0, "ransac_time": 0, "inlier_matches": 0,
            "detector": detector_type, "matcher": matcher_type,
            "match_quality": 0.0, "status": "no_features"
        }
    
    # Feature matching
    des1, des2 = prepare_descriptors(des1, des2, matcher_type, detector_type)
    matcher = create_matcher(matcher_type, detector_type)
    
    start_time = time.time()
    matches = matcher.knnMatch(des1, des2, k=2)
    matching_time = time.time() - start_time
    
    # Ratio test
    good_matches = []
    if matches:
        for match_list in matches:
            if len(match_list) >= 2:
                m, n = match_list
                if m.distance < ratio_thresh * n.distance:
                    good_matches.append(m)
    
    match_quality = len(good_matches) / min(len(kp1), len(kp2)) * 100 if min(len(kp1), len(kp2)) > 0 else 0
    
    # Save visualizations
    if output_dir:
        os.makedirs(output_dir, exist_ok=True)
        base_name = os.path.basename(image1_path).split('_')[0]
        
        # Keypoints
        img_kp1 = cv2.drawKeypoints(img1_color, kp1, None, color=(0, 255, 0))
        img_kp2 = cv2.drawKeypoints(img2_color, kp2, None, color=(0, 255, 0))
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_kp1.png", img_kp1)
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_kp2.png", img_kp2)
        
        # Matches
        img_matches = cv2.drawMatches(img1_color, kp1, img2_color, kp2, good_matches, None,
                                     flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)
        cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_{matcher_type}_matches.png", img_matches)
    
    # RANSAC and registration
    ransac_time = 0
    inlier_matches = 0
    registration_success = False
    
    if len(good_matches) > 4:
        src_pts = np.float32([kp1[m.queryIdx].pt for m in good_matches]).reshape(-1, 1, 2)
        dst_pts = np.float32([kp2[m.trainIdx].pt for m in good_matches]).reshape(-1, 1, 2)
        
        start_time = time.time()
        H, mask = cv2.findHomography(src_pts, dst_pts, cv2.RANSAC, 5.0)
        ransac_time = time.time() - start_time
        
        if mask is not None:
            inlier_matches = sum(mask.ravel())
        
        if H is not None and inlier_matches > 0:
            registration_success = True
            if output_dir:
                img1_warped = cv2.warpPerspective(img1_color, H, (img2.shape[1], img2.shape[0]))
                gray_warped = cv2.cvtColor(img1_warped, cv2.COLOR_BGR2GRAY)
                ret, mask_warped = cv2.threshold(gray_warped, 1, 255, cv2.THRESH_BINARY)
                mask_warped_inv = cv2.bitwise_not(mask_warped)
                img2_masked = cv2.bitwise_and(img2_color, img2_color, mask=mask_warped_inv)
                img_registered = cv2.add(img2_masked, img1_warped)
                cv2.imwrite(f"{output_dir}/{base_name}_{detector_type}_{matcher_type}_registration.png", 
                           img_registered)
    
    # Status
    if len(good_matches) == 0:
        status = "no_matches"
    elif len(good_matches) < 4:
        status = "insufficient_matches"
    elif not registration_success:
        status = "registration_failed"
    else:
        status = "success"
    
    return {
        "kp1_count": len(kp1), "kp2_count": len(kp2), "good_matches": len(good_matches),
        "detection_time": detection_time, "matching_time": matching_time, "ransac_time": ransac_time,
        "inlier_matches": inlier_matches, "detector": detector_type, "matcher": matcher_type,
        "match_quality": match_quality, "status": status,
        "image1_path": image1_path, "image2_path": image2_path
    }


def find_image_pairs(image_dir):
    """Find image pairs in directory"""
    image_files = []
    for root, _, files in os.walk(image_dir):
        for filename in files:
            if any(filename.lower().endswith(ext) for ext in ['.jpg', '.jpeg', '.png']):
                image_files.append(os.path.join(root, filename))
    
    image_pairs = {}
    for filepath in image_files:
        filename = os.path.basename(filepath)
        base_name_parts = filename.rsplit('_', 1)
        if len(base_name_parts) == 2:
            base_name = base_name_parts[0]
            suffix_with_ext = base_name_parts[1]
            
            if base_name not in image_pairs:
                image_pairs[base_name] = {'a': None, 'b': None}
            
            if suffix_with_ext.lower().startswith('a.'):
                image_pairs[base_name]['a'] = filepath
            elif suffix_with_ext.lower().startswith('b.'):
                image_pairs[base_name]['b'] = filepath
    
    return {k: v for k, v in image_pairs.items() if v.get('a') and v.get('b')}


def analyze_results(results_list, output_dir):
    """Analyze and save results"""
    if not results_list:
        return
    
    valid_results = [r for r in results_list if r is not None]
    analysis_dir = os.path.join(output_dir, "analysis")
    os.makedirs(analysis_dir, exist_ok=True)
    
    # Save CSV
    with open(f"{analysis_dir}/detailed_results.csv", 'w', newline='', encoding='utf-8') as csvfile:
        fieldnames = ['base_name', 'detector', 'matcher', 'kp1_count', 'kp2_count',
                     'good_matches', 'inlier_matches', 'match_quality', 'detection_time',
                     'matching_time', 'ransac_time', 'status']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        
        for result in valid_results:
            base_name = os.path.basename(result['image1_path']).split('_')[0]
            writer.writerow({
                'base_name': base_name, 'detector': result['detector'], 'matcher': result['matcher'],
                'kp1_count': result['kp1_count'], 'kp2_count': result['kp2_count'],
                'good_matches': result['good_matches'], 'inlier_matches': result['inlier_matches'],
                'match_quality': f"{result['match_quality']:.2f}",
                'detection_time': f"{result['detection_time']:.4f}",
                'matching_time': f"{result['matching_time']:.4f}",
                'ransac_time': f"{result['ransac_time']:.4f}",
                'status': result['status']
            })
    
    # Analyze by detector
    detector_analysis = {}
    matcher_analysis = {}
    
    for result in valid_results:
        detector = result['detector']
        matcher = result['matcher']
        
        if detector not in detector_analysis:
            detector_analysis[detector] = {
                'total_runs': 0, 'successful_runs': 0, 'total_matches': 0,
                'total_inliers': 0, 'total_detection_time': 0.0, 'avg_match_quality': 0.0
            }
        
        if matcher not in matcher_analysis:
            matcher_analysis[matcher] = {
                'total_runs': 0, 'successful_runs': 0, 'total_matches': 0, 'total_matching_time': 0.0
            }
        
        detector_analysis[detector]['total_runs'] += 1
        detector_analysis[detector]['total_matches'] += result['good_matches']
        detector_analysis[detector]['total_inliers'] += result['inlier_matches']
        detector_analysis[detector]['total_detection_time'] += result['detection_time']
        detector_analysis[detector]['avg_match_quality'] += result['match_quality']
        
        matcher_analysis[matcher]['total_runs'] += 1
        matcher_analysis[matcher]['total_matches'] += result['good_matches']
        matcher_analysis[matcher]['total_matching_time'] += result['matching_time']
        
        if result['status'] == 'success':
            detector_analysis[detector]['successful_runs'] += 1
            matcher_analysis[matcher]['successful_runs'] += 1
    
    # Calculate averages
    for detector in detector_analysis:
        stats = detector_analysis[detector]
        if stats['total_runs'] > 0:
            stats['avg_matches'] = stats['total_matches'] / stats['total_runs']
            stats['avg_inliers'] = stats['total_inliers'] / stats['total_runs']
            stats['avg_detection_time'] = stats['total_detection_time'] / stats['total_runs']
            stats['avg_match_quality'] = stats['avg_match_quality'] / stats['total_runs']
            stats['success_rate'] = stats['successful_runs'] / stats['total_runs'] * 100
    
    for matcher in matcher_analysis:
        stats = matcher_analysis[matcher]
        if stats['total_runs'] > 0:
            stats['avg_matches'] = stats['total_matches'] / stats['total_runs']
            stats['avg_matching_time'] = stats['total_matching_time'] / stats['total_runs']
            stats['success_rate'] = stats['successful_runs'] / stats['total_runs'] * 100
    
    # Save JSON summary
    summary_data = {
        'detector_analysis': detector_analysis,
        'matcher_analysis': matcher_analysis,
        'total_experiments': len(valid_results)
    }
    
    with open(f"{analysis_dir}/analysis_summary.json", 'w', encoding='utf-8') as f:
        json.dump(summary_data, f, indent=2, ensure_ascii=False, default=float)


def main():
    """Main experiment function"""
    image_dir = "match_pics/"
    output_base_dir = "feature_matching_results"
    
    if not os.path.exists(output_base_dir):
        os.makedirs(output_base_dir)
    
    # Find image pairs
    image_pairs = find_image_pairs(image_dir)
    
    # Configuration
    detector_types = ["SIFT", "ORB", "AKAZE", "KAZE", "BRISK"]
    matcher_types = ["BF", "FLANN"]
    
    # Create all combinations
    all_combinations = []
    for base_name, paths in sorted(image_pairs.items()):
        for detector_type in detector_types:
            for matcher_type in matcher_types:
                all_combinations.append({
                    "base_name": base_name,
                    "image1_path": paths['a'],
                    "image2_path": paths['b'],
                    "detector_type": detector_type,
                    "matcher_type": matcher_type
                })
    
    # Run experiments
    all_results = []
    for combo in tqdm(all_combinations, desc="Running experiments"):
        current_output_dir = os.path.join(output_base_dir, combo["base_name"])
        os.makedirs(current_output_dir, exist_ok=True)
        
        result = perform_feature_matching(
            combo["image1_path"], combo["image2_path"],
            combo["detector_type"], combo["matcher_type"],
            output_dir=current_output_dir
        )
        
        all_results.append(result)
    
    # Analyze results
    analyze_results(all_results, output_base_dir)


if __name__ == "__main__":
    main()