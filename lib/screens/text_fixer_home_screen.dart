import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../services/intent_service.dart';
import '../services/text_processing_service.dart';
import '/widgets/setup_dialog.dart';
import '/widgets/main_app_ui.dart';
import '/services/clipboard_service.dart';

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

  Future<void> _initializeApp() async {
    await _loadApiKey();
    await _handleIntentText();
  }

  Future<void> _loadApiKey() async {
    final apiKey = await _storage.getApiKey();
    if (mounted) {
      setState(() {
        _apiKey = apiKey;
      });
    }
  }

  Future<void> _handleIntentText() async {
    try {
      final String? intentText = await IntentService.getIntentText();

      if (intentText != null && intentText.isNotEmpty) {
        setState(() {
          _isFromTextSelection = true;
        });

        if (_apiKey != null) {
          await _processTextWithLoading(intentText);
        } else {
          _showSetupDialog();
        }
      }
    } catch (e) {
      // Silently handle intent processing errors
    }
  }

  Future<void> _processTextWithLoading(String text) async {
    if (!mounted) return;

    setState(() {
      _isProcessing = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));

    const minimumDisplayTime = Duration(seconds: 2);
    final startTime = DateTime.now();

    try {
      await _textProcessingService.processTextWithoutClosing(text);

      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minimumDisplayTime) {
        await Future.delayed(minimumDisplayTime - elapsed);
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 1500));
      IntentService.closeApp();
    } catch (e) {
      final elapsed = DateTime.now().difference(startTime);
      const minimumErrorTime = Duration(milliseconds: 1500);

      if (elapsed < minimumErrorTime) {
        await Future.delayed(minimumErrorTime - elapsed);
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }

      await Future.delayed(const Duration(milliseconds: 2500));
      IntentService.closeApp();
    }
  }

  void _showSetupDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => SetupDialog(
        isFromTextSelection: _isFromTextSelection,
        onApiKeySaved: () async {
          await _loadApiKey();
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
    if (_isFromTextSelection) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: _isProcessing ? _buildLoadingOverlay() : const SizedBox.shrink(),
      );
    }

    return MainAppUI(
      apiKey: _apiKey,
      onSetupRequested: _showSetupDialog,
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.black.withOpacity(0.1),
      child: Center(
        child: Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA45C40)),
                  strokeWidth: 3,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Fixing...',
                style: TextStyle(
                  color: Color(0xFF4A3933),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
