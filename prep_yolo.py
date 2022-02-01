import os
import shutil
from sklearn.model_selection import train_test_split

# Read images and annotations
picture_path = os.path.join('pictures', 'images')
annotation_path = os.path.join('pictures', 'labels')
images = [os.path.join(picture_path, x) for x in os.listdir(picture_path)]
annotations = [os.path.join(annotation_path, x) for x in os.listdir(annotation_path) if x[-3:] == "txt"]

images.sort()
annotations.sort()

# Split the dataset into train-valid-test splits
train_images, val_images, train_annotations, val_annotations = train_test_split(images, annotations, test_size = 0.2, random_state = 1)
val_images, test_images, val_annotations, test_annotations = train_test_split(val_images, val_annotations, test_size = 0.5, random_state = 1)
os.mkdir(os.path.join(picture_path, 'train'))
os.mkdir(os.path.join(picture_path, 'val'))
os.mkdir(os.path.join(picture_path, 'test'))
os.mkdir(os.path.join(annotation_path, 'train'))
os.mkdir(os.path.join(annotation_path, 'val'))
os.mkdir(os.path.join(annotation_path, 'test'))


def move_files_to_folder(list_of_files, destination_folder):
    for f in list_of_files:
        try:
            shutil.move(f, destination_folder)
        except:
            print(f)
            assert False


# Move the splits into their folders
move_files_to_folder(train_images, os.path.join(picture_path, 'train'))
move_files_to_folder(val_images, os.path.join(picture_path, 'val'))
move_files_to_folder(test_images, os.path.join(picture_path, 'test'))
move_files_to_folder(train_annotations, os.path.join(annotation_path, 'train'))
move_files_to_folder(val_annotations, os.path.join(annotation_path, 'val'))
move_files_to_folder(test_annotations, os.path.join(annotation_path, 'test'))

