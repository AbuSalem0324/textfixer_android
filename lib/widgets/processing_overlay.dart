import 'package:flutter/material.dart';

class ProcessingOverlay extends StatelessWidget {
  static const Color _brandColor = Color(0xFFA45C40);
  static const Color _textDark = Color(0xFF4A3933);
  static const Color _textLight = Color(0xFF847C74);

  const ProcessingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 60),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                strokeWidth: 3,
              ),
              SizedBox(height: 20),
              Text(
                'Fixing your text...',
                style: TextStyle(
                  fontSize: 16,
                  color: _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  fontSize: 14,
                  color: _textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
