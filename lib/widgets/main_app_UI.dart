import 'package:flutter/material.dart';
import '../widgets/setup_dialog.dart';

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
              SizedBox(height: 8),
              Text(
                'Use the share menu in any app to fix text',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
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
        _buildInstructionStep('1', 'Select text in any app'),
        _buildInstructionStep('2', 'Tap "Share" → "TextFixer"'),
        _buildInstructionStep('3', 'Your text gets fixed instantly!'),
        _buildInstructionStep('4', 'Fixed text is copied to clipboard'),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Color(0xFFA45C40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
