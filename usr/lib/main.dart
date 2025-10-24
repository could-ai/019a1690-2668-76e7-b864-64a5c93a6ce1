import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
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

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prescription Digitizer'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Take a photo of your prescription',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _openCamera(context),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _pickFromGallery(context),
              icon: const Icon(Icons.photo_library),
              label: const Text('Select from Gallery'),
            ),
          ],
        ),
      ),
    );
  }

  void _openCamera(BuildContext context) async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CameraPage(camera: cameras.first),
        ),
      );
    }
  }

  void _pickFromGallery(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      _processImage(File(pickedFile.path), context);
    }
  }

  void _processImage(File imageFile, BuildContext context) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    // Extract medicine names (simple regex for demo)
    final medicines = _extractMedicines(recognizedText.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          recognizedText: recognizedText.text,
          medicines: medicines,
        ),
      ),
    );
  }

  List<String> _extractMedicines(String text) {
    // Simple extraction - look for common medicine patterns
    final medicineRegex = RegExp(r'\b[A-Z][a-z]+\s*[A-Z]*[a-z]*\b');
    final matches = medicineRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toSet().toList(); // Remove duplicates
  }
}

class CameraPage extends StatefulWidget {
  final CameraDescription camera;

  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Take Photo')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            await _initializeControllerFuture;
            final image = await _controller.takePicture();
            if (!mounted) return;
            _processImage(File(image.path), context);
          } catch (e) {
            print(e);
          }
        },
        child: const Icon(Icons.camera),
      ),
    );
  }

  void _processImage(File imageFile, BuildContext context) async {
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await textRecognizer.processImage(inputImage);

    await textRecognizer.close();

    final medicines = _extractMedicines(recognizedText.text);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResultsPage(
          recognizedText: recognizedText.text,
          medicines: medicines,
        ),
      ),
    );
  }

  List<String> _extractMedicines(String text) {
    final medicineRegex = RegExp(r'\b[A-Z][a-z]+\s*[A-Z]*[a-z]*\b');
    final matches = medicineRegex.allMatches(text);
    return matches.map((match) => match.group(0)!).toSet().toList();
  }
}

class ResultsPage extends StatelessWidget {
  final String recognizedText;
  final List<String> medicines;

  const ResultsPage({
    super.key,
    required this.recognizedText,
    required this.medicines,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recognized Text')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recognized Text:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Text(recognizedText),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Detected Medicines:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: medicines.length,
                itemBuilder: (context, index) {
                  final medicine = medicines[index];
                  final info = _getMedicineInfo(medicine);
                  return Card(
                    child: ListTile(
                      title: Text(medicine),
                      subtitle: Text(info),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMedicineInfo(String medicine) {
    // Mock medicine information - in a real app, this would come from an API
    final mockData = {
      'Aspirin': 'Pain reliever and anti-inflammatory. Common side effects: stomach upset, heartburn.',
      'Ibuprofen': 'NSAID for pain and inflammation. May cause stomach issues, dizziness.',
      'Paracetamol': 'Fever reducer and pain reliever. Overuse can damage liver.',
      'Amoxicillin': 'Antibiotic for bacterial infections. May cause diarrhea, nausea.',
      'Metformin': 'Diabetes medication. Side effects: nausea, diarrhea, stomach upset.',
    };

    return mockData[medicine] ?? 'Additional information not available. Please consult a healthcare professional.';
  }
}
