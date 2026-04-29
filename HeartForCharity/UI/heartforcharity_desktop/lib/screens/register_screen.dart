import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_shared/providers/base_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _orgNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactEmailController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _errorMessage;
  bool _registered = false;
  String _password = '';


  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() {
        _password = _passwordController.text;
      });
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _orgNameController.dispose();
    _descriptionController.dispose();
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = {
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'organisationName': _orgNameController.text.trim(),
        'description': _descriptionController.text.trim().isNotEmpty
            ? _descriptionController.text.trim()
            : null,
        'contactEmail': _contactEmailController.text.trim().isNotEmpty
            ? _contactEmailController.text.trim()
            : null,
        'contactPhone': _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : null,
      };

      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}user/register-organisation'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        setState(() {
          _registered = true;
        });
      } else {
        try {
          final data = jsonDecode(response.body);
          setState(() {
            _errorMessage = data['message'] ?? 'Registration failed.';
          });
        } catch (_) {
          setState(() {
            _errorMessage = 'Registration failed. Please try again.';
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error. Please try again.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: colorScheme.outlineVariant, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: colorScheme.error, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _registered ? _buildSuccessCard(colorScheme) : _buildFormCard(colorScheme),
        ),
      ),
    );
  }

  Widget _buildSuccessCard(ColorScheme colorScheme) {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline, size: 64, color: colorScheme.secondary),
          const SizedBox(height: 16),
          Text(
            'Registration Successful',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'Your organisation account has been created.\nYou can now sign in.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                'Go to Sign In',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(ColorScheme colorScheme) {
    return Container(
      width: 780,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.07),
            blurRadius: 40,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(height: 12),
            Text(
              'Create your account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
            ),
            const SizedBox(height: 4),
            Text(
              'Register your organisation to get started',
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),

            // Two panels side by side
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Organisation Info
                  Expanded(child: _buildOrgPanel(colorScheme)),

                  // Vertical divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: 1,
                      color: colorScheme.outline,
                    ),
                  ),

                  // Right: Account Info
                  Expanded(child: _buildAccountPanel(colorScheme)),
                ],
              ),
            ),

            // Error message
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.error.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: colorScheme.error, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Register button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
                      ),
              ),
            ),

            const SizedBox(height: 16),

            // Back to login
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrgPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Organisation Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Divider(color: colorScheme.outline),
        const SizedBox(height: 8),

        _buildField(
          label: 'Organisation Name',
          controller: _orgNameController,
          hint: 'Enter organisation name',
          icon: Icons.business_outlined,
          colorScheme: colorScheme,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Organisation name is required';
            if (v.length > 200) return 'Max 200 characters';
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Contact Email (optional)',
          controller: _contactEmailController,
          hint: 'Contact email',
          icon: Icons.alternate_email,
          colorScheme: colorScheme,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v != null && v.isNotEmpty) {
              if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
                return 'Enter a valid email';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Contact Phone (optional)',
          controller: _contactPhoneController,
          hint: 'Contact phone',
          icon: Icons.phone_outlined,
          colorScheme: colorScheme,
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v != null && v.trim().isNotEmpty) {
              if (!RegExp(r'^[\+\d\s\-()]{6,20}$').hasMatch(v.trim())) {
                return 'Enter a valid phone (e.g. +387 33 123 456)';
              }
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Description (optional)',
          controller: _descriptionController,
          hint: 'Briefly describe your organisation',
          icon: Icons.description_outlined,
          colorScheme: colorScheme,
          validator: (v) {
            if (v != null && v.length > 2000) return 'Max 2000 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountPanel(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Account Information', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        const SizedBox(height: 4),
        Divider(color: colorScheme.outline),
        const SizedBox(height: 8),

        _buildField(
          label: 'Username',
          controller: _usernameController,
          hint: 'Enter username',
          icon: Icons.person_outline,
          colorScheme: colorScheme,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Username is required';
            if (v.length > 100) return 'Max 100 characters';
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Email',
          controller: _emailController,
          hint: 'Enter email',
          icon: Icons.email_outlined,
          colorScheme: colorScheme,
          keyboardType: TextInputType.emailAddress,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Email is required';
            if (!RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(v)) {
              return 'Enter a valid email';
            }
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Password',
          controller: _passwordController,
          hint: 'Min 8 characters',
          icon: Icons.lock_outline,
          colorScheme: colorScheme,
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Password is required';
            if (v.length < 8) return 'Min 8 characters';
            if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain an uppercase letter';
            if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must contain a lowercase letter';
            if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
            if (!RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(v)) return 'Must contain a special character';
            return null;
          },
        ),
        if (_password.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildPasswordChecklist(colorScheme),
        ],
        const SizedBox(height: 10),

        _buildField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          colorScheme: colorScheme,
          obscure: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
          ),
          validator: (v) {
            if (v == null || v.isEmpty) return 'Please confirm password';
            if (v != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordChecklist(ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckRow('At least 8 characters', _password.length >= 8, colorScheme),
        _buildCheckRow('One uppercase letter', RegExp(r'[A-Z]').hasMatch(_password), colorScheme),
        _buildCheckRow('One lowercase letter', RegExp(r'[a-z]').hasMatch(_password), colorScheme),
        _buildCheckRow('One number', RegExp(r'[0-9]').hasMatch(_password), colorScheme),
        _buildCheckRow('One special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(_password), colorScheme),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool met, ColorScheme colorScheme) {
    final color = met ? colorScheme.secondary : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    required ColorScheme colorScheme,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: colorScheme.onSurface)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          decoration: _inputDecoration(hint: hint, icon: icon, colorScheme: colorScheme, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }
}
