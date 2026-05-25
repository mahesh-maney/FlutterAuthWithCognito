import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../services/auth_service.dart';

class TotpSetupScreen extends StatefulWidget {
  final String userEmail;

  const TotpSetupScreen({super.key, required this.userEmail});

  @override
  State<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends State<TotpSetupScreen> {
  final _authService = AuthService();
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  String? _otpauthUri;
  bool _isLoadingSecret = true;
  bool _isVerifying = false;

  @override
  void initState() {
    super.initState();
    _startTotpSetup();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _startTotpSetup() async {
    try {
      final details = await _authService.setUpTotp();
      final uri = details.getSetupUri(
        appName: 'FlutterAuth',
        accountName: widget.userEmail,
      );
      setState(() {
        _otpauthUri = uri.toString();
        _isLoadingSecret = false;
      });
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _verifyCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isVerifying = true);
    try {
      await _authService.verifyTotpSetup(_codeController.text.trim());
      if (mounted) {
        Navigator.pop(context, true);
      }
    } on Exception catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Authenticator')),
      body: SafeArea(
        child: _isLoadingSecret
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Scan this QR code',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Open Google Authenticator or Authy and scan the QR code below to add your account.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // QR Code
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(20),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: QrImageView(
                            data: _otpauthUri!,
                            version: QrVersions.auto,
                            size: 220,
                            backgroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      const Divider(),
                      const SizedBox(height: 16),

                      Text(
                        'Enter the 6-digit code from your app',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'After scanning, enter the code shown in your authenticator app to confirm setup.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        autofocus: false,
                        style: const TextStyle(fontSize: 28, letterSpacing: 10),
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          counterText: '',
                          hintText: '------',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) return 'Code is required';
                          if (value.length < 6) return 'Enter the full 6-digit code';
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        onPressed: _isVerifying ? null : _verifyCode,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text('Verify & Enable',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
