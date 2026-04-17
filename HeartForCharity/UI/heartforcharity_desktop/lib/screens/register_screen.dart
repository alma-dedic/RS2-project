import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:heartforcharity_desktop/providers/base_provider.dart';

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
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }

  static const _labelStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: Color(0xFF374151),
  );

  static const _sectionStyle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: Color(0xFF1A1A2E),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: _registered ? _buildSuccessCard() : _buildFormCard(),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      width: 420,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
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
          const Icon(Icons.check_circle_outline, size: 64, color: Color(0xFF22C55E)),
          const SizedBox(height: 16),
          const Text(
            'Registration Successful',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your organisation account has been created.\nYou can now sign in.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF), height: 1.5),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD1493F),
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

  Widget _buildFormCard() {
    return Container(
      width: 780,
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
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
            const Text(
              'Create your account',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Register your organisation to get started',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
            const SizedBox(height: 16),

            // Two panels side by side
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Organisation Info
                  Expanded(child: _buildOrgPanel()),

                  // Vertical divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      width: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),

                  // Right: Account Info
                  Expanded(child: _buildAccountPanel()),
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
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Color(0xFFDC2626)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFFDC2626), fontSize: 13),
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
                  backgroundColor: const Color(0xFFD1493F),
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
                const Text(
                  'Already have an account? ',
                  style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD1493F),
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

  Widget _buildOrgPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Organisation Information', style: _sectionStyle),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 8),

        _buildField(
          label: 'Organisation Name',
          controller: _orgNameController,
          hint: 'Enter organisation name',
          icon: Icons.business_outlined,
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
          keyboardType: TextInputType.phone,
          validator: (v) {
            if (v != null && v.length > 20) return 'Max 20 characters';
            return null;
          },
        ),
        const SizedBox(height: 10),

        _buildField(
          label: 'Description (optional)',
          controller: _descriptionController,
          hint: 'Briefly describe your organisation',
          icon: Icons.description_outlined,
          validator: (v) {
            if (v != null && v.length > 2000) return 'Max 2000 characters';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountPanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Account Information', style: _sectionStyle),
        const SizedBox(height: 4),
        const Divider(color: Color(0xFFE5E7EB)),
        const SizedBox(height: 8),

        _buildField(
          label: 'Username',
          controller: _usernameController,
          hint: 'Enter username',
          icon: Icons.person_outline,
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
          obscure: _obscurePassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF9CA3AF),
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
          _buildPasswordChecklist(),
        ],
        const SizedBox(height: 10),

        _buildField(
          label: 'Confirm Password',
          controller: _confirmPasswordController,
          hint: 'Re-enter password',
          icon: Icons.lock_outline,
          obscure: _obscureConfirmPassword,
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 18,
              color: const Color(0xFF9CA3AF),
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

  Widget _buildPasswordChecklist() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCheckRow('At least 8 characters', _password.length >= 8),
        _buildCheckRow('One uppercase letter', RegExp(r'[A-Z]').hasMatch(_password)),
        _buildCheckRow('One lowercase letter', RegExp(r'[a-z]').hasMatch(_password)),
        _buildCheckRow('One number', RegExp(r'[0-9]').hasMatch(_password)),
        _buildCheckRow('One special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(_password)),
      ],
    );
  }

  Widget _buildCheckRow(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: met ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffixIcon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: _inputDecoration(hint: hint, icon: icon, suffixIcon: suffixIcon),
          validator: validator,
        ),
      ],
    );
  }
}
