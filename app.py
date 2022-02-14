from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from PIL import Image
import os

app = Flask(__name__)
api = Api(app)


class Hello(Resource):

    def __init__(self):
        self.requests = 0

    def get(self):
        self.requests += 1
        return "hello, world!"

    def post(self):
        self.requests += 1
        data = request.get_json()
        return jsonify({'data_received': data}), 201


class File(Resource):

    def __init__(self):
        self.files = 0

    def get(self):
        name = request.args.get('name')
        return f"your name is {name }!! {self.files['name']}"

    def post(self):
        self.files += 1
        file = request.files['image']

        # Read the image via file.stream
        img = Image.open(file.stream)
        img = img.resize((640, 640))
        img.save(os.path.join('temp', file.filename))

        # run through model

        return jsonify({'file': file.filename, 'msg': 'success', 'size': [img.width, img.height]})


api.add_resource(Hello, '/')
api.add_resource(File, '/file')

if __name__ == '__main__':
    app.run(debug=True)
