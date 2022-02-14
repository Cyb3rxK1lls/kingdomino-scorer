import requests
import json
import os

img = open(os.path.join('send', 'IMG_7039.JPG'), 'rb')

files = {'image': img}
response = requests.post("http://127.0.0.1:5000/file", files=files)

print(response.text)
