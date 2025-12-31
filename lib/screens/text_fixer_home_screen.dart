import 'package:flutter/material.dart';
import '../storage_service.dart';
import '../services/intent_service.dart';
import '../services/text_processing_service.dart';
import '../services/clipboard_service.dart';
import '../services/toast_service.dart';
import '../models/clipboard_processing_result.dart';
import '../widgets/main_app_ui.dart';
import '../widgets/comparison_bottom_sheet.dart';

class TextFixerHomeScreen extends StatefulWidget {
  const TextFixerHomeScreen({super.key});

  @override
  State<TextFixerHomeScreen> createState() => _TextFixerHomeScreenState();
}

class _TextFixerHomeScreenState extends State<TextFixerHomeScreen> {
  final StorageService _storage = StorageService();
  final TextProcessingService _textProcessingService = TextProcessingService();

  String? _apiKey;
  bool _isFromTextSelection = false;

  // Bottom sheet state
  String? _originalIntentText;
  String? _fixedIntentText;
  ClipboardProcessingResult? _result;
  bool _isRefixing = false;
  StateSetter? _modalSetState;

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
          _originalIntentText = intentText;
        });

        if (_apiKey != null) {
          // Process text directly without modal
          _processIntentText(intentText);
        }
        // If no API key, the user will see the setup form inline on the main screen
      }
    } catch (e) {
      // Silently handle intent processing errors
    }
  }

  // Removed _showComparisonBottomSheet method as modal is no longer used

  Future<void> _processIntentText(String text) async {
    if (!mounted) return;

    try {
      setState(() {
        _fixedIntentText = null;
        _result = null;
      });

      final result = await _textProcessingService.refixText(text);

      if (mounted) {
        setState(() {
          _fixedIntentText = result.fixedText;
          _result = result;
        });
        // Trigger modal rebuild with new data
        _modalSetState?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        // Trigger modal rebuild to show error state
        _modalSetState?.call(() {});
      }
      // Error already shown by service
    }
  }

  Future<void> _handleRefix(String editedText) async {
    if (!mounted) return;

    try {
      setState(() {
        _isRefixing = true;
      });
      // Trigger modal rebuild to show refixing state
      _modalSetState?.call(() {});

      final result = await _textProcessingService.refixText(editedText);

      if (mounted) {
        setState(() {
          _fixedIntentText = result.fixedText;
          _result = result;
          _isRefixing = false;
        });
        // Trigger modal rebuild with new data
        _modalSetState?.call(() {});
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isRefixing = false;
        });
        // Trigger modal rebuild to show error state
        _modalSetState?.call(() {});
      }
      // Error already shown by service
    }
  }

  Future<void> _handleCopy() async {
    if (_fixedIntentText == null) return;

    try {
      await ClipboardService.setClipboardText(_fixedIntentText!);
      ToastService.showSuccessLong(
        _result?.userMessage ?? 'Text copied to clipboard!',
      );

      // Auto-close app after short delay
      await Future.delayed(const Duration(milliseconds: 1500));
      if (mounted) {
        Navigator.of(context).pop(); // Close bottom sheet
        await Future.delayed(const Duration(milliseconds: 300));
        IntentService.closeApp();
      }
    } catch (e) {
      ToastService.showError('Failed to copy text');
    }
  }

  void _handleClose() {
    if (mounted) {
      Navigator.of(context).pop(); // Close bottom sheet
      Future.delayed(const Duration(milliseconds: 300), () {
        IntentService.closeApp();
      });
    }
  }

  Future<void> _handleApiKeySaved() async {
    await _loadApiKey();
    if (_isFromTextSelection && _originalIntentText != null) {
        _processIntentText(_originalIntentText!);
      }
  }

  @override
  Widget build(BuildContext context) {
    if (_isFromTextSelection) {
      return Scaffold(
        backgroundColor: Colors.transparent,  // Keep transparent for overlay effect
        body: SafeArea(
          child: Align(
            alignment: Alignment.bottomCenter,  // Position like a bottom sheet
            child: ComparisonBottomSheet(
              originalText: _originalIntentText!,
              fixedText: _fixedIntentText,
              result: _result,
              onRefix: _handleRefix,
              onCopy: _handleCopy,
              onClose: _handleClose,
              isRefixing: _isRefixing,
            ),
          ),
        ),
      );
    }

    return MainAppUI(
      apiKey: _apiKey,
      onApiKeySaved: _handleApiKeySaved,
    );
  }
}
