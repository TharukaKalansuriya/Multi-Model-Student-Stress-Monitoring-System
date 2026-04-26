# YAMNet Model Files

Place the following files in this directory before building the app:

1. `yamnet.tflite` — YAMNet TFLite model
   Download from: https://tfhub.dev/google/lite-model/yamnet/classification/tflite/1

2. `yamnet_class_map.txt` — YAMNet class labels (one per line, 521 classes)
   Download from: https://raw.githubusercontent.com/tensorflow/models/master/research/audioset/yamnet/yamnet_class_map.csv
   (extract the display_name column, one label per line)
