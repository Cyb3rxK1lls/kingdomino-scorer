import requests
import json
from KingdominoBoard import KingdominoBoard
from Tile import Tile

# send image file
filename = input("enter image filepath: ")
response = requests.post("http://127.0.0.1:5000/file", files={'image': open(filename, 'rb')})

# get list of detections
dictionary = json.loads(response.text)
detections = dictionary['labels'].split(',')

# get map of detection to tile name
with open("classes.txt") as file:
    labels = file.read().split("\n")

tiles = []
for tile in detections:
    key, x_mid, y_mid, width, height = tile.split(" ")
    tiles.append(Tile(labels[int(key)], x_mid, y_mid, width, height))

board = KingdominoBoard(tiles)
x_dim, y_dim = board.get_dimensions()
print("\n-----------------\nBoard Dimensions\n-----------------\n", x_dim, "x", y_dim)
print("\n-------------\nBoard Values\n-------------\n" + board.display_tiles())
print("\n-------------\nBoard Scores\n-------------\n" + board.display_scores())
print("\n------------\nFinal Score\n------------\n", board.get_score(), "\n\n")
