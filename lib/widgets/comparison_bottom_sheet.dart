import 'package:flutter/material.dart';
import '/models/clipboard_processing_result.dart';

/// Bottom sheet for comparing original vs fixed text
/// Shows usage stats, original text (read-only), and fixed text (editable)
class ComparisonBottomSheet extends StatefulWidget {
  final String originalText;
  final String? fixedText;
  final ClipboardProcessingResult? result;
  final Function(String) onRefix;
  final VoidCallback onCopy;
  final VoidCallback onClose;
  final bool isRefixing;

  const ComparisonBottomSheet({
    super.key,
    required this.originalText,
    this.fixedText,
    this.result,
    required this.onRefix,
    required this.onCopy,
    required this.onClose,
    this.isRefixing = false,
  });

  @override
  State<ComparisonBottomSheet> createState() => _ComparisonBottomSheetState();
}

class _ComparisonBottomSheetState extends State<ComparisonBottomSheet> {
  static const Color _brandColor = Color(0xFFA45C40);
  static const Color _lightBackground = Color(0xFFF6F4EA);
  static const Color _borderColor = Color(0xFFE6D7C1);
  static const Color _textDark = Color(0xFF4A3933);
  static const Color _textLight = Color(0xFF847C74);

  late TextEditingController _fixedTextController;
  late FocusNode _focusNode;
  bool _isOriginalExpanded = false;

  @override
  void initState() {
    super.initState();
    _fixedTextController = TextEditingController(text: widget.fixedText ?? '');
    _focusNode = FocusNode();
  }

  @override
  void didUpdateWidget(ComparisonBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when fixed text arrives from API
    // But don't overwrite if user is actively editing
    if (widget.fixedText != oldWidget.fixedText &&
        widget.fixedText != null &&
        widget.fixedText != _fixedTextController.text) {
      // Check if widget is still mounted before updating controller
      if (mounted) {
        // Use value.copyWith for safer updates
        _fixedTextController.value = _fixedTextController.value.copyWith(
          text: widget.fixedText!,
          selection: TextSelection.collapsed(offset: widget.fixedText!.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _fixedTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              _buildDragHandle(),

              // Usage stats bar (if available)
              if (widget.result != null) _buildUsageBar(),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildOriginalSection(),
                      const SizedBox(height: 16),
                      _buildSeparator(),
                      const SizedBox(height: 16),
                      _buildFixedSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Bottom action bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildActionButtons(),
          ),

          // Loading overlay for refix
          if (widget.isRefixing)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Re-fixing your text...'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Widget _buildUsageBar() {
    final result = widget.result!;
    final isApproaching = result.isApproachingLimit;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.monthlyRequests} / ${result.monthlyLimit} requests',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isApproaching ? Colors.orange[900] : Colors.grey[700],
                  ),
                ),
                Text(
                  '${result.characterLimitPerRequest} chars per request',
                  style: TextStyle(
                    fontSize: 10,
                    color:
                        isApproaching ? Colors.orange[700] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _brandColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _brandColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              result.subscriptionTier?.toUpperCase() ?? 'FREE',
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _brandColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tappable header
        InkWell(
          onTap: () {
            setState(() {
              _isOriginalExpanded = !_isOriginalExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _borderColor),
            ),
            child: Row(
              children: [
                Icon(
                  _isOriginalExpanded ? Icons.expand_less : Icons.chevron_right,
                  size: 20,
                  color: _textDark,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Original Text',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
                const Spacer(),
                if (!_isOriginalExpanded)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Text(
                      'Tap to expand',
                      style: TextStyle(
                        fontSize: 11,
                        color: _textLight,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Text(
                  '${widget.originalText.length} chars',
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textLight,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Expandable content with smooth animation
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: _isOriginalExpanded
              ? Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: _borderColor),
                      ),
                      child: Text(
                        widget.originalText,
                        style: const TextStyle(
                          fontSize: 14,
                          color: _textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Column(
            children: [
              Icon(Icons.arrow_downward, size: 16, color: Colors.grey[600]),
              const SizedBox(height: 4),
              Text(
                'Fixed to',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Icon(Icons.arrow_downward, size: 16, color: Colors.grey[600]),
            ],
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildFixedSection() {
    final isLoading = widget.fixedText == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Fixed Text',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
            if (!isLoading)
              Text(
                '${_fixedTextController.text.length} characters',
                style: const TextStyle(
                  fontSize: 12,
                  color: _textLight,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Loading state or editable text field
        if (isLoading) _buildLoadingState() else _buildEditableTextField(),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _lightBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: const Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Fixing your text...',
            style: TextStyle(
              fontSize: 14,
              color: _textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableTextField() {
    return TextField(
      controller: _fixedTextController,
      focusNode: _focusNode,
      maxLines: null,
      minLines: 3, // Reduced for overlay
      autofocus: true, // Auto-focus for overlay
      keyboardType: TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onTap: () {
        _focusNode.requestFocus();
      },
      style: const TextStyle(
        fontSize: 14,
        color: _textDark,
        height: 1.5,
      ),
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.all(12),
        filled: true,
        fillColor: Colors.white,
        hintText: 'Edit text if needed...',
        hintStyle: const TextStyle(color: _textLight),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _brandColor.withValues(alpha: 0.3), width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _brandColor, width: 2),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final canRefix = widget.fixedText != null && !widget.isRefixing;
    final canCopy = widget.fixedText != null && !widget.isRefixing;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: _borderColor),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Refix button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: canRefix
                  ? () => widget.onRefix(_fixedTextController.text)
                  : null,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Refix'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _brandColor,
                side: BorderSide(color: canRefix ? _brandColor : Colors.grey),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Copy button (primary)
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: canCopy ? widget.onCopy : null,
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                disabledBackgroundColor: Colors.grey[300],
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Close button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: widget.onClose,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Close'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _textLight,
                side: BorderSide(color: Colors.grey[400]!),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
