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
  final TextEditingController _controller = TextEditingController();
  final StorageService _storage = StorageService();
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
    final apiKey = _controller.text.trim();
    if (apiKey.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _storage.saveApiKey(apiKey);

      if (mounted) {
        Navigator.pop(context);
        widget.onApiKeySaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save API key')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Setup TextFixer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your TextFixer API key:'),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(
              hintText: 'Paste your API key here',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            enabled: !_isLoading,
          ),
          const SizedBox(height: 8),
          Text(
            'You can get your API key from textfixer.co.uk',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _handleCancel,
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}
