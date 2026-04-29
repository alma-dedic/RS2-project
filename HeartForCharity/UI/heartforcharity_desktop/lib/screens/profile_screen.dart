import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/utils/auth_image.dart';
import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_shared/providers/base_provider.dart';
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
  String? _nameError;
  String? _emailError;
  String? _phoneError;

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
          SnackBar(content: Text('Failed to load profile: ${BaseProvider.cleanError(e)}')),
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

  void _cancelEditing() => setState(() {
        _isEditing = false;
        _nameError = null;
        _emailError = null;
        _phoneError = null;
      });

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
    final nameVal = _nameController.text.trim();
    final emailVal = _emailController.text.trim();
    final phoneVal = _phoneController.text.trim();
    final nameErr = nameVal.isEmpty
        ? 'Organisation name is required.'
        : nameVal.length > 200 ? 'Max 200 characters.' : null;
    final emailErr = emailVal.isNotEmpty &&
            !RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,}$').hasMatch(emailVal)
        ? 'Enter a valid email address (e.g. info@org.com).'
        : null;
    final phoneErr = phoneVal.isNotEmpty &&
            !RegExp(r'^[+\d\s\-()]{6,20}$').hasMatch(phoneVal)
        ? 'Enter a valid phone number (e.g. +387 33 123 456).'
        : null;
    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _phoneError = phoneErr;
    });
    if (nameErr != null || emailErr != null || phoneErr != null) return;

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
          SnackBar(content: Text(BaseProvider.cleanError(e))),
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

    String? validateNew(String val) {
      if (val.isEmpty) return 'New password is required.';
      if (val.length < 8) return 'Must be at least 8 characters.';
      if (!RegExp(r'[A-Z]').hasMatch(val)) return 'Must contain an uppercase letter.';
      if (!RegExp(r'[a-z]').hasMatch(val)) return 'Must contain a lowercase letter.';
      if (!RegExp(r'[0-9]').hasMatch(val)) return 'Must contain a number.';
      if (!RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(val)) return 'Must contain a special character.';
      if (val == currentCtrl.text && currentCtrl.text.isNotEmpty) return 'New password must differ from current.';
      return null;
    }

    String? validateConfirm(String val) {
      if (val.isEmpty) return 'Please confirm your new password.';
      if (val != newCtrl.text) return 'Passwords do not match.';
      return null;
    }

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
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
                      Expanded(
                        child: Text('Change password',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.onSurface)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close, size: 20, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
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
                      if (newCtrl.text.isNotEmpty) {
                        newError = validateNew(newCtrl.text);
                      }
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
                      newError = validateNew(val);
                      if (confirmCtrl.text.isNotEmpty) confirmError = validateConfirm(confirmCtrl.text);
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
                    onChanged: (val) => setDialogState(() => confirmError = validateConfirm(val)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: isSaving ? null : () => Navigator.of(ctx).pop(),
                        style: _outlinedStyle(Theme.of(ctx).colorScheme),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                setDialogState(() {
                                  currentError = currentCtrl.text.isEmpty ? 'Current password is required.' : null;
                                  newError = validateNew(newCtrl.text);
                                  confirmError = validateConfirm(confirmCtrl.text);
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
                        style: _primaryStyle(Theme.of(ctx).colorScheme),
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
                      Expanded(
                        child: Text('Delete account',
                            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Theme.of(ctx).colorScheme.error)),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        icon: Icon(Icons.close, size: 20, color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                        splashRadius: 18,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This action cannot be undone. Your account will be deactivated immediately and you will be logged out.',
                    style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurfaceVariant, height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.25)),
                    ),
                    child: Text(
                      'Note: accounts with active campaigns or volunteer jobs cannot be deleted. Please complete or cancel them first.',
                      style: TextStyle(fontSize: 12, color: Theme.of(ctx).colorScheme.error, height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Type "$orgName" to confirm:',
                    style: TextStyle(fontSize: 13, color: Theme.of(ctx).colorScheme.onSurface, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: confirmCtrl,
                    onChanged: (_) => setDialogState(() {}),
                    style: const TextStyle(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: orgName,
                      hintStyle: TextStyle(color: Theme.of(ctx).colorScheme.onSurfaceVariant),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Theme.of(ctx).colorScheme.error, width: 1.5),
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
                        style: _outlinedStyle(Theme.of(ctx).colorScheme),
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
                                    Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                                      (_) => false,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(BaseProvider.cleanError(e))),
                                    );
                                  }
                                }
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(ctx).colorScheme.error,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Theme.of(ctx).colorScheme.error.withValues(alpha: 0.4),
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
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(32, 32, 32, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
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
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: _cardDecoration(colorScheme),
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
                        onChanged: (_) => setState(() => _nameError = null),
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                        decoration: _fieldDecoration('Organisation name', colorScheme, errorText: _nameError),
                      )
                    else
                      Text(
                        _profile!.name,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: colorScheme.onSurface),
                      ),
                    if (_profile!.organisationTypeName != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        _profile!.organisationTypeName!,
                        style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                      ),
                    ],
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
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
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
                      style: _outlinedStyle(colorScheme),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: _primaryStyle(colorScheme),
                      child: _isSaving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(color: colorScheme.outline),
          const SizedBox(height: 20),
          if (_isEditing) ...[
            Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 8),
            TextField(
              controller: _descController,
              maxLines: 4,
              maxLength: 2000,
              style: const TextStyle(fontSize: 13),
              decoration: _fieldDecoration('Describe your organisation...', colorScheme),
            ),
            const SizedBox(height: 20),
            Text('Contact', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    onChanged: (_) => setState(() => _emailError = null),
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration('Contact email', colorScheme, errorText: _emailError).copyWith(prefixIcon: Icon(Icons.email_outlined, size: 18, color: colorScheme.onSurfaceVariant)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: _phoneController,
                    onChanged: (_) => setState(() => _phoneError = null),
                    style: const TextStyle(fontSize: 13),
                    decoration: _fieldDecoration('Contact phone', colorScheme, errorText: _phoneError).copyWith(prefixIcon: Icon(Icons.phone_outlined, size: 18, color: colorScheme.onSurfaceVariant)),
                  ),
                ),
              ],
            ),
          ] else ...[
            if (_profile!.description != null && _profile!.description!.isNotEmpty) ...[
              Text('About', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
              const SizedBox(height: 8),
              Text(_profile!.description!, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.6)),
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
    final colorScheme = Theme.of(context).colorScheme;
    const size = 80.0;
    Widget inner;

    if (_isEditing && _localLogoPath != null) {
      inner = Image.file(File(_localLogoPath!), fit: BoxFit.cover, errorBuilder: (_, e, s) => _logoPlaceholder());
    } else if (_profile?.logoUrl != null && _profile!.logoUrl!.isNotEmpty) {
      inner = Image(image: authNetworkImage(_profile!.logoUrl!), fit: BoxFit.cover, errorBuilder: (_, _, _) => _logoPlaceholder());
    } else {
      inner = _logoPlaceholder();
    }

    final circle = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.08),
        border: Border.all(color: colorScheme.outline, width: 1.5),
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
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary,
              ),
              child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder() {
    final colorScheme = Theme.of(context).colorScheme;
    final initials = (_profile?.name ?? 'O').substring(0, 1).toUpperCase();
    return Center(
      child: Text(initials, style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colorScheme.primary)),
    );
  }

  Widget _buildSecurityCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: _cardDecoration(colorScheme),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.08),
          ),
          child: Icon(Icons.lock_outline, size: 20, color: colorScheme.primary),
        ),
        title: Text('Change password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
        subtitle: Text('Update your account password', style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant)),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: colorScheme.onSurfaceVariant),
        onTap: _showChangePasswordDialog,
      ),
    );
  }

  Widget _buildDangerCard() {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.error.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Danger zone', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colorScheme.error)),
          const SizedBox(height: 8),
          Text(
            'Deleting your account will deactivate it immediately. You will lose access to all your campaigns and volunteer jobs.',
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant, height: 1.5),
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _showDeleteDialog,
            style: OutlinedButton.styleFrom(
              foregroundColor: colorScheme.error,
              side: BorderSide(color: colorScheme.error),
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

  BoxDecoration _cardDecoration(ColorScheme colorScheme) => BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2)),
        ],
      );

  InputDecoration _fieldDecoration(String hint, ColorScheme colorScheme, {String? errorText}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 13),
        errorText: errorText,
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
      );

  ButtonStyle _outlinedStyle(ColorScheme colorScheme) => OutlinedButton.styleFrom(
        foregroundColor: colorScheme.onSurface,
        side: BorderSide(color: colorScheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      );

  ButtonStyle _primaryStyle(ColorScheme colorScheme) => ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
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
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.onSurfaceVariant),
          const SizedBox(width: 10),
          Text(value, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
        ],
      ),
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
    final colorScheme = Theme.of(context).colorScheme;
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.error)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.error, width: 1.5)),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20, color: colorScheme.onSurfaceVariant),
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
        _row(context, 'At least 8 characters', password.length >= 8),
        _row(context, 'One uppercase letter', RegExp(r'[A-Z]').hasMatch(password)),
        _row(context, 'One lowercase letter', RegExp(r'[a-z]').hasMatch(password)),
        _row(context, 'One number', RegExp(r'[0-9]').hasMatch(password)),
        _row(context, 'One special character (!@#\$%^&*)', RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(password)),
      ],
    );
  }

  Widget _row(BuildContext context, String label, bool met) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? colorScheme.secondary : colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: met ? colorScheme.secondary : colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
