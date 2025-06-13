import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../../services/intent_service.dart';

class SetupDialog extends StatefulWidget {
  final bool isFromTextSelection;
  final VoidCallback? onApiKeySaved;

  const SetupDialog({
    Key? key,
    this.isFromTextSelection = false,
    this.onApiKeySaved,
  }) : super(key: key);

  @override
  _SetupDialogState createState() => _SetupDialogState();
}

class _SetupDialogState extends State<SetupDialog> {
  final TextEditingController _controller = TextEditingController();
  final StorageService _storage = StorageService();

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
    if (apiKey.isNotEmpty) {
      await _storage.saveApiKey(apiKey);
      Navigator.pop(context);

      if (widget.onApiKeySaved != null) {
        widget.onApiKeySaved!();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Setup TextFixer'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Enter your TextFixer API key:'),
          SizedBox(height: 16),
          TextField(
            controller: _controller,
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
          onPressed: _handleCancel,
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _handleSave,
          child: Text('Save'),
        ),
      ],
    );
  }
}
