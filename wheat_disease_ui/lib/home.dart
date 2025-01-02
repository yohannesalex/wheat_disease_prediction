import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class WheatRustDetection extends StatefulWidget {
  const WheatRustDetection({super.key});

  @override
  _WheatRustDetectionState createState() => _WheatRustDetectionState();
}

class _WheatRustDetectionState extends State<WheatRustDetection> {
  late Interpreter _interpreter;
  late List<String> _classes;
  File? _selectedImage;
  String _predicted = "No prediction yet";

  @override
  void initState() {
    super.initState();
    _loadModel();
    _loadClasses();
  }

  Future<void> _loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset("assets/model.tflite");
      print('----------------------------I am here ---------------------');
    } catch (e) {
      print("Error loading model: $e");
    }
  }

  Future<void> _loadClasses() async {
    _classes = ["Leaf rust", "Loose smut", "Crown root rot", "Healthy"];
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _predicted = "Predicting...";
      });
      _runModel(File(pickedFile.path));
    }
  }

  Future<void> _runModel(File imageFile) async {
    try {
      // Load and preprocess the image
      final image = img.decodeImage(await imageFile.readAsBytes());
      if (image == null) {
        setState(() {
          _predicted = "Invalid image!";
        });
        return;
      }

      // Resize the image to match the model's input size
      final imgSize = 64; // Match the size used in the notebook
      final resizedImage =
          img.copyResize(image, width: imgSize, height: imgSize);

      // Convert the image to Float32List normalized to [0, 1]
      final inputBuffer = Float32List(imgSize * imgSize * 3);
      for (int i = 0; i < imgSize; i++) {
        for (int j = 0; j < imgSize; j++) {
          final pixel = resizedImage.getPixel(j, i);
          final index = (i * imgSize + j) * 3;
          inputBuffer[index] = img.getRed(pixel).toDouble() / 255.0;
          inputBuffer[index + 1] = img.getGreen(pixel).toDouble() / 255.0;
          inputBuffer[index + 2] = img.getBlue(pixel).toDouble() / 255.0;
        }
      }

      // Define the output buffer (1x4 for this model)
      final outputBuffer = Float32List(4).reshape([1, 4]);

      // Run inference
      _interpreter.run(
          inputBuffer.reshape([1, imgSize, imgSize, 3]), outputBuffer);

      // Process the prediction
      final prediction = outputBuffer[0];
      final roundedPrediction =
          prediction.map((value) => value.round()).toList();
      print('Prediction: $prediction');
      // Map the prediction to the class label
      final predictedIndex = roundedPrediction.indexOf(1);
      print('predictedIndex: $predictedIndex');
      setState(() {
        _predicted =
            predictedIndex != -1 ? _classes[predictedIndex] : "Unknown Class";
      });
    } catch (e) {
      setState(() {
        _predicted = "Error: $e";
      });
    }
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/image.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 18, 18, 18).withOpacity(1),
                  const Color.fromARGB(0, 216, 211, 211)
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 50),
                Center(
                    child: const Text(
                  "Wheat Rust Detection",
                  style: TextStyle(
                    color: Color.fromARGB(255, 185, 191, 241),
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                )),
                const SizedBox(height: 60),
                _selectedImage != null
                    ? Image.file(_selectedImage!,
                        height: 300, width: 300, fit: BoxFit.cover)
                    : Container(
                        height: 300,
                        width: 300,
                        color: Colors.grey[200],
                        child: const Center(child: Text("No image selected")),
                      ),
                const SizedBox(height: 20),
                Text(
                  "Predicted: $_predicted",
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt),
                      label: const Text("Camera"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library),
                      label: const Text("Gallery"),
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
