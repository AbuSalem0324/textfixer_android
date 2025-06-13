import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../services/intent_service.dart';
import '../services/text_processing_service.dart';
import '/widgets/setup_dialog.dart';
import '/widgets/processing_overlay.dart';
import '../service/widgets/main_app_ui.dart';

class TextFixerHomeScreen extends StatefulWidget {
  @override
  _TextFixerHomeScreenState createState() => _TextFixerHomeScreenState();
}

class _TextFixerHomeScreenState extends State<TextFixerHomeScreen> {
  final StorageService _storage = StorageService();
  final TextProcessingService _textProcessingService = TextProcessingService();

  String? _apiKey;
  bool _isFromTextSelection = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  /// Initialize the app by loading API key and handling intent text
  Future<void> _initializeApp() async {
    await _loadApiKey();
    await _handleIntentText();
  }

  /// Load API key from storage
  Future<void> _loadApiKey() async {
    final apiKey = await _storage.getApiKey();
    setState(() {
      _apiKey = apiKey;
    });
  }

  /// Handle text from Android intent (share menu or text selection)
  Future<void> _handleIntentText() async {
    try {
      final String? intentText = await IntentService.getIntentText();

      if (intentText != null && intentText.isNotEmpty) {
        setState(() {
          _isFromTextSelection = true;
        });

        if (_apiKey != null) {
          // Process immediately without showing UI
          await _textProcessingService.processTextInBackground(intentText);
        } else {
          // Show setup dialog only if no API key
          _showSetupDialog();
        }
      }
    } catch (e) {
      print('Error getting intent text: $e');
    }
  }

  /// Show API key setup dialog
  void _showSetupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SetupDialog(
        isFromTextSelection: _isFromTextSelection,
        onApiKeySaved: () async {
          await _loadApiKey();

          // Process the text that brought us here
          if (_isFromTextSelection) {
            final intentText = await IntentService.getIntentText();
            if (intentText != null) {
              await _textProcessingService.processTextInBackground(intentText);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If we came from text selection, show loading widget
    if (_isFromTextSelection) {
      return ProcessingOverlay();
    }

    // Full app interface (only when opened directly)
    return MainAppUI(
      apiKey: _apiKey,
      onSetupRequested: _showSetupDialog,
    );
  }
}
