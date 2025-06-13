import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui';
import 'api_service.dart';
import 'storage_service.dart';

void main() {
  runApp(TextFixerApp());
}

class TextFixerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TextFixer',
      theme: ThemeData(
        primarySwatch: Colors.brown,
        fontFamily: 'Roboto',
      ),
      home: TextFixerHome(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class TextFixerHome extends StatefulWidget {
  @override
  _TextFixerHomeState createState() => _TextFixerHomeState();
}

class _TextFixerHomeState extends State<TextFixerHome> {
  final StorageService _storage = StorageService();
  final ApiService _api = ApiService();

  String? _apiKey;
  bool _isProcessing = false;
  bool _isFromTextSelection = false;

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
    setState(() {
      _apiKey = apiKey;
    });
  }

  Future<void> _handleIntentText() async {
    try {
      final String? intentText = await _getIntentText();

      if (intentText != null && intentText.isNotEmpty) {
        setState(() {
          _isFromTextSelection = true;
        });

        if (_apiKey != null) {
          // Process immediately without showing UI
          await _processTextInBackground(intentText);
        } else {
          // Show setup dialog only if no API key
          _showSetupDialog();
        }
      }
    } catch (e) {
      print('Error getting intent text: $e');
    }
  }

  Future<String?> _getIntentText() async {
    try {
      const platform = MethodChannel('com.textfixer.android/intent');
      final String? text = await platform.invokeMethod('getIntentText');
      return text;
    } catch (e) {
      print('Error in getIntentText: $e');
      return null;
    }
  }

  Future<void> _processTextInBackground(String text) async {
    if (_apiKey == null) return;

    try {
      final result = await _api.fixText(_apiKey!, text);

      // Copy to clipboard
      await Clipboard.setData(ClipboardData(text: result['fixedText']));

      // Show success toast
      _showToast(
          result['userMessage'] ?? 'Text fixed and copied to clipboard!');

      // Close app after showing success
      await Future.delayed(Duration(milliseconds: 1200));
      _closeApp();
    } catch (e) {
      // Show error toast
      String errorMessage;
      if (e.toString().contains('Network') ||
          e.toString().contains('Connection')) {
        errorMessage = 'Network error. Please try again.';
      } else {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      }

      _showToast(errorMessage);

      // Close app after showing error
      await Future.delayed(Duration(milliseconds: 2500));
      _closeApp();
    }
  }

  void _showLoadingOverlay() {
    _showToast('Fixing text...', isLoading: true);
  }

  void _hideLoadingOverlay() {
    // Toast will hide automatically
  }

  void _showToast(String message, {bool isLoading = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: isLoading ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Color(0xFFA45C40),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _closeApp() {
    SystemNavigator.pop();
  }

  void _showSetupDialog() {
    final TextEditingController controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Setup TextFixer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Enter your TextFixer API key:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Paste your API key here',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 8),
            Text(
              'You can get your API key from textfixer.co.uk',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isFromTextSelection) _closeApp();
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final apiKey = controller.text.trim();
              if (apiKey.isNotEmpty) {
                await _storage.saveApiKey(apiKey);
                setState(() {
                  _apiKey = apiKey;
                });
                Navigator.pop(context);

                // Process the text that brought us here
                if (_isFromTextSelection) {
                  final intentText = await _getIntentText();
                  if (intentText != null) {
                    await _processTextInBackground(intentText);
                  }
                }
              }
            },
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ Error'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_isFromTextSelection) _closeApp();
            },
            child: Text('OK'),
          ),
          if (error.contains('limit') || error.contains('Upgrade')) ...[
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _openUpgradeUrl();
                if (_isFromTextSelection) _closeApp();
              },
              child: Text('Upgrade'),
            ),
          ],
        ],
      ),
    );
  }

  void _openUpgradeUrl() {
    print('Opening upgrade URL: https://textfixer.co.uk/#pricing');
  }

  @override
  Widget build(BuildContext context) {
    // If we came from text selection, show loading widget
    if (_isFromTextSelection) {
      return Scaffold(
        backgroundColor:
            Colors.black.withOpacity(0.3), // Semi-transparent overlay
        body: Center(
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 60),
            padding: EdgeInsets.all(24),
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
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA45C40)),
                  strokeWidth: 3,
                ),
                SizedBox(height: 20),
                Text(
                  'Fixing your text...',
                  style: TextStyle(
                    fontSize: 16,
                    color: Color(0xFF4A3933),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF847C74),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Full app interface (only when opened directly)
    return Scaffold(
      appBar: AppBar(
        title: Text('TextFixer'),
        backgroundColor: Color(0xFFA45C40),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFF6F4EA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(Icons.auto_fix_high, size: 48, color: Color(0xFFA45C40)),
                  SizedBox(height: 12),
                  Text(
                    'TextFixer',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4A3933),
                    ),
                  ),
                  Text(
                    'AI-Powered Text Correction',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF847C74),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Status
            if (_apiKey == null) ...[
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.key, color: Colors.orange),
                      SizedBox(height: 8),
                      Text('Setup Required'),
                      SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _showSetupDialog,
                        child: Text('Enter API Key'),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(height: 8),
                      Text('Ready to fix text!'),
                    ],
                  ),
                ),
              ),
            ],

            SizedBox(height: 24),

            // How to use
            Text(
              'How to use:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('1. Select text in any app'),
            Text('2. Tap "Share" → "TextFixer"'),
            Text('3. Your text gets fixed instantly!'),
            Text('4. Fixed text is copied to clipboard'),

            SizedBox(height: 24),

            // Test button
            if (_apiKey != null) ...[
              ElevatedButton.icon(
                onPressed: () async {
                  await _processTextInBackground(
                      "This is a test text with erors to fix.");
                },
                icon: Icon(Icons.play_arrow),
                label: Text('Test TextFixer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFA45C40),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.all(16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
