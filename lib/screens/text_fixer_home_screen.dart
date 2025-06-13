import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../services/intent_service.dart';
import '../services/text_processing_service.dart';
import '/widgets/setup_dialog.dart';
import '/widgets/main_app_ui.dart';

class TextFixerHomeScreen extends StatefulWidget {
  @override
  _TextFixerHomeScreenState createState() => _TextFixerHomeScreenState();
}

class _TextFixerHomeScreenState extends State<TextFixerHomeScreen> {
  final StorageService _storage = StorageService();
  final TextProcessingService _textProcessingService = TextProcessingService();

  String? _apiKey;
  bool _isFromTextSelection = false;
  bool _isProcessing = false;

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
          // Start processing in background with loading indicator
          await _processTextWithLoading(intentText);
        } else {
          // Show setup dialog only if no API key
          _showSetupDialog();
        }
      }
    } catch (e) {
      print('Error getting intent text: $e');
    }
  }

  /// Process text with loading indicator
  Future<void> _processTextWithLoading(String text) async {
    setState(() {
      _isProcessing = true;
    });

    try {
      // Process text in background
      await _textProcessingService.processTextWithoutClosing(text);

      // Success - close app after brief delay
      await Future.delayed(Duration(milliseconds: 1000));
      IntentService.closeApp();
    } catch (e) {
      // Error - close app after showing error
      await Future.delayed(Duration(milliseconds: 2000));
      IntentService.closeApp();
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
              await _processTextWithLoading(intentText);
            }
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // If from text selection - always show invisible widget
    if (_isFromTextSelection) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Invisible base
            Container(width: 0, height: 0),

            // Show loading indicator only when processing
            if (_isProcessing)
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Color(0xFFA45C40)),
                      strokeWidth: 3,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // Full app interface (only when opened directly from launcher)
    return MainAppUI(
      apiKey: _apiKey,
      onSetupRequested: _showSetupDialog,
    );
  }
}
