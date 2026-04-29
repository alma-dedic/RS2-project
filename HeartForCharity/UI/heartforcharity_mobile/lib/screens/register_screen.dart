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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

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
      setState(() => _password = _passwordController.text);
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final body = <String, dynamic>{
        'username': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'firstName': _firstNameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
      };
      if (_phoneController.text.trim().isNotEmpty) {
        body['phoneNumber'] = _phoneController.text.trim();
      }

      final response = await http.post(
        Uri.parse('${BaseProvider.baseUrl}user/register-user'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (!mounted) return;

      if (response.statusCode == 200 || response.statusCode == 201) {
        setState(() => _registered = true);
      } else {
        try {
          final data = jsonDecode(response.body);
          setState(() => _errorMessage = data['message'] ?? 'Registration failed.');
        } catch (_) {
          setState(() => _errorMessage = 'Registration failed. Please try again.');
        }
      }
    } catch (e) {
      setState(() => _errorMessage = 'Connection error. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
        centerTitle: true,
      ),
      body: _registered
          ? _buildSuccessScreen(colorScheme)
          : _buildForm(colorScheme),
    );
  }

  Widget _buildSuccessScreen(ColorScheme colorScheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: colorScheme.secondary),
            const SizedBox(height: 20),
            Text(
              'Registration Successful!',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your account has been created.\nYou can now sign in.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Go to Sign In',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Center(child: Image.asset('assets/logo.png', height: 64)),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Fill in your details to get started',
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
              ),
            ),
            const SizedBox(height: 24),

            // Section: Personal Info
            _buildSectionHeader('Personal Information', colorScheme),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildField(
                    label: 'First Name',
                    controller: _firstNameController,
                    hint: 'First name',
                    icon: Icons.person_outline,
                    colorScheme: colorScheme,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.trim().length < 2) return 'Min 2 characters';
                      if (v.length > 100) return 'Max 100 chars';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    label: 'Last Name',
                    controller: _lastNameController,
                    hint: 'Last name',
                    icon: Icons.person_outline,
                    colorScheme: colorScheme,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.trim().length < 2) return 'Min 2 characters';
                      if (v.length > 100) return 'Max 100 chars';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            _buildField(
              label: 'Phone Number (optional)',
              controller: _phoneController,
              hint: 'e.g. +387 61 123 456',
              icon: Icons.phone_outlined,
              colorScheme: colorScheme,
              keyboardType: TextInputType.phone,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  if (!RegExp(r'^[\+\d\s\-()]{6,20}$').hasMatch(v.trim())) {
                    return 'Enter a valid phone (e.g. +387 61 123 456)';
                  }
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Section: Account Info
            _buildSectionHeader('Account Information', colorScheme),
            const SizedBox(height: 12),

            _buildField(
              label: 'Username',
              controller: _usernameController,
              hint: 'Choose a username',
              icon: Icons.alternate_email,
              colorScheme: colorScheme,
              validator: (v) {
                if (v == null || v.isEmpty) return 'Username is required';
                if (v.trim().length < 3) return 'Min 3 characters';
                if (v.length > 100) return 'Max 100 characters';
                return null;
              },
            ),
            const SizedBox(height: 14),

            _buildField(
              label: 'Email',
              controller: _emailController,
              hint: 'Enter your email',
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
            const SizedBox(height: 14),

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
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 8) return 'Minimum 8 characters';
                if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Must contain an uppercase letter';
                if (!RegExp(r'[a-z]').hasMatch(v)) return 'Must contain a lowercase letter';
                if (!RegExp(r'[0-9]').hasMatch(v)) return 'Must contain a number';
                if (!RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(v)) {
                  return 'Must contain a special character';
                }
                return null;
              },
            ),
            if (_password.isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildPasswordChecklist(colorScheme),
            ],
            const SizedBox(height: 14),

            _buildField(
              label: 'Confirm Password',
              controller: _confirmPasswordController,
              hint: 'Re-enter your password',
              icon: Icons.lock_outline,
              colorScheme: colorScheme,
              obscure: _obscureConfirmPassword,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
                onPressed: () =>
                    setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordController.text) return 'Passwords do not match';
                return null;
              },
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

            const SizedBox(height: 28),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        'Create Account',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account? ',
                    style: TextStyle(fontSize: 14, color: colorScheme.onSurfaceVariant),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Divider(color: colorScheme.outline, height: 1),
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
        _buildCheckRow(
          'One special character (!@#\$%^&*)',
          RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(_password),
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool met, ColorScheme colorScheme) {
    final color = met ? colorScheme.secondary : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: color,
          ),
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
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          style: TextStyle(fontSize: 14, color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: colorScheme.outlineVariant, fontSize: 14),
            prefixIcon: Icon(icon, size: 20, color: colorScheme.onSurfaceVariant),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: colorScheme.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: colorScheme.error, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
