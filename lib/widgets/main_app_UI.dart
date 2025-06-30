import 'package:flutter/material.dart';
import '/models/clipboard_processing_result.dart';
import '/services/clipboard_service.dart';
import '/services/text_processing_service.dart';
import '/services/toast_service.dart';

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
  static const Color _brandColor = Color(0xFFA45C40);
  static const Color _lightBackground = Color(0xFFF6F4EA);
  static const Color _borderColor = Color(0xFFE6D7C1);
  static const Color _textDark = Color(0xFF4A3933);
  static const Color _textLight = Color(0xFF847C74);

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

  bool get _hasApiKey => widget.apiKey != null;
  bool get _canProcess => _hasApiKey && !_isProcessing;

  Future<void> _loadClipboardPreview() async {
    setState(() => _isLoadingClipboard = true);

    try {
      final clipboardText = await ClipboardService.getCurrentClipboardText();
      if (mounted) {
        setState(() {
          _clipboardPreview = clipboardText;
          _isLoadingClipboard = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _clipboardPreview = null;
          _isLoadingClipboard = false;
        });
      }
    }
  }

  Future<void> _processClipboardText() async {
    if (!_hasApiKey) {
      widget.onSetupRequested();
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final result =
          await _textProcessingService.processClipboardTextWithResult();
      _handleProcessingResult(result);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _handleProcessingResult(ClipboardProcessingResult result) {
    _fixedTextController?.dispose();
    setState(() {
      _lastResult = result;
      _fixedTextController = TextEditingController(text: result.fixedText);
      _showResults = true;
      _isProcessing = false;
    });
    ToastService.showSuccess(result.userMessage);
  }

  Future<void> _copyToClipboard() async {
    final text = _fixedTextController?.text;
    if (text?.isNotEmpty == true) {
      try {
        await ClipboardService.setClipboardText(text!);
        ToastService.showSuccess('Text copied to clipboard!');
      } catch (e) {
        ToastService.showError('Failed to copy text to clipboard');
      }
    }
  }

  Future<void> _refixText() async {
    final text = _fixedTextController?.text;
    if (text?.isEmpty != false) return;

    setState(() => _isProcessing = true);

    try {
      final result = await _textProcessingService.refixText(text!);
      setState(() {
        _fixedTextController!.text = result.fixedText;
        _lastResult = result;
        _isProcessing = false;
      });
      ToastService.showSuccess(result.userMessage);
    } catch (e) {
      setState(() => _isProcessing = false);
    }
  }

  void _clearResults() {
    _fixedTextController?.dispose();
    setState(() {
      _showResults = false;
      _lastResult = null;
      _fixedTextController = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'TextFixer',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 28,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.4,
          ),
        ),
        backgroundColor: _brandColor,
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            _buildStatusCard(),
            const SizedBox(height: 24),
            _buildClipboardSection(),
            if (_showResults) ...[
              const SizedBox(height: 24),
              _buildResultsSection(),
            ],
            const SizedBox(height: 24),
            _buildInstructions(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    return Card(
      color: _hasApiKey ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              _hasApiKey ? Icons.check_circle : Icons.key,
              color: _hasApiKey ? Colors.green : Colors.orange,
            ),
            const SizedBox(height: 8),
            Text(_hasApiKey ? 'Ready to fix text!' : 'Setup Required'),
            const SizedBox(height: 8),
            if (!_hasApiKey)
              ElevatedButton(
                onPressed: widget.onSetupRequested,
                child: const Text('Enter API Key'),
              )
            else
              Text(
                'Use the share menu in any app or the clipboard feature below',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildClipboardSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            'Clipboard Fix',
            Icons.content_paste,
            onRefresh: _loadClipboardPreview,
          ),
          const SizedBox(height: 12),
          _buildClipboardPreviewCard(),
          const SizedBox(height: 16),
          _buildProcessButton(),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon,
      {VoidCallback? onRefresh}) {
    return Row(
      children: [
        Icon(icon, color: _brandColor, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _textDark,
          ),
        ),
        const Spacer(),
        if (onRefresh != null)
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh, size: 18),
            color: _textLight,
            tooltip: 'Refresh clipboard',
          ),
      ],
    );
  }

  Widget _buildClipboardPreviewCard() {
    if (_isLoadingClipboard) {
      return _buildLoadingCard('Loading clipboard...');
    }

    if (_clipboardPreview?.isEmpty != false) {
      return _buildEmptyCard();
    }

    final preview = ClipboardService.getClipboardPreview(_clipboardPreview!);
    final isWorthFixing =
        ClipboardService.isTextWorthFixing(_clipboardPreview!);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWorthFixing ? _lightBackground : Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWorthFixing ? _borderColor : Colors.orange[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPreviewHeader(isWorthFixing),
          const SizedBox(height: 8),
          Text(
            preview,
            style: const TextStyle(
              fontSize: 14,
              color: _textDark,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewHeader(bool isWorthFixing) {
    return Row(
      children: [
        Icon(
          isWorthFixing ? Icons.check_circle_outline : Icons.warning_outlined,
          size: 16,
          color: isWorthFixing ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 4),
        Text(
          '${_clipboardPreview!.length} characters',
          style: const TextStyle(fontSize: 12, color: _textLight),
        ),
        if (!isWorthFixing) ...[
          const SizedBox(width: 8),
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
    );
  }

  Widget _buildLoadingCard(String message) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
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
                valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: _textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.content_paste_off, color: _textLight),
            SizedBox(height: 4),
            Text(
              'No text in clipboard',
              style: TextStyle(fontSize: 12, color: _textLight),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProcessButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _canProcess ? _processClipboardText : null,
        icon: _isProcessing
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Icon(Icons.auto_fix_high),
        label: Text(_isProcessing ? 'Processing...' : 'Fix Clipboard Text'),
        style: ElevatedButton.styleFrom(
          backgroundColor: _brandColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    if (!_showResults || _lastResult == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultsHeader(),
          const SizedBox(height: 12),
          _buildTextEditor(),
          const SizedBox(height: 16),
          _buildActionButtons(),
          if (_isProcessing) _buildProcessingIndicator(),
        ],
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.auto_fix_high, color: _brandColor, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Fixed Text',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            const Spacer(),
            Text(
              '${_fixedTextController!.text.length} chars',
              style: const TextStyle(fontSize: 12, color: _textLight),
            ),
          ],
        ),
        if (_lastResult!.hasChanges) ...[
          const SizedBox(height: 4),
          Text(
            _lastResult!.changeSummary,
            style: TextStyle(
              fontSize: 12,
              color: Colors.green[700],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextEditor() {
    return TextField(
      controller: _fixedTextController,
      maxLines: null,
      minLines: 3,
      decoration: InputDecoration(
        hintText: 'Your fixed text appears here...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brandColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(12),
      ),
      style: const TextStyle(fontSize: 14, height: 1.4, color: _textDark),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: ElevatedButton.icon(
            onPressed: _copyToClipboard,
            icon: const Icon(Icons.content_copy, size: 18),
            label: const Text('Copy to Clipboard'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _brandColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _isProcessing ? null : _refixText,
            icon: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
                    ),
                  )
                : const Icon(Icons.refresh, size: 18),
            label: const Text('Re-fix'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _brandColor,
              side: const BorderSide(color: _brandColor),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: _clearResults,
          icon: const Icon(Icons.clear),
          color: _textLight,
          tooltip: 'Clear results',
        ),
      ],
    );
  }

  Widget _buildProcessingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(_brandColor),
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'Re-processing...',
            style: TextStyle(fontSize: 12, color: _textLight),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructions() {
    const instructions = [
      'Select text in any app, then share → TextFixer',
      'OR copy text and use "Fix Clipboard Text" above',
      'Review and edit the improved text',
      'Copy to clipboard and paste anywhere',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'How to use:',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...instructions.asMap().entries.map((entry) {
          return _buildInstructionStep('${entry.key + 1}', entry.value);
        }),
      ],
    );
  }

  Widget _buildInstructionStep(String number, String instruction) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: _brandColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: const TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
