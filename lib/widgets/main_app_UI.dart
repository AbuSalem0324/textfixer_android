import 'package:flutter/material.dart';
import '/models/clipboard_processing_result.dart';
import '/services/clipboard_service.dart';
import '/services/text_processing_service.dart';
import '/services/toast_service.dart';
import '../widgets/setup_dialog.dart';

class MainAppUI extends StatefulWidget {
  final String? apiKey;
  final VoidCallback onSetupRequested;

  const MainAppUI({
    Key? key,
    this.apiKey,
    required this.onSetupRequested,
  }) : super(key: key);

  @override
  _MainAppUIState createState() => _MainAppUIState();
}

class _MainAppUIState extends State<MainAppUI> {
  final TextProcessingService _textProcessingService = TextProcessingService();

  String? _clipboardPreview;
  ClipboardProcessingResult? _lastResult;
  TextEditingController? _fixedTextController;
  bool _isProcessing = false;
  bool _showResults = false;
  bool _isLoadingClipboard = false;

  @override
  void initState() {
    super.initState();
    _loadClipboardPreview();
  }

  @override
  void dispose() {
    _fixedTextController?.dispose();
    super.dispose();
  }

  /// Load clipboard preview
  Future<void> _loadClipboardPreview() async {
    setState(() {
      _isLoadingClipboard = true;
    });

    try {
      final clipboardText = await ClipboardService.getCurrentClipboardText();
      setState(() {
        _clipboardPreview = clipboardText;
        _isLoadingClipboard = false;
      });
    } catch (e) {
      setState(() {
        _clipboardPreview = null;
        _isLoadingClipboard = false;
      });
    }
  }

  /// Process clipboard text
  Future<void> _processClipboardText() async {
    if (widget.apiKey == null) {
      widget.onSetupRequested();
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await _textProcessingService.processClipboardTextWithResult();
      _handleProcessingResult(result);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      // Error already shown by service
    }
  }

  /// Handle processing result
  void _handleProcessingResult(ClipboardProcessingResult result) {
    setState(() {
      _lastResult = result;
      _fixedTextController?.dispose();
      _fixedTextController = TextEditingController(text: result.fixedText);
      _showResults = true;
      _isProcessing = false;
    });

    ToastService.showSuccess(result.userMessage);
  }

  /// Copy current text to clipboard
  Future<void> _copyToClipboard() async {
    if (_fixedTextController?.text.isNotEmpty == true) {
      try {
        await ClipboardService.setClipboardText(_fixedTextController!.text);
        ToastService.showSuccess('Text copied to clipboard!');
      } catch (e) {
        ToastService.showError('Failed to copy text to clipboard');
      }
    }
  }

