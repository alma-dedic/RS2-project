import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_profile_provider.dart';
import 'package:heartforcharity_desktop/providers/upload_provider.dart';
import 'package:heartforcharity_desktop/screens/login_screen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  final VoidCallback? onProfileUpdated;

  const ProfileScreen({super.key, this.onProfileUpdated});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  OrganisationProfile? _profile;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _localLogoPath;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final profile = await context.read<OrganisationProfileProvider>().getMe();
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startEditing() {
    _nameController.text = _profile?.name ?? '';
    _descController.text = _profile?.description ?? '';
    _emailController.text = _profile?.contactEmail ?? '';
    _phoneController.text = _profile?.contactPhone ?? '';
    _localLogoPath = null;
    setState(() => _isEditing = true);
  }

  void _cancelEditing() => setState(() => _isEditing = false);

  Future<void> _pickLogo() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _localLogoPath = result.files.single.path!);
    }
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Organisation name is required.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final orgProvider = context.read<OrganisationProfileProvider>();
      final uploadProvider = context.read<UploadProvider>();

      String? logoUrl = _profile?.logoUrl;
      if (_localLogoPath != null) {
        logoUrl = await uploadProvider.uploadImage(_localLogoPath!);
      }

      await orgProvider.update(
        _profile!.organisationProfileId,
        {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          'contactEmail': _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          'contactPhone': _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          'logoUrl': logoUrl,
          'organisationTypeId': _profile?.organisationTypeId,
          'addressId': _profile?.addressId,
        },
      );

      await _loadProfile();
      widget.onProfileUpdated?.call();
      if (mounted) setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? currentError;
    String? newError;
    String? confirmError;
    bool isSaving = false;

    String? _validateNew(String val) {
      if (val.isEmpty) return 'New password is required.';
      if (val.length < 8) return 'Must be at least 8 characters.';
      if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain an uppercase letter.';
      if (!RegExp(r'[a-z]').hasMatch(val)) return 'Must contain a lowercase letter.';
      if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain a number.';
      if (!RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(val)) return 'Must contain a special character.';
      if (val == currentCtrl.text && currentCtrl.text.isNotEmpty) return 'New password must differ from current.';
      return null;
    }

    String? _validateConfirm(String val) {
      if (val.isEmpty) return 'Please confirm your new password.';
      if (val != newCtrl.text) return 'Passwords do not match.';
      return null;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Change password',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _PasswordField(
                    controller: currentCtrl,
                    label: 'Current password',
                    obscure: obscureCurrent,
                    errorText: currentError,
                    onToggle: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    onChanged: (_) => setDialogState(() {
                      currentError = null;
                      newError = _validateNew(newCtrl.text);
                    }),
                  ),
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: newCtrl,
                    label: 'New password',
                    obscure: obscureNew,
                    errorText: newError,
                    onToggle: () => setDialogState(() => obscureNew = !obscureNew),
                    onChanged: (val) => setDialogState(() {
                      newError = _validateNew(val);
                      if (confirmCtrl.text.isNotEmpty) confirmError = _validateConfirm(confirmCtrl.text);
                    }),
                  ),
                  if (newCtrl.text.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _PasswordChecklist(password: newCtrl.text),
                  ],
                  const SizedBox(height: 14),
                  _PasswordField(
                    controller: confirmCtrl,
                    label: 'Confirm new password',
                    obscure: obscureConfirm,
                    errorText: confirmError,
                    onToggle: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    onChanged: (val) => setDialogState(() => confirmError = _validateConfirm(val)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                        style: _outlinedStyle(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setDialogState(() {
                                  currentError = currentCtrl.text.isEmpty ? 'Current password is required.' : null;
                                  newError = _validateNew(newCtrl.text);
                                  confirmError = _validateConfirm(confirmCtrl.text);
                                });
                                if (currentError != null || newError != null || confirmError != null) return;

                                setDialogState(() => isSaving = true);
                                try {
                                  await context.read<AuthProvider>().changePassword(
                                    currentCtrl.text,
                                    newCtrl.text,
                                  );
                                  if (ctx.mounted) Navigator.of(ctx).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password changed successfully.')),
                                    );
                                  }
                                } catch (e) {
                                  final msg = e.toString().replaceFirst('Exception: ', '');
                                  setDialogState(() {
                                    isSaving = false;
                                    if (msg.toLowerCase().contains('incorrect') || msg.toLowerCase().contains('current')) {
                                      currentError = msg;
                                    } else {
                                      newError = msg;
                                    }
                                  });
                                }
                              },
                        style: _primaryStyle(),
                        child: isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Change password'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog() async {
    final confirmCtrl = TextEditingController();
    final orgName = _profile?.name ?? '';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text('Delete account',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: const Icon(Icons.close, size: 20, color: Color(0xFF6B7280)),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This action cannot be undone. Your account will be deactivated immediately and you will be logged out.',
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECACA)),
                    ),
                    child: const Text(
                      'Note: accounts with active campaigns or volunteer jobs cannot be deleted. Please complete or cancel them first.',
                      style: TextStyle(fontSize: 12, color: Color(0xFFEF4444), height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Type "$orgName" to confirm:',
                    style: const TextStyle(fontSize: 13, color: Color(0xFF374151), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: orgName,
                      hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        style: _outlinedStyle(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: confirmCtrl.text == orgName
                            ? () async {
                                Navigator.of(ctx).pop();
                                try {
                                  await context.read<AuthProvider>().deleteAccount();
                                  if (mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (_) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('$e')),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEF4444),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFFFCA5A5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Delete account'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFFD1493F)))
                  : _profile == null
                      ? const Center(child: Text('Could not load profile.'))
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(),
                              const SizedBox(height: 20),
                              _buildSecurityCard(),
                              const SizedBox(height: 20),
                              _buildDangerCard(),
                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLogo(),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_isEditing)
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                        decoration: _fieldDecoration('Organisation name'),
                      )
                    else
                      Text(
                        _profile!.name,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                      ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (_profile!.organisationTypeName != null)
                          Text(
                            _profile!.organisationTypeName!,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                          ),
                        if (_profile!.organisationTypeName != null) const SizedBox(width: 12),
                        _VerifiedBadge(isVerified: _profile!.isVerified),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (!_isEditing)
                OutlinedButton.icon(
                  onPressed: _startEditing,
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Edit profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFD1493F),
                    side: const BorderSide(color: Color(0xFFD1493F)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                )
              else
                Row(
                  children: [
                    OutlinedButton(
                      onPressed: _isSaving ? null : _cancelEditing,
                      style: _outlinedStyle(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: _primaryStyle(),
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            const Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 1000,
              style: const TextStyle(fontSize: 13),
              decoration: _fieldDecoration('Describe your organisation...'),
            ),
            const SizedBox(height: 20),
            const Text('Contact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration('Contact email').copyWith(prefixIcon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF9CA3AF))),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration('Contact phone').copyWith(prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF9CA3AF))),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_profile!.description != null && _profile!.description!.isNotEmpty) ...[
              const Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
              const SizedBox(height: 8),
              Text(_profile!.description!, style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.6)),
              const SizedBox(height: 20),
            ],
            if (_profile!.contactEmail != null)
              _InfoRow(icon: Icons.email_outlined, value: _profile!.contactEmail!),
            if (_profile!.contactPhone != null)
              _InfoRow(icon: Icons.phone_outlined, value: _profile!.contactPhone!),
            if (_profile!.cityName != null || _profile!.countryName != null)
              _InfoRow(
                icon: Icons.location_on_outlined,
                value: [_profile!.cityName, _profile!.countryName].where((s) => s != null).join(', '),
              ),
            if (_profile!.createdAt != null)
              _InfoRow(
                icon: Icons.calendar_today_outlined,
                value: 'Member since ${DateFormat('MMMM yyyy').format(_profile!.createdAt!)}',
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogo() {
    const size = 80.0;
    Widget inner;

    if (_isEditing && _localLogoPath != null) {
      inner = Image.file(File(_localLogoPath!), fit: BoxFit.cover, errorBuilder: (_, e, s) => _logoPlaceholder());
    } else if (_profile?.logoUrl != null && _profile!.logoUrl!.isNotEmpty) {
      inner = Image.network(_profile!.logoUrl!, fit: BoxFit.cover, errorBuilder: (_, e, s) => _logoPlaceholder());
    } else {
      inner = _logoPlaceholder();
    }

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFD1493F).withValues(alpha: 0.08),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
      ),
      child: ClipOval(child: inner),
    );

    if (!_isEditing) return circle;

    return GestureDetector(
      onTap: _pickLogo,
      child: Stack(
        children: [
          circle,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 26,
              height: 26,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFFD1493F),
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    final initials = (_profile?.name ?? 'O').substring(0, 1).toUpperCase();
    return Center(
      child: Text(initials, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Color(0xFFD1493F))),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFD1493F).withValues(alpha: 0.08),
          ),
          child: const Icon(Icons.lock_outline, size: 20, color: Color(0xFFD1493F)),
        ),
        title: const Text('Change password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
        subtitle: const Text('Update your account password', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF9CA3AF)),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  Widget _buildDangerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Danger zone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFEF4444))),
          const SizedBox(height: 8),
          const Text(
            'Deleting your account will deactivate it immediately. You will lose access to all your campaigns and volunteer jobs.',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280), height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showDeleteDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFEF4444),
              side: const BorderSide(color: Color(0xFFEF4444)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
            child: const Text('Delete account'),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      );

  InputDecoration _fieldDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 13),
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5)),
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF374151),
        side: const BorderSide(color: Color(0xFFD1D5DB)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  ButtonStyle _primaryStyle() => ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFD1493F),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String value;
  const _InfoRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF9CA3AF)),
          const SizedBox(width: 10),
          Text(value, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
        ],
      ),
    );
  }
}

class _VerifiedBadge extends StatelessWidget {
  final bool isVerified;
  const _VerifiedBadge({required this.isVerified});

  @override
  Widget build(BuildContext context) {
    final color = isVerified ? const Color(0xFF10B981) : const Color(0xFF9CA3AF);
    final icon = isVerified ? Icons.verified_outlined : Icons.pending_outlined;
    final label = isVerified ? 'Verified' : 'Pending verification';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool obscure;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;
  final String? errorText;

  const _PasswordField({
    required this.controller,
    required this.label,
    required this.obscure,
    required this.onToggle,
    this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444))),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: const Color(0xFF9CA3AF)),
          onPressed: onToggle,
          splashRadius: 18,
        ),
      ),
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  final String password;
  const _PasswordChecklist({required this.password});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row('At least 8 characters', password.length >= 8),
        _row('One uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
        _row('One lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
        _row('One number', RegExp(r'[0-9]').hasMatch(password)),
        _row('One special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(password)),
      ],
    );
  }

  Widget _row(String label, bool met) {
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
            style: TextStyle(fontSize: 12, color: met ? const Color(0xFF22C55E) : const Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}
