# Mute tensorflow debugging information console
import os
from keras.models import save_model
from keras.utils import np_utils
import argparse
import keras
import model
import helper


def train(model, training_data, callback=True, batch_size=256, epochs=10):

    (x_train, y_train), (x_test, y_test), mapping, nb_classes = training_data

    # convert class vectors to binary class matrices
    y_train = np_utils.to_categorical(y_train, nb_classes)
    y_test = np_utils.to_categorical(y_test, nb_classes)

    if callback == True:
        # Callback for analysis in TensorBoard
        tbCallBack = keras.callbacks.TensorBoard(log_dir='./Graph', histogram_freq=0, write_graph=True, write_images=True)

    model.fit(x_train, y_train,
              batch_size=batch_size,
              epochs=epochs,
              verbose=1,
              validation_data=(x_test, y_test),
              callbacks=[tbCallBack] if callback else None)

    score = model.evaluate(x_test, y_test, verbose=0)
    print('Test score:', score[0])
    print('Test accuracy:', score[1])

    # Offload model to file
    model_yaml = model.to_yaml()
    with open("bin/model.yaml", "w") as yaml_file:
        yaml_file.write(model_yaml)
    save_model(model, 'bin/model.h5')


if __name__ == '__main__':

    parser = argparse.ArgumentParser(usage='A training program for classifying the EMNIST dataset')
    parser.add_argument('-f', '--file', type=str, help='Path .mat file data', required=True)
    parser.add_argument('--width', type=int, default=28, help='Width of the images')
    parser.add_argument('--height', type=int, default=28, help='Height of the images')
    parser.add_argument('--epochs', type=int, default=10, help='Number of epochs to train on')
    args = parser.parse_args()

    bin_dir = os.path.dirname(os.path.realpath(__file__)) + '/bin'
    if not os.path.exists(bin_dir):
        os.makedirs(bin_dir)

    training_data = helper.load_data(args.file, width=args.width, height=args.height, max=args.max)
    model = model.build_model(training_data, width=args.width, height=args.height)
    train(model, training_data, epochs=args.epochs)
