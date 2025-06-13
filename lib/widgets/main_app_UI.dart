import 'package:flutter/material.dart';
import '../widgets/setup_dialog.dart';
import '/services/text_processing_service.dart';

class MainAppUI extends StatelessWidget {
  final String? apiKey;
  final VoidCallback onSetupRequested;

  const MainAppUI({
    Key? key,
    this.apiKey,
    required this.onSetupRequested,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final TextProcessingService textProcessingService = TextProcessingService();

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
            _buildHeader(),
            SizedBox(height: 24),
            _buildStatusCard(),
            SizedBox(height: 24),
            _buildInstructions(),
            SizedBox(height: 24),
            if (apiKey != null) _buildTestButton(textProcessingService),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
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
    );
  }

  Widget _buildStatusCard() {
    if (apiKey == null) {
      return Card(
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
                onPressed: onSetupRequested,
                child: Text('Enter API Key'),
              ),
            ],
          ),
        ),
      );
    } else {
      return Card(
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
      );
    }
  }

  Widget _buildInstructions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How to use:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text('1. Select text in any app'),
        Text('2. Tap "Share" → "TextFixer"'),
        Text('3. Your text gets fixed instantly!'),
        Text('4. Fixed text is copied to clipboard'),
      ],
    );
  }

  Widget _buildTestButton(TextProcessingService textProcessingService) {
    return ElevatedButton.icon(
      onPressed: () => textProcessingService.testTextProcessing(),
      icon: Icon(Icons.play_arrow),
      label: Text('Test TextFixer'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xFFA45C40),
        foregroundColor: Colors.white,
        padding: EdgeInsets.all(16),
      ),
    );
  }
}
