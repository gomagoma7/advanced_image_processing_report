from pathlib import Path

import cv2 as cv
import numpy as np


def find_chessboard_corner(chessboard_path: Path, board_size=(9, 9)):
    # termination criteria
    criteria = (cv.TERM_CRITERIA_EPS + cv.TERM_CRITERIA_MAX_ITER, 30, 0.001)
    
    # prepare object points, like (0,0,0), (1,0,0), (2,0,0) ....,(6,5,0)
    objp = np.zeros((board_size[0]*board_size[1],3), np.float32)
    objp[:,:2] = np.mgrid[0:board_size[0],0:board_size[1]].T.reshape(-1,2)
    
    # Arrays to store object points and image points from all the images.
    objpoints = [] # 3d point in real world space
    imgpoints = [] # 2d points in image plane.
    
    images = chessboard_path.glob('*.jpg')
    for fname in images:
        
        if fname not in chessboard_path.glob("checkerboard.jpg"):
            img = cv.imread(fname)
            gray = cv.cvtColor(img, cv.COLOR_BGR2GRAY)
        
            # Find the chess board corners
            ret, corners = cv.findChessboardCorners(gray, board_size, None)
        
            # If found, add object points, image points (after refining them)
            if ret:
                print(fname)
                objpoints.append(objp)
        
                corners2 = cv.cornerSubPix(gray,corners, (11,11), (-1,-1), criteria)
                imgpoints.append(corners2)
        
                # Draw and display the corners
                cv.drawChessboardCorners(img, board_size, corners2, ret)
                cv.imshow('img', img)
                cv.waitKey(1000)
            
    ret, mtx, dist, rvecs, tvecs = cv.calibrateCamera(objpoints, imgpoints, gray.shape[::-1], None, None)
    
    cv.destroyAllWindows()
    
    mean_error = 0
    for i in range(len(objpoints)):
        imgpoints2, _ = cv.projectPoints(objpoints[i], rvecs[i], tvecs[i], mtx, dist)
        error = cv.norm(imgpoints[i], imgpoints2, cv.NORM_L2)/len(imgpoints2)
        mean_error += error
    
    print( "total error: {}".format(mean_error/len(objpoints)) )
    
    return ret, mtx, dist, rvecs, tvecs
    