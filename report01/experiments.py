"""
完璧なOpenCVカメラ校正プログラム
手動評価関数を省き、OpenCVの結果のみを信頼

機能:
1. 実チェッカーボード画像からのコーナー検出
2. OpenCVによる高精度カメラ校正
3. 結果の自動保存・読み込み
4. 歪み補正のデモンストレーション
5. レポート用の包括的な結果出力
"""

import glob
import json
from pathlib import Path

import cv2
import matplotlib.pyplot as plt
import numpy as np
import seaborn as sns

# 日本語フォント設定
plt.rcParams['font.size'] = 12
sns.set_style("whitegrid")

class PerfectOpenCVCalibration:
    def __init__(self, checkerboard_size=(7, 7), square_size=20.0, output_dir="calibration_results"):
        """
        完璧なOpenCVカメラ校正クラス
        
        Parameters:
        checkerboard_size: (cols, rows) 内部コーナー数
        square_size: 正方形のサイズ（mm）
        output_dir: 結果保存ディレクトリ
        """
        self.checkerboard_size = checkerboard_size
        self.square_size = square_size
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
        # 3D座標の準備
        self.objp = np.zeros((checkerboard_size[0] * checkerboard_size[1], 3), np.float32)
        self.objp[:, :2] = np.mgrid[0:checkerboard_size[0], 
                                   0:checkerboard_size[1]].T.reshape(-1, 2)
        self.objp *= square_size
        
        # 校正結果保存用
        self.camera_matrix = None
        self.dist_coeffs = None
        self.rvecs = None
        self.tvecs = None
        self.rms_error = None
        self.object_points = []
        self.image_points = []
        self.image_files = []
        self.image_size = None
    
    def load_images_from_directory(self, image_dir):
        """ディレクトリから画像を読み込み"""
        image_dir = Path(image_dir)
        image_extensions = ['*.jpg', '*.jpeg', '*.png', '*.bmp', '*.tiff']
        
        image_files = []
        for ext in image_extensions:
            image_files.extend(glob.glob(str(image_dir / ext)))
            image_files.extend(glob.glob(str(image_dir / ext.upper())))
        
        print(f"Found {len(image_files)} images in {image_dir}")
        return sorted(image_files)
    
    def process_images(self, image_files, show_progress=True):
        """複数画像のコーナー検出処理"""
        successful_detections = 0
        failed_detections = 0
        
        print(f"Processing {len(image_files)} images...")
        
        for i, image_file in enumerate(image_files):
            if show_progress and (i + 1) % 5 == 0:
                print(f"Progress: {i + 1}/{len(image_files)} images processed")
            
            # 画像読み込み
            img = cv2.imread(image_file)
            if img is None:
                print(f"✗ Could not load {Path(image_file).name}")
                failed_detections += 1
                continue
            
            # 画像サイズを記録（初回のみ）
            if self.image_size is None:
                self.image_size = img.shape[:2][::-1]  # (width, height)
            
            # グレースケール変換
            gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
            
            # コーナー検出
            ret, corners = cv2.findChessboardCorners(
                gray, self.checkerboard_size,
                cv2.CALIB_CB_ADAPTIVE_THRESH + cv2.CALIB_CB_FAST_CHECK + cv2.CALIB_CB_NORMALIZE_IMAGE
            )
            
            if ret:
                # サブピクセル精度でコーナーを改良
                criteria = (cv2.TERM_CRITERIA_EPS + cv2.TERM_CRITERIA_MAX_ITER, 30, 0.001)
                corners = cv2.cornerSubPix(gray, corners, (11, 11), (-1, -1), criteria)
                
                # データを保存
                self.object_points.append(self.objp)
                self.image_points.append(corners)
                self.image_files.append(image_file)
                
                successful_detections += 1
                print(f"✓ Corners detected in {Path(image_file).name}: {len(corners)} points")
            else:
                failed_detections += 1
                print(f"✗ No corners detected in {Path(image_file).name}")
        
        print(f"\nCorner Detection Summary:")
        print(f"✓ Successful: {successful_detections}")
        print(f"✗ Failed: {failed_detections}")
        print(f"Success rate: {successful_detections/(successful_detections+failed_detections)*100:.1f}%")
        
        return successful_detections > 0
    
    def calibrate_camera(self):
        """OpenCVによるカメラ校正"""
        if len(self.object_points) < 3:
            print("Error: Need at least 3 images for calibration")
            return False
        
        print(f"\nCalibrating camera with {len(self.object_points)} images...")
        print("Using OpenCV's cv2.calibrateCamera()...")
        
        # OpenCVカメラ校正実行
        self.rms_error, self.camera_matrix, self.dist_coeffs, self.rvecs, self.tvecs = cv2.calibrateCamera(
            self.object_points, self.image_points, self.image_size, None, None,
            flags=cv2.CALIB_RATIONAL_MODEL  # 高次歪みモデルを使用
        )
        
        print(f"✓ Calibration successful!")
        print(f"RMS reprojection error: {self.rms_error:.4f} pixels")
        
        return True
    
    def analyze_calibration_results(self):
        """校正結果の詳細分析"""
        if self.camera_matrix is None:
            print("Error: Camera not calibrated yet")
            return None
        
        print("\n" + "="*60)
        print("OPENCV CALIBRATION RESULTS ANALYSIS")
        print("="*60)
        
        # カメラパラメータの分析
        fx, fy = self.camera_matrix[0, 0], self.camera_matrix[1, 1]
        cx, cy = self.camera_matrix[0, 2], self.camera_matrix[1, 2]
        
        print(f"✓ RMS Reprojection Error: {self.rms_error:.4f} pixels")
        print(f"\nCamera Intrinsic Parameters:")
        print(f"  Focal length: fx={fx:.2f}, fy={fy:.2f} pixels")
        print(f"  Principal point: cx={cx:.2f}, cy={cy:.2f}")
        print(f"  Aspect ratio: {fy/fx:.6f}")
        print(f"  Image size: {self.image_size[0]}×{self.image_size[1]}")
        
        # 歪み係数の分析
        dist_coeffs = self.dist_coeffs.flatten()
        print(f"\nDistortion Coefficients:")
        print(f"  Radial distortion:")
        print(f"    k1 = {dist_coeffs[0]:.6f}")
        print(f"    k2 = {dist_coeffs[1]:.6f}")
        if len(dist_coeffs) > 4:
            print(f"    k3 = {dist_coeffs[4]:.6f}")
        print(f"  Tangential distortion:")
        print(f"    p1 = {dist_coeffs[2]:.6f}")
        print(f"    p2 = {dist_coeffs[3]:.6f}")
        
        # 品質評価（実用的な基準に修正）
        print(f"\nCalibration Quality Assessment:")
        if self.rms_error < 1.0:
            quality = "Excellent"
            print(f"✓ {quality} calibration (< 1.0 pixels)")
        elif self.rms_error < 2.0:
            quality = "Good"
            print(f"✓ {quality} calibration (< 2.0 pixels)")
        elif self.rms_error < 3.0:
            quality = "Acceptable"
            print(f"✓ {quality} calibration (< 3.0 pixels)")
        else:
            quality = "Poor"
            print(f"✗ {quality} calibration (>= 3.0 pixels)")
        
        # 実用性の判定
        print(f"\nPractical Usability:")
        if self.rms_error < 2.0:
            print("✓ Suitable for high-precision applications")
        elif self.rms_error < 4.0:
            print("✓ Suitable for general computer vision applications")
        else:
            print("△ May require improvement for precision applications")
        
        return {
            'rms_error': self.rms_error,
            'camera_matrix': self.camera_matrix,
            'dist_coeffs': self.dist_coeffs,
            'quality': quality,
            'fx': fx, 'fy': fy, 'cx': cx, 'cy': cy,
            'aspect_ratio': fy/fx,
            'image_size': self.image_size,
            'num_images': len(self.object_points)
        }
    
    def visualize_results(self):
        """結果の可視化"""
        if self.camera_matrix is None:
            print("Error: Camera not calibrated yet")
            return
        
        fig, ((ax1, ax2), (ax3, ax4)) = plt.subplots(2, 2, figsize=(15, 12))
        
        # 1. カメラパラメータ
        params = ['fx', 'fy', 'cx', 'cy']
        values = [self.camera_matrix[0,0], self.camera_matrix[1,1], 
                 self.camera_matrix[0,2], self.camera_matrix[1,2]]
        colors = ['red', 'green', 'blue', 'orange']
        
        bars1 = ax1.bar(params, values, color=colors, alpha=0.7)
        ax1.set_ylabel('Parameter Value (pixels)')
        ax1.set_title('Camera Intrinsic Parameters')
        ax1.grid(True, alpha=0.3)
        
        # 値をバーの上に表示
        for bar, value in zip(bars1, values):
            ax1.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max(values)*0.01,
                    f'{value:.1f}', ha='center', va='bottom')
        
        # 2. 歪み係数（主要な5つ）
        dist_labels = ['k1', 'k2', 'p1', 'p2', 'k3']
        dist_values = self.dist_coeffs.flatten()[:5]
        colors = ['red' if abs(v) > 0.1 else 'blue' if abs(v) > 0.01 else 'gray' for v in dist_values]
        
        bars2 = ax2.bar(dist_labels, dist_values, color=colors, alpha=0.7)
        ax2.set_ylabel('Distortion Coefficient')
        ax2.set_title('Distortion Coefficients')
        ax2.grid(True, alpha=0.3)
        
        # 3. 校正品質指標
        quality_metrics = ['RMS Error', 'Good (<2.0)', 'Excellent (<1.0)']
        quality_values = [self.rms_error, 1.0, 0.5]
        quality_colors = ['blue', 'orange', 'green']
        
        bars3 = ax3.bar(quality_metrics, quality_values, color=quality_colors, alpha=0.7)
        ax3.set_ylabel('Error (pixels)')
        ax3.set_title('Calibration Quality Metrics')
        ax3.grid(True, alpha=0.3)
        
        # 値をバーの上に表示
        for bar, value in zip(bars3, quality_values):
            ax3.text(bar.get_x() + bar.get_width()/2, bar.get_height() + max(quality_values)*0.01,
                    f'{value:.3f}', ha='center', va='bottom')
        
        # 4. 画像使用状況
        total_images = len(self.image_files) if hasattr(self, 'image_files') else 0
        used_images = len(self.object_points)
        failed_images = total_images - used_images if total_images > 0 else 0
        
        usage_labels = ['Used Images', 'Failed Detection']
        usage_values = [used_images, failed_images]
        usage_colors = ['green', 'red']
        
        ax4.pie(usage_values, labels=usage_labels, colors=usage_colors, autopct='%1.1f%%',
               startangle=90)
        ax4.set_title(f'Image Usage (Total: {total_images})')
        
        plt.tight_layout()
        plt.savefig(str(self.output_dir / 'opencv_calibration_analysis.png'), dpi=300, bbox_inches='tight')
        plt.show()
    
    def demonstrate_undistortion(self, image_index=0):
        """歪み補正のデモンストレーション"""
        if self.camera_matrix is None:
            print("Error: Camera not calibrated yet")
            return
        
        if len(self.image_files) == 0:
            print("No images available for undistortion demo")
            return
        
        if image_index >= len(self.image_files):
            image_index = 0
        
        # 元画像を読み込み
        img_path = self.image_files[image_index]
        img = cv2.imread(img_path)
        
        if img is None:
            print(f"Could not load image: {img_path}")
            return
        
        print(f"Demonstrating undistortion on: {Path(img_path).name}")
        
        # 歪み補正パラメータの計算
        h, w = img.shape[:2]
        new_camera_matrix, roi = cv2.getOptimalNewCameraMatrix(
            self.camera_matrix, self.dist_coeffs, (w, h), 1, (w, h)
        )
        
        # 歪み補正実行
        undistorted = cv2.undistort(img, self.camera_matrix, 
                                   self.dist_coeffs, None, new_camera_matrix)
        
        # ROIでクロップ
        x, y, w_roi, h_roi = roi
        if w_roi > 0 and h_roi > 0:
            undistorted_cropped = undistorted[y:y+h_roi, x:x+w_roi]
        else:
            undistorted_cropped = undistorted
        
        # 比較表示
        fig, axes = plt.subplots(1, 3, figsize=(18, 6))
        
        # 元画像
        axes[0].imshow(cv2.cvtColor(img, cv2.COLOR_BGR2RGB))
        axes[0].set_title('Original Image\n(with distortion)')
        axes[0].axis('off')
        
        # 歪み補正後
        axes[1].imshow(cv2.cvtColor(undistorted, cv2.COLOR_BGR2RGB))
        axes[1].set_title('Undistorted Image\n(full frame)')
        axes[1].axis('off')
        
        # クロップ後
        axes[2].imshow(cv2.cvtColor(undistorted_cropped, cv2.COLOR_BGR2RGB))
        axes[2].set_title('Undistorted & Cropped\n(valid region)')
        axes[2].axis('off')
        
        plt.tight_layout()
        plt.savefig(str(self.output_dir / 'undistortion_demo.png'), dpi=300, bbox_inches='tight')
        plt.show()
        
        print("✓ Undistortion demonstration completed!")
        print(f"Original size: {img.shape[:2]}")
        print(f"Valid ROI: x={x}, y={y}, w={w_roi}, h={h_roi}")
        
        return undistorted, undistorted_cropped
    
    def save_results(self):
        """校正結果をファイルに保存"""
        if self.camera_matrix is None:
            print("No calibration results to save")
            return
        
        # NumPy形式で校正データ保存
        np.savez(str(self.output_dir / 'opencv_calibration.npz'),
                camera_matrix=self.camera_matrix,
                dist_coeffs=self.dist_coeffs,
                rvecs=self.rvecs,
                tvecs=self.tvecs,
                rms_error=self.rms_error,
                object_points=self.object_points,
                image_points=self.image_points,
                checkerboard_size=self.checkerboard_size,
                square_size=self.square_size,
                image_size=self.image_size)
        
        # JSON形式でサマリー保存
        summary = {
            'calibration_info': {
                'checkerboard_size': self.checkerboard_size,
                'square_size_mm': float(self.square_size),
                'num_images_used': len(self.object_points),
                'image_size': list(self.image_size),
                'rms_error_pixels': float(self.rms_error)
            },
            'camera_matrix': {
                'fx': float(self.camera_matrix[0, 0]),
                'fy': float(self.camera_matrix[1, 1]),
                'cx': float(self.camera_matrix[0, 2]),
                'cy': float(self.camera_matrix[1, 2]),
                'aspect_ratio': float(self.camera_matrix[1, 1] / self.camera_matrix[0, 0])
            },
            'distortion_coefficients': {
                'k1': float(self.dist_coeffs[0, 0]),
                'k2': float(self.dist_coeffs[0, 1]),
                'p1': float(self.dist_coeffs[0, 2]),
                'p2': float(self.dist_coeffs[0, 3]),
                'k3': float(self.dist_coeffs[0, 4]) if len(self.dist_coeffs[0]) > 4 else 0.0
            }
        }
        
        with open(self.output_dir / 'calibration_summary.json', 'w') as f:
            json.dump(summary, f, indent=2)
        
        # テキスト形式でレポート保存
        with open(self.output_dir / 'calibration_report.txt', 'w') as f:
            f.write("OpenCV Camera Calibration Report\n")
            f.write("="*50 + "\n\n")
            f.write(f"Experiment Date: {import_datetime().datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n")
            f.write(f"OpenCV Version: {cv2.__version__}\n\n")
            
            f.write("Configuration:\n")
            f.write(f"- Checkerboard size: {self.checkerboard_size} (internal corners)\n")
            f.write(f"- Square size: {self.square_size} mm\n")
            f.write(f"- Images processed: {len(self.object_points)}\n")
            f.write(f"- Image resolution: {self.image_size[0]}×{self.image_size[1]}\n\n")
            
            f.write("Calibration Results:\n")
            f.write(f"- RMS reprojection error: {self.rms_error:.4f} pixels\n")
            f.write(f"- Focal length: fx={self.camera_matrix[0,0]:.2f}, fy={self.camera_matrix[1,1]:.2f}\n")
            f.write(f"- Principal point: cx={self.camera_matrix[0,2]:.2f}, cy={self.camera_matrix[1,2]:.2f}\n")
            f.write(f"- Aspect ratio: {self.camera_matrix[1,1]/self.camera_matrix[0,0]:.6f}\n\n")
            
            f.write("Quality Assessment:\n")
            if self.rms_error < 1.0:
                f.write("✓ Excellent calibration (< 1.0 pixels)\n")
            elif self.rms_error < 2.0:
                f.write("✓ Good calibration (< 2.0 pixels)\n")
            elif self.rms_error < 3.0:
                f.write("✓ Acceptable calibration (< 3.0 pixels)\n")
            else:
                f.write("✗ Poor calibration (>= 3.0 pixels)\n")
        
        print(f"✓ All results saved to {self.output_dir}/")
        print("Generated files:")
        print(f"  - opencv_calibration.npz (calibration data)")
        print(f"  - calibration_summary.json (structured summary)")
        print(f"  - calibration_report.txt (human-readable report)")
        print(f"  - opencv_calibration_analysis.png (visualization)")
        print(f"  - undistortion_demo.png (undistortion demo)")
    
    def load_results(self):
        """保存された校正結果を読み込み"""
        calib_file = self.output_dir / 'opencv_calibration.npz'
        
        if not calib_file.exists():
            print(f"No saved calibration found at {calib_file}")
            return False
        
        try:
            data = np.load(calib_file, allow_pickle=True)
            self.camera_matrix = data['camera_matrix']
            self.dist_coeffs = data['dist_coeffs']
            self.rvecs = data['rvecs']
            self.tvecs = data['tvecs']
            self.rms_error = float(data['rms_error'])
            self.object_points = list(data['object_points'])
            self.image_points = list(data['image_points'])
            self.image_size = tuple(data['image_size'])
            
            print(f"✓ Loaded calibration results from {calib_file}")
            print(f"  - RMS error: {self.rms_error:.4f} pixels")
            print(f"  - Images used: {len(self.object_points)}")
            return True
            
        except Exception as e:
            print(f"Error loading calibration: {e}")
            return False
    
    def run_complete_calibration(self, image_dir, skip_if_exists=True):
        """完全な校正プロセスを実行"""
        print("Perfect OpenCV Camera Calibration")
        print("="*60)
        print(f"Checkerboard: {self.checkerboard_size} corners, {self.square_size}mm squares")
        print(f"Output directory: {self.output_dir}")
        print()
        
        # 既存結果のチェック
        if skip_if_exists and (self.output_dir / 'opencv_calibration.npz').exists():
            print("Found existing calibration results!")
            choice = input("Load existing results? (y/n): ").lower().strip()
            if choice in ['y', 'yes', '']:
                if self.load_results():
                    print("\nSkipping calibration, using saved results...")
                    self.analyze_calibration_results()
                    self.visualize_results()
                    self.demonstrate_undistortion()
                    return True
        
        # 新規校正の実行
        print("Step 1: Loading and processing images...")
        image_files = self.load_images_from_directory(image_dir)
        
        if not image_files:
            print("No images found!")
            return False
        
        success = self.process_images(image_files)
        if not success:
            print("Failed to detect corners in any image!")
            return False
        
        print(f"\nStep 2: Calibrating camera with OpenCV...")
        if not self.calibrate_camera():
            print("Calibration failed!")
            return False
        
        print(f"\nStep 3: Analyzing calibration results...")
        results = self.analyze_calibration_results()
        
        print(f"\nStep 4: Visualizing results...")
        self.visualize_results()
        
        print(f"\nStep 5: Demonstrating undistortion...")
        self.demonstrate_undistortion()
        
        print(f"\nStep 6: Saving all results...")
        self.save_results()
        
        print(f"\n" + "="*60)
        print("PERFECT OPENCV CALIBRATION COMPLETED!")
        print("="*60)
        print(f"✓ RMS Error: {self.rms_error:.4f} pixels")
        print(f"✓ Quality: {'Excellent' if self.rms_error < 1.0 else 'Good' if self.rms_error < 2.0 else 'Acceptable' if self.rms_error < 3.0 else 'Poor'}")
        print(f"✓ Images used: {len(self.object_points)}")
        print(f"✓ All results saved to: {self.output_dir}/")
        
        return True


