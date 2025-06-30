import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../services/intent_service.dart';

class SetupDialog extends StatefulWidget {
  final bool isFromTextSelection;
  final VoidCallback? onApiKeySaved;

  const SetupDialog({
    Key? key,
    this.isFromTextSelection = false,
    this.onApiKeySaved,
  }) : super(key: key);

  @override
  State<SetupDialog> createState() => _SetupDialogState();
}

class _SetupDialogState extends State<SetupDialog> {
  static const Color _brandColor = Color(0xFFA45C40);
  static const int _minApiKeyLength = 20;

  final TextEditingController _controller = TextEditingController();
  final StorageService _storage = StorageService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleCancel() {
    Navigator.pop(context);
    if (widget.isFromTextSelection) {
      IntentService.closeApp();
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    final apiKey = _controller.text.trim();

    setState(() => _isLoading = true);

    try {
      await _storage.saveApiKey(apiKey);

      if (mounted) {
        Navigator.pop(context);
        widget.onApiKeySaved?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save API key. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateApiKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your API key';
    }

    final trimmed = value.trim();
    if (trimmed.length < _minApiKeyLength) {
      return 'API key seems too short (minimum $_minApiKeyLength characters)';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Setup TextFixer',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your TextFixer API key to get started:'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: 'Paste your API key here',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.key),
                helperText: 'This will be stored securely on your device',
              ),
              maxLines: 3,
              enabled: !_isLoading,
              validator: _validateApiKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleSave(),
            ),
            const SizedBox(height: 12),
            _buildInfoCard(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _handleCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Get your API key from textfixer.co.uk',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
