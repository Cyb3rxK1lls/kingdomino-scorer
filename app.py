from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from PIL import Image
from models.detect import run
import os

app = Flask(__name__)
api = Api(app)


class File(Resource):

    def post(self):
        img_file = request.files['image']

        # Read the image via file.stream
        img = Image.open(img_file.stream)
        img = img.resize((640, 640))
        img.save(os.path.join('temp', img_file.filename))

        # run through models and receive list
        run(weights='models/kd_mod_med.pt', source=os.path.join('temp', img_file.filename),
            project='receive', name='', exist_ok=True)
        txt_filename = img_file.filename.split('.')[0] + '.txt'
        with open(os.path.join('receive', txt_filename)) as txt_file:
            labels = txt_file.read()

        # remove img from temp
        os.remove(os.path.join('temp', img_file.filename))

        return jsonify({'result': 'success', 'labels': labels.replace('\n', ',')[:len(labels)-1]})


api.add_resource(File, '/file')

if __name__ == '__main__':
    app.run(debug=True)