def import_datetime():
    """動的にdatetimeをインポート"""
    import datetime
    return datetime


# メイン実行部分
if __name__ == "__main__":
    print("Perfect OpenCV Camera Calibration Program")
    print("="*70)
    print(f"OpenCV version: {cv2.__version__}")
    print()
    
    # 設定
    checkerboard_size = (7, 7)  # 内部コーナー数
    square_size = 20.0  # mm
    image_directory = "./checkerboards"
    output_directory = "./calibration_results"
    
    # 校正実行
    calibrator = PerfectOpenCVCalibration(
        checkerboard_size=checkerboard_size,
        square_size=square_size,
        output_dir=output_directory
    )
    
    # 完全な校正プロセスを実行
    success = calibrator.run_complete_calibration(
        image_dir=image_directory,
        skip_if_exists=True  # 既存結果があれば確認
    )
    
    if success:
        print("\n🎉 Perfect calibration completed successfully!")
        print("Ready for report writing!")
    else:
        print("\n❌ Calibration failed. Please check your images.")
    
    print("\n" + "="*70)
    print("For report writing:")
    print(f"1. Check results in: {output_directory}/")
    print("2. Use calibration_report.txt for numerical results")
    print("3. Include opencv_calibration_analysis.png in your report")
    print("4. Use undistortion_demo.png to show practical benefits")
    print("="*70)