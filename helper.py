import numpy as np
from scipy.io import loadmat
import pickle


def load_data(mat_file_path, width=28, height=28, max=None):

    ''' Load data in from .mat file as specified by the paper.

        Arguments:
            mat_file_path: path to the .mat, should be in sample/

        Optional Arguments:
            width: specified width
            height: specified height
            max: the max number of samples to load
            verbose: enable verbose printing

        Returns:
            A tuple of training and test data, and the mapping for class code to ascii value,
            in the following format:
                - ((training_images, training_labels), (testing_images, testing_labels), mapping)

    '''
    # Local functions
    def rotate(img):
        # Used to rotate images (for some reason they are transposed on read-in)
        flipped = np.fliplr(img)
        return np.rot90(flipped)

    def display(img, threshold=0.5):
        # Debugging only
        render = ''
        for row in img:
            for col in row:
                if col > threshold:
                    render += '@'
                else:
                    render += '.'
            render += '\n'
        return render

    # Load convoluted list structure form loadmat
    mat = loadmat(mat_file_path)

    # Load char mapping
    mapping = {kv[0]:kv[1:][0] for kv in mat['dataset'][0][0][2]}
    pickle.dump(mapping, open('bin/mapping.p', 'wb' ))

    # Load training data
    if max == None:
        max = len(mat['dataset'][0][0][0][0][0][0])
    training_images = mat['dataset'][0][0][0][0][0][0][:max].reshape(max, height, width, 1)
    training_labels = mat['dataset'][0][0][0][0][0][1][:max]

    # Load testing data
    if max == None:
        max = len(mat['dataset'][0][0][1][0][0][0])
    else:
        max = int(max / 6)
    testing_images = mat['dataset'][0][0][1][0][0][0][:max].reshape(max, height, width, 1)
    testing_labels = mat['dataset'][0][0][1][0][0][1][:max]

    # Reshape training data to be valid
    _len = len(training_images)
    for i in range(len(training_images)):
        print('%d/%d (%.2lf%%)' % (i + 1, _len, ((i + 1)/_len) * 100), end='\r')
        training_images[i] = rotate(training_images[i])
    print('')

    # Reshape testing data to be valid
    _len = len(testing_images)
    for i in range(len(testing_images)):
        print('%d/%d (%.2lf%%)' % (i + 1, _len, ((i + 1)/_len) * 100), end='\r')
        testing_images[i] = rotate(testing_images[i])
    print('')

    # Convert type to float32
    training_images = training_images.astype('float32')
    testing_images = testing_images.astype('float32')

    # Normalize to prevent issues with model
    training_images /= 255
    testing_images /= 255

    nb_classes = len(mapping)

    return ((training_images, training_labels), (testing_images, testing_labels), mapping, nb_classes)