  /// Re-process the currently edited text
  Future<void> _refixText() async {
    if (_fixedTextController?.text.isEmpty == true) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await _textProcessingService.refixText(_fixedTextController!.text);

      // Update the text field with new result
      setState(() {
        _fixedTextController!.text = result.fixedText;
        _lastResult = result;
        _isProcessing = false;
      });

      ToastService.showSuccess(result.userMessage);
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      // Error already shown by service
    }
  }

  /// Clear results and return to initial state
  void _clearResults() {
    setState(() {
      _showResults = false;
      _lastResult = null;
      _fixedTextController?.dispose();
      _fixedTextController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'TextFixer',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        backgroundColor: Color(0xFFA45C40),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 24),
            _buildStatusCard(),
            SizedBox(height: 24),
            _buildClipboardSection(),
            if (_showResults) ...[
              SizedBox(height: 24),
              _buildResultsSection(),
            ],
            SizedBox(height: 24),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    if (widget.apiKey == null) {
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
                onPressed: widget.onSetupRequested,
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
                'Use the share menu in any app or the clipboard feature below',
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

  Widget _buildClipboardSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE6D7C1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.content_paste, color: Color(0xFFA45C40), size: 20),
              SizedBox(width: 8),
              Text(
                'Clipboard Fix',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A3933),
                ),
              ),
              Spacer(),
              IconButton(
                onPressed: _loadClipboardPreview,
                icon: Icon(Icons.refresh, size: 18),
                color: Color(0xFF847C74),
                tooltip: 'Refresh clipboard',
              ),
            ],
          ),

          SizedBox(height: 12),

          // Clipboard Preview
          _buildClipboardPreviewCard(),

          SizedBox(height: 16),

          // Fix Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isProcessing || widget.apiKey == null
                  ? null
                  : _processClipboardText,
              icon: _isProcessing
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Icon(Icons.auto_fix_high),
              label:
                  Text(_isProcessing ? 'Processing...' : 'Fix Clipboard Text'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFA45C40),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipboardPreviewCard() {
    if (_isLoadingClipboard) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFFF6F4EA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFE6D7C1)),
        ),
        child: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFA45C40)),
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Loading clipboard...',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF847C74),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_clipboardPreview == null || _clipboardPreview!.trim().isEmpty) {
      return Container(
        height: 80,
        decoration: BoxDecoration(
          color: Color(0xFFF6F4EA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Color(0xFFE6D7C1)),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.content_paste_off, color: Color(0xFF847C74)),
              SizedBox(height: 4),
              Text(
                'No text in clipboard',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF847C74),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final preview = ClipboardService.getClipboardPreview(_clipboardPreview!);
    final isWorthFixing =
        ClipboardService.isTextWorthFixing(_clipboardPreview!);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWorthFixing ? Color(0xFFF6F4EA) : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWorthFixing ? Color(0xFFE6D7C1) : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isWorthFixing
                    ? Icons.check_circle_outline
                    : Icons.warning_outlined,
                size: 16,
                color: isWorthFixing ? Colors.green : Colors.orange,
              ),
              SizedBox(width: 4),
              Text(
                '${_clipboardPreview!.length} characters',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF847C74),
                ),
              ),
              if (!isWorthFixing) ...[
                SizedBox(width: 8),
                Text(
                  'Too short/unreadable',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 8),
          Text(
            preview,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF4A3933),
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    if (!_showResults || _lastResult == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE6D7C1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            children: [
              Icon(Icons.auto_fix_high, color: Color(0xFFA45C40), size: 20),
              SizedBox(width: 8),
              Text(
                'Fixed Text',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF4A3933),
                ),
              ),
              Spacer(),
              Text(
                '${_fixedTextController!.text.length} chars',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF847C74),
                ),
              ),
            ],
          ),

          if (_lastResult!.hasChanges) ...[
            SizedBox(height: 4),
            Text(
              _lastResult!.changeSummary,
              style: TextStyle(
                fontSize: 12,
                color: Colors.green[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          SizedBox(height: 12),

          // Editable Text Field
          TextField(
            controller: _fixedTextController,
            maxLines: null,
            minLines: 3,
            decoration: InputDecoration(
              hintText: 'Your fixed text appears here...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFE6D7C1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Color(0xFFA45C40), width: 2),
              ),
              contentPadding: EdgeInsets.all(12),
            ),
            style: TextStyle(
              fontSize: 14,
              height: 1.4,
              color: Color(0xFF4A3933),
            ),
          ),

          SizedBox(height: 16),

          // Action Buttons Row
          Row(
            children: [
              // Copy to Clipboard Button (Primary)
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: () => _copyToClipboard(),
                  icon: Icon(Icons.content_copy, size: 18),
                  label: Text('Copy to Clipboard'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA45C40),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Re-fix Button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isProcessing ? null : () => _refixText(),
                  icon: _isProcessing
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xFFA45C40)),
                          ),
                        )
                      : Icon(Icons.refresh, size: 18),
                  label: Text('Re-fix'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(0xFFA45C40),
                    side: BorderSide(color: Color(0xFFA45C40)),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),

              SizedBox(width: 8),

              // Clear Button
              IconButton(
                onPressed: () => _clearResults(),
                icon: Icon(Icons.clear),
                color: Color(0xFF847C74),
                tooltip: 'Clear results',
              ),
            ],
          ),

          // Processing Indicator
          if (_isProcessing) ...[
            SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(Color(0xFFA45C40)),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Re-processing...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF847C74),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
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
        _buildInstructionStep(
            '1', 'Select text in any app, then share → TextFixer'),
        _buildInstructionStep(
            '2', 'OR copy text and use "Fix Clipboard Text" above'),
        _buildInstructionStep('3', 'Review and edit the improved text'),
        _buildInstructionStep('4', 'Copy to clipboard and paste anywhere'),
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
