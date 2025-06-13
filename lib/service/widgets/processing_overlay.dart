import 'package:flutter/material.dart';

class ProcessingOverlay extends StatelessWidget {
  const ProcessingOverlay({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
}
