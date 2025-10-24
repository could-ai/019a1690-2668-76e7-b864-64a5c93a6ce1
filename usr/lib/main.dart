import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Prescription Digitizer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _extractedText = '';
  List<String> _medicines = [];
  Map<String, String> _medicineInfo = {
    'aspirin': 'Pain reliever and fever reducer. Common side effects: stomach upset, heartburn.',
    'ibuprofen': 'Anti-inflammatory drug for pain and fever. Side effects: nausea, dizziness.',
    'paracetamol': 'Fever reducer and pain reliever. Side effects: rare but can include skin rash.',
    'amoxicillin': 'Antibiotic for bacterial infections. Side effects: diarrhea, nausea.',
    // Add more medicines as needed
  };

  final ImagePicker _picker = ImagePicker();
  final textRecognizer = GoogleMlKit.vision.textRecognizer();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      setState(() {
        _image = File(image.path);
      });
      _processImage();
    }
  }

  Future<void> _processImage() async {
    if (_image == null) return;

    final inputImage = InputImage.fromFile(_image!);
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);

    setState(() {
      _extractedText = recognizedText.text;
      _medicines = _extractMedicines(_extractedText);
    });
  }

  List<String> _extractMedicines(String text) {
    List<String> medicines = [];
    // Simple extraction: look for lines that might be medicine names
    // This is basic; in a real app, you'd use better NLP
    List<String> lines = text.split('\n');
    for (String line in lines) {
      String trimmed = line.trim();
      if (trimmed.isNotEmpty && !RegExp(r'^\d').hasMatch(trimmed) && trimmed.length > 2) {
        // Assume medicine names are not starting with numbers and longer than 2 chars
        medicines.add(trimmed);
      }
    }
    return medicines;
  }

  @override
  void dispose() {
    textRecognizer.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Digitizer'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera),
              label: const Text('Take Photo of Prescription'),
            ),
            const SizedBox(height: 20),
            if (_image != null)
              Column(
                children: [
                  Image.file(_image!, height: 200),
                  const SizedBox(height: 20),
                  const Text(
                    'Digitized Text:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(_extractedText),
                  const SizedBox(height: 20),
                  const Text(
                    'Detected Medicines:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._medicines.map((medicine) => Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(_medicineInfo[medicine.toLowerCase()] ?? 'No information available. For more details, consult a healthcare professional.'),
                        ],
                      ),
                    ),
                  )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}