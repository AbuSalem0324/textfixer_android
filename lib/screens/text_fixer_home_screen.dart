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

  /// Process text with loading indicator - COMPLETELY REWRITTEN
  Future<void> _processTextWithLoading(String text) async {
    print('🔄 Starting text processing, setting _isProcessing = true');

    // Step 1: Show loading indicator
    setState(() {
      _isProcessing = true;
    });

    // Step 2: Force UI update and wait
    await Future.delayed(Duration(milliseconds: 200));
    print('🎨 Loading indicator should be visible now');

    // Step 3: Start API call but don't await it yet
    print('📝 Starting API call for text: $text');
    final apiCallFuture =
        _textProcessingService.processTextWithoutClosing(text);

    // Step 4: Wait for EITHER 2 seconds OR API completion, whichever is longer
    final minimumDisplayTime = Duration(seconds: 2);
    final startTime = DateTime.now();

    try {
      // Wait for API call to complete
      await apiCallFuture;
      print('✅ API call completed');

      // Check if we need to wait longer for minimum display time
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < minimumDisplayTime) {
        final remainingTime = minimumDisplayTime - elapsed;
        print(
            '⏳ Waiting ${remainingTime.inMilliseconds}ms more for minimum display time');
        await Future.delayed(remainingTime);
      }

      print('🏁 Hiding loading indicator');
      setState(() {
        _isProcessing = false;
      });

      // Give user time to see the success toast
      await Future.delayed(Duration(milliseconds: 1500));
      print('🚪 Closing app');
      IntentService.closeApp();
    } catch (e) {
      print('❌ API call failed: $e');

      // For errors, still respect minimum display time
      final elapsed = DateTime.now().difference(startTime);
      final minimumErrorTime = Duration(milliseconds: 1500);
      if (elapsed < minimumErrorTime) {
        final remainingTime = minimumErrorTime - elapsed;
        await Future.delayed(remainingTime);
      }

      print('🏁 Hiding loading indicator (error)');
      setState(() {
        _isProcessing = false;
      });

      // Give user time to see error toast
      await Future.delayed(Duration(milliseconds: 2500));
      print('🚪 Closing app (error)');
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
    print(
        '🏗️ Building UI - _isFromTextSelection: $_isFromTextSelection, _isProcessing: $_isProcessing');

    // If from text selection - show loading overlay when processing
    if (_isFromTextSelection) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Invisible base container
            Container(width: 0, height: 0),

            // Loading overlay - ALWAYS show when _isProcessing is true
            if (_isProcessing)
              Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black.withOpacity(0.1), // Much lighter overlay
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
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFA45C40)),
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
