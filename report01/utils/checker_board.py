import numpy as np
from PIL import Image


def create_checkerboard(size=8, square_size=50):
    """
    Create a black and white checkerboard pattern.
    
    Parameters:
    - size: Number of squares in each dimension (default: 8 for 8x8 checkerboard)
    - square_size: Pixel size of each square (default: 50)
    
    Returns:
    - Image object with checkerboard pattern
    """
    # Create an empty array
    board_size = size * square_size
    board = np.zeros((board_size, board_size), dtype=np.uint8)
    
    # Fill the checkerboard pattern
    for i in range(size):
        for j in range(size):
            if (i + j) % 2 == 0:
                # White square (255)
                board[i*square_size:(i+1)*square_size, j*square_size:(j+1)*square_size] = 255
                
    # Convert numpy array to PIL Image
    img = Image.fromarray(board)
    return img

# Create an 8x8 checkerboard with 50px squares
checkerboard = create_checkerboard(8, 50)

# Save as JPEG
checkerboard.save("checkerboard.jpg")

print("Checkerboard image saved as 'checkerboard.jpg'")