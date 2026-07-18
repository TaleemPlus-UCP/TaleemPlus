import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
  final ImagePicker _picker = ImagePicker();

  /// Gallery se image pick karne ke liye
  Future<File?> pickImageFromGallery() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // Max quality for better OCR accuracy
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Camera se image capture karne ke liye
  Future<File?> captureImageWithCamera() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100, // Max quality for better OCR accuracy
    );
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

  /// Google ML Kit ka use karke text recognize karne ke liye
  Future<String> recognizeText(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      
      String text = recognizedText.text;
      
      if (text.isEmpty) return "";

      // Post-processing to clean common OCR noise
      return _cleanExtractedText(text);
    } catch (e) {
      throw Exception("Text recognition failed: $e");
    }
  }

  /// AI-based heuristic cleaning for common OCR mistakes
  String _cleanExtractedText(String input) {
    String cleaned = input;

    // 1. Fix common misspelled words from OCR
    final Map<String, String> corrections = {
      'Passuond': 'Password',
      'Passuord': 'Password',
      'tuleme': 'taleem',
      'Sasat': 'Student',
      'Sasant': 'Student',
      'Stndent': 'Student',
      'Pnrent': 'Parent',
    };

    corrections.forEach((wrong, right) {
      cleaned = cleaned.replaceAll(RegExp(wrong, caseSensitive: false), right);
    });

    // 2. Remove stray single characters that are likely noise (like dots or single 'M')
    // but keep numbers or 'a', 'I'
    List<String> lines = cleaned.split('\n');
    List<String> filteredLines = [];

    for (var line in lines) {
      String trimmed = line.trim();
      if (trimmed.length <= 1 && !RegExp(r'[0-9aAiI]').hasMatch(trimmed)) {
        continue; // Skip noise line
      }
      filteredLines.add(line);
    }

    return filteredLines.join('\n').trim();
  }

  /// Memory clean karne ke liye
  void dispose() {
    _textRecognizer.close();
  }
}
