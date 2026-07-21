import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../logic/auth_provider.dart';
import '../../../widgets/app_widgets.dart';
import '../../../widgets/gradient_background.dart';
import '../services/ocr_service.dart';
import '../services/ocr_firestore_service.dart';

class OcrScannerScreen extends StatefulWidget {
  const OcrScannerScreen({super.key});

  @override
  State<OcrScannerScreen> createState() => _OcrScannerScreenState();
}

class _OcrScannerScreenState extends State<OcrScannerScreen> {
  final OcrService _ocrService = OcrService();
  final OcrFirestoreService _firestoreService = OcrFirestoreService();
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  File? _image;
  bool _isProcessing = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _ocrService.dispose();
    _textController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    setState(() {
      _image = null;
      _textController.clear();
    });

    try {
      final File? image = fromCamera
          ? await _ocrService.captureImageWithCamera()
          : await _ocrService.pickImageFromGallery();

      if (image != null) {
        setState(() {
          _image = image;
          _isProcessing = true;
        });

        final String recognizedText = await _ocrService.recognizeText(image);

        setState(() {
          _textController.text = recognizedText;
          _isProcessing = false;
        });

        if (recognizedText.isEmpty) {
          _showSnackBar("No text found in the image!", isError: true);
        }
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showSnackBar("OCR Failed: $e", isError: true);
    }
  }

  Future<void> _saveDocument() async {
    if (_textController.text.trim().isEmpty) {
      _showSnackBar("Please extract text first!", isError: true);
      return;
    }

    final String? title = await _showTitleDialog();
    if (title == null || title.trim().isEmpty) return;

    setState(() => _isSaving = true);

    try {
      if (!mounted) return;
      final user = context.read<AuthProvider>().currentUser;
      if (user == null) throw Exception("User not logged in");

      await _firestoreService.saveDocument(
        title: title,
        extractedText: _textController.text,
        createdByUid: user.uid,
        createdByName: user.fullName,
      );

      _showSnackBar("Document saved successfully!");
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnackBar("Save failed: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<String?> _showTitleDialog() async {
    _titleController.clear();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text("Document Title",
            style: TextStyle(color: AppColors.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Enter a title for your document to save it in history.",
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                hintText: "E.g. Class Notes Ch 1",
                hintStyle: TextStyle(color: AppColors.textMuted),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL",
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _titleController.text),
            child: const Text("SAVE",
                style: TextStyle(
                    color: AppColors.accent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _copyToClipboard() {
    if (_textController.text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: _textController.text));
      _showSnackBar("Text copied to clipboard!");
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.danger : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("OCR Scanner",
            style: TextStyle(fontWeight: FontWeight.w700)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GradientBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selection Buttons
                Row(
                  children: [
                    Expanded(
                      child: _choiceCard(
                        "Take Photo",
                        Icons.camera_alt_rounded,
                        () => _pickImage(true),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _choiceCard(
                        "Gallery",
                        Icons.photo_library_rounded,
                        () => _pickImage(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // OCR Tips for better accuracy
                _buildTipsBanner(),
                const SizedBox(height: 24),

                // Image Preview
                if (_image != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Extracted Text Area
                const Text(
                  "EXTRACTED TEXT",
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.inputFill,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _isProcessing
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                                color: AppColors.accent),
                          ),
                        )
                      : TextField(
                          controller: _textController,
                          maxLines: 12,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            hintText: "Extracted text will appear here...",
                            border: InputBorder.none,
                            hintStyle: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                ),
                const SizedBox(height: 24),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _copyToClipboard,
                        icon: const Icon(Icons.copy_rounded, size: 18),
                        label: const Text("COPY"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.textSecondary,
                          side: const BorderSide(color: AppColors.border),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: PrimaryButton(
                        label: "SAVE DOCUMENT",
                        onPressed: _saveDocument,
                        loading: _isSaving,
                        icon: Icons.save_rounded,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceCard(String title, IconData icon, VoidCallback onTap) {
    // ... logic remains same
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: AppColors.accent, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTipsBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lightbulb_outline_rounded,
              color: AppColors.accent, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TIPS FOR BETTER SCAN",
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5),
                ),
                SizedBox(height: 4),
                Text(
                  "1. Use dark blue/black ink.\n2. Ensure good lighting (no shadows).\n3. Keep the paper flat and camera steady.",
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 11, height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
