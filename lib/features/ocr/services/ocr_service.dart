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
      imageQuality: 85, // Quality thodi kam ki hai taake processing fast ho
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
      imageQuality: 85,
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
      
      // Agar text empty ho toh properly handle karein
      if (text.isEmpty) {
        return "";
      }
      
      return text;
    } catch (e) {
      // Production code mein error properly log honi chahiye
      throw Exception("Text recognition failed: $e");
    }
  }

  /// Memory clean karne ke liye
  void dispose() {
    _textRecognizer.close();
  }
}
