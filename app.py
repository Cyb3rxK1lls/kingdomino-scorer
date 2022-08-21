from flask import Flask, request, jsonify
from flask_restful import Resource, Api
from PIL import Image
from models.detect import run
import os

app = Flask(__name__)
api = Api(app)


class File(Resource):

    def get(self):
        response = jsonify({'status': 200})

        response.headers.add("Access-Control-Allow-Origin", "*")
        return response

    def post(self):
        img_file = request.files['picture']

        # Read the image via file.stream
        img = Image.open(img_file.stream)
        width, height = img.size
        padded_width = 0 if width >= height else height - width
        padded_height = 0 if width <= height else width - height

        new_img = Image.new('RGB', (padded_width + width, padded_height + height), (255, 255, 255))
        new_img.paste(img, img.getbbox())
        img = new_img.resize((640, 640))
        img.save(os.path.join('temp', img_file.filename))

        # run through models and receive list
        run(weights='models/kd_mod_med.pt', source=os.path.join('temp', img_file.filename),
            project='receive', name='', exist_ok=True)
        txt_filename = img_file.filename.split('.')[0] + '.txt'
        with open(os.path.join('receive', txt_filename)) as txt_file:
            labels = txt_file.read()

        # remove img from temp
        os.remove(os.path.join('temp', img_file.filename))

        status = 300 if len(labels) == 0 else 200
        if status == 300:
            try:
                os.remove(os.path.join('receieve', img_file.filename[:len(img_file.filename)-3] + 'txt'))
            except:
                pass
        return jsonify({'result': status, 'labels': labels.replace('\n', ',')[:len(labels)-1]})


api.add_resource(File, '/file')

if __name__ == '__main__':
    app.run(debug=True, host="0.0.0.0", port=8000)
    # app.run(debug=True)
