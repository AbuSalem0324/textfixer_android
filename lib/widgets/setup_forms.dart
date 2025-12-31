import 'package:flutter/material.dart';
import '/storage_service.dart';
import '../api_service.dart';

enum SetupMode { initialChoice, emailInput, manualApiKey }

class SetupForms extends StatefulWidget {
  final VoidCallback? onApiKeySaved;
  final Function(String, {bool isSuccess})? onShowMessage;

  const SetupForms({
    super.key,
    this.onApiKeySaved,
    this.onShowMessage,
  });

  @override
  State<SetupForms> createState() => _SetupFormsState();
}

class _SetupFormsState extends State<SetupForms> {
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

  Future<void> _handleEmailRegistration() async {
    if (!_emailFormKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() => _isLoading = true);

    try {
      final result = await _apiService.registerFreeAccount(email);

      if (result['success'] == true) {
        if (mounted) {
          // Show dialog instead of toast
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: Colors.green[600], size: 28),
                    const SizedBox(width: 12),
                    const Text('Access Code Sent'),
                  ],
                ),
                content: Text(
                  'We\'ve sent your access code to ${_emailController.text.trim()}. Please check your email and return here to enter it.',
                  style: const TextStyle(fontSize: 14),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      // Switch to API key input mode
                      _switchToMode(SetupMode.manualApiKey);
                    },
                    child: const Text(
                      'OK',
                      style: TextStyle(
                        color: _brandColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(e.toString().replaceFirst('Exception: ', ''),
            isSuccess: false);
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
        _showMessage('Access code saved successfully!', isSuccess: true);
        widget.onApiKeySaved?.call();
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Failed to save access code. Please try again.',
            isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showMessage(String message, {bool isSuccess = false}) {
    widget.onShowMessage?.call(message, isSuccess: isSuccess);
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<SetupMode>(_currentMode),
          child: _buildContent(),
        ),
      ),
    );
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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

  Widget _buildEmailInputContent() {
    return Form(
      key: _emailFormKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _switchToMode(SetupMode.initialChoice),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
              'Enter your email to receive your free TextFixer access code:'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                // Inner shadow effect - dark on bottom-right
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
                // Inner shadow effect - light on top-left
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
                // Subtle outer shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'your@email.com',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                prefixIcon: Icon(Icons.email),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                helperText: 'We\'ll send your access code to this email',
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
              validator: _validateEmail,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleEmailRegistration(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleEmailRegistration,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
          ),
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
          Row(
            children: [
              IconButton(
                onPressed: () => _switchToMode(SetupMode.initialChoice),
                icon: const Icon(Icons.arrow_back),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Back',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                // Inner shadow effect - dark on bottom-right
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  offset: const Offset(3, 3),
                  blurRadius: 6,
                  spreadRadius: -2,
                ),
                // Inner shadow effect - light on top-left
                BoxShadow(
                  color: Colors.white.withValues(alpha: 0.8),
                  offset: const Offset(-2, -2),
                  blurRadius: 4,
                  spreadRadius: -1,
                ),
                // Subtle outer shadow for depth
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: TextFormField(
              controller: _apiKeyController,
              decoration: const InputDecoration(
                hintText: 'Paste your access code here',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
                prefixIcon: Icon(Icons.key),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                helperText: 'This will be stored securely on your device',
              ),
              maxLines: 3,
              enabled: !_isLoading,
              validator: _validateApiKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleManualApiKeySave(),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleManualApiKeySave,
              style: ElevatedButton.styleFrom(
                backgroundColor: _brandColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
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
                  : const Text('Save Access Code'),
            ),
          ),
        ],
      ),
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
              'Free accounts get 20 fixes/month',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
