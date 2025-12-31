import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../services/intent_service.dart';
import '../api_service.dart';

class SetupDialog extends StatefulWidget {
  final bool isFromTextSelection;
  final VoidCallback? onApiKeySaved;

  const SetupDialog({
    super.key,
    this.isFromTextSelection = false,
    this.onApiKeySaved,
  });

  @override
  State<SetupDialog> createState() => _SetupDialogState();
}

enum SetupMode { initialChoice, emailInput, manualApiKey }

class _SetupDialogState extends State<SetupDialog> {
  static const Color _brandColor = Color(0xFFA45C40);
  static const int _minApiKeyLength = 20;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _apiKeyController = TextEditingController();
  final StorageService _storage = StorageService();
  final ApiService _apiService = ApiService();
  final GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _apiKeyFormKey = GlobalKey<FormState>();

  bool _isLoading = false;
  SetupMode _currentMode = SetupMode.initialChoice;

  @override
  void dispose() {
    _emailController.dispose();
    _apiKeyController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    Navigator.pop(context);
    if (widget.isFromTextSelection) {
      IntentService.closeApp();
    }
  }

  Future<void> _handleEmailRegistration() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.registerFreeAccount(email);
      
      if (result['success'] == true) {
        if (mounted) {
          Navigator.pop(context);
          _showSuccessSnackBar(
            'Account created! Please check your email for your access code, then return here to enter it.',
          );
          // Note: We intentionally do NOT call widget.onApiKeySaved?.call() 
          // because the user still needs to manually enter the API key from their email
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar(e.toString().replaceFirst('Exception: ', ''));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleManualApiKeySave() async {
    if (!_apiKeyFormKey.currentState!.validate()) return;

    final apiKey = _apiKeyController.text.trim();
    setState(() => _isLoading = true);

    try {
      await _storage.saveApiKey(apiKey);

      if (mounted) {
        Navigator.pop(context);
        _showSuccessSnackBar('Access code saved successfully!');
        widget.onApiKeySaved?.call();
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to save access code. Please try again.');
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

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email address';
    }

    final trimmed = value.trim();
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    return null;
  }

  String? _validateApiKey(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your access code';
    }

    final trimmed = value.trim();
    if (trimmed.length < _minApiKeyLength) {
      return 'Access code seems too short (minimum $_minApiKeyLength characters)';
    }

    return null;
  }

  void _switchToMode(SetupMode mode) {
    setState(() {
      _currentMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        _getDialogTitle(),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: _buildContent(),
      actions: _buildActions(),
    );
  }

  String _getDialogTitle() {
    switch (_currentMode) {
      case SetupMode.initialChoice:
        return 'Setup TextFixer';
      case SetupMode.emailInput:
        return 'Get Your Access Code';
      case SetupMode.manualApiKey:
        return 'Enter Access Code';
    }
  }

  Widget _buildContent() {
    switch (_currentMode) {
      case SetupMode.initialChoice:
        return _buildInitialChoiceContent();
      case SetupMode.emailInput:
        return _buildEmailInputContent();
      case SetupMode.manualApiKey:
        return _buildApiKeyInputContent();
    }
  }

  Widget _buildInitialChoiceContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Do you already have a TextFixer access code?',
          style: TextStyle(fontSize: 16),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'TextFixer works across multiple platforms',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _switchToMode(SetupMode.manualApiKey),
          icon: const Icon(Icons.key),
          label: const Text('I have an access code'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _brandColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => _switchToMode(SetupMode.emailInput),
          icon: const Icon(Icons.email),
          label: const Text('I need an access code'),
          style: OutlinedButton.styleFrom(
            foregroundColor: _brandColor,
            side: const BorderSide(color: _brandColor),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildInitialChoiceInfoCard(),
      ],
    );
  }

  Widget _buildInitialChoiceInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Access codes work across iOS, Android, and web platforms',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailInputContent() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your email to receive your free TextFixer access code:'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _emailController,
            decoration: const InputDecoration(
              hintText: 'your@email.com',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              helperText: 'We\'ll send your access code to this email',
            ),
            keyboardType: TextInputType.emailAddress,
            enabled: !_isLoading,
            validator: _validateEmail,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleEmailRegistration(),
          ),
          const SizedBox(height: 12),
          _buildEmailInfoCard(),
        ],
      ),
    );
  }

  Widget _buildApiKeyInputContent() {
    return Form(
      key: _apiKeyFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Enter your TextFixer access code:'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _apiKeyController,
            decoration: const InputDecoration(
              hintText: 'Paste your access code here',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.key),
              helperText: 'This will be stored securely on your device',
            ),
            maxLines: 3,
            enabled: !_isLoading,
            validator: _validateApiKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _handleManualApiKeySave(),
          ),
          const SizedBox(height: 12),
          _buildApiKeyInfoCard(),
        ],
      ),
    );
  }

  Widget _buildEmailInfoCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.blue.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your access code will be sent to this email',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '• Free account: 20 text fixes per month\n• You\'ll need to copy the code from your email',
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApiKeyInfoCard() {
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
              'Get your access code from textfixer.co.uk',
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

  List<Widget> _buildActions() {
    switch (_currentMode) {
      case SetupMode.initialChoice:
        return [
          TextButton(
            onPressed: _handleCancel,
            child: const Text('Cancel'),
          ),
        ];
      case SetupMode.emailInput:
        return [
          TextButton(
            onPressed: _isLoading ? null : () => _switchToMode(SetupMode.initialChoice),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleEmailRegistration,
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
                : const Text('Send Access Code'),
          ),
        ];
      case SetupMode.manualApiKey:
        return [
          TextButton(
            onPressed: _isLoading ? null : () => _switchToMode(SetupMode.initialChoice),
            child: const Text('Back'),
          ),
          ElevatedButton(
            onPressed: _isLoading ? null : _handleManualApiKeySave,
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
        ];
    }
  }
}
