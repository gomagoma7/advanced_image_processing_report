import time
from pathlib import Path

import cv2


def capture_with_spacebar(save_folder: Path):
    """
    Capture images from the webcam when spacebar is pressed.
    Press Enter to stop the program.
    """
    # Initialize webcam
    print("Initializing camera...")
    cap = cv2.VideoCapture(0)  # 0 is usually the default webcam
    
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return
    
    # Allow the camera to warm up
    time.sleep(1)
    
    print("Camera ready.")
    print("Press SPACE to take a picture")
    print("Press ENTER to exit")
    
    image_counter = 0
    should_exit = False
    
    while not should_exit:
        # Capture frame-by-frame
        ret, frame = cap.read()
        
        if not ret:
            print("Failed to grab frame")
            break
            
        # Display the frame
        cv2.imshow('Press SPACE to capture, ENTER to exit', frame)
        
        # Wait for key press (30ms delay to keep UI responsive)
        key = cv2.waitKey(30) & 0xFF
        
        # If Space bar is pressed, take a picture
        if key == 32:  # Space bar
            image_name = save_folder.cwd() / f"checkerboard_{image_counter
            }.jpg"
            print(image_name)
            cv2.imwrite(image_name, frame)
            print(f"Image {image_counter} captured and saved as '{image_name}'")
            image_counter += 1
            
        # If Enter key is pressed, exit
        elif key == 13:  # Enter key
            print("\nEnter key pressed. Stopping capture...")
            should_exit = True
    
    # Release the webcam and close windows
    cap.release()
    cv2.destroyAllWindows()
    print(f"Capture stopped. Total images taken: {image_counter}")

if __name__ == "__main__":
    save_folder = Path("/Users/JupiterMokusei/Documents/GitHub/advanced_image_processing_report/report01/checkerboards")
    capture_with_spacebar(save_folder)