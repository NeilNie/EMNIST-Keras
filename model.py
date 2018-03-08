from keras.layers import Conv2D, MaxPooling2D, Convolution2D, Dropout, Dense, Flatten, LSTM
from keras.models import Sequential


def build_model(training_data, width=28, height=28):

    ''' Build and train neural network. Also offloads the net in .yaml and the
        weights in .h5 to the bin/.

        Arguments:
            training_data: the packed tuple from load_data()

        Optional Arguments:
            width: specified width
            height: specified height
            epochs: the number of epochs to train over
            verbose: enable verbose printing
    '''
    # Initialize data
    (x_train, y_train), (x_test, y_test), mapping, nb_classes = training_data
    input_shape = (height, width, 1)

    # Hyperparameters
    nb_filters = 32 # number of convolutional filters to use
    pool_size = (2, 2) # size of pooling area for max pooling
    kernel_size = (3, 3) # convolution kernel size

    model = Sequential()
    model.add(Convolution2D(nb_filters, kernel_size, padding='valid', input_shape=input_shape, activation='relu'))
    model.add(Convolution2D(nb_filters, kernel_size, activation='relu'))

    model.add(MaxPooling2D(pool_size=pool_size))
    model.add(Dropout(0.25))
    model.add(Flatten())

    model.add(Dense(512, activation='relu'))
    model.add(Dropout(0.5))
    model.add(Dense(nb_classes, activation='softmax'))

    model.compile(loss='categorical_crossentropy', optimizer='adadelta', metrics=['accuracy'])

    print(model.summary())
    return model