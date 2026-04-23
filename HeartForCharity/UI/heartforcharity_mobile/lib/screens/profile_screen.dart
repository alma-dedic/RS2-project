import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/model/responses/city.dart';
import 'package:heartforcharity_mobile/model/responses/country.dart';
import 'package:heartforcharity_mobile/providers/account_provider.dart';
import 'package:heartforcharity_mobile/providers/address_provider.dart';
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_mobile/providers/city_provider.dart';
import 'package:heartforcharity_mobile/providers/country_provider.dart';
import 'package:heartforcharity_mobile/providers/upload_provider.dart';
import 'package:heartforcharity_mobile/providers/user_profile_provider.dart';
import 'package:heartforcharity_mobile/screens/login_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  int? _profileId;
  int? _addressId;
  String? _profilePictureUrl;

  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _streetCtrl = TextEditingController();
  final _numberCtrl = TextEditingController();
  final _postalCtrl = TextEditingController();
  DateTime? _dateOfBirth;

  List<Country> _countries = [];
  List<City> _cities = [];
  int? _selectedCountryId;
  int? _selectedCityId;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _numberCtrl.dispose();
    _postalCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() { _loading = true; _error = null; });
    try {
      await Future.wait([_loadProfile(), _loadCountries()]);
    } catch (e) {
      setState(() => _error = 'Failed to load profile.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadProfile() async {
    final profileProvider = context.read<UserProfileProvider>();
    final profile = await profileProvider.getMe();
    if (profile != null) {
      _profileId = profile.userProfileId;
      _addressId = profile.addressId;
      _profilePictureUrl = profile.profilePictureUrl;
      _firstNameCtrl.text = profile.firstName;
      _lastNameCtrl.text = profile.lastName;
      _phoneCtrl.text = profile.phoneNumber ?? '';
      _dateOfBirth = profile.dateOfBirth;
      if (_addressId != null) await _loadAddress(_addressId!);
    }
  }

  Future<void> _loadAddress(int addressId) async {
    final addressProvider = context.read<AddressProvider>();
    final cityProvider = context.read<CityProvider>();
    final address = await addressProvider.getById(addressId);
    _streetCtrl.text = address.streetName ?? '';
    _numberCtrl.text = address.number ?? '';
    _postalCtrl.text = address.postalCode ?? '';
    _selectedCityId = address.cityId;

    final city = await cityProvider.getById(address.cityId);
    _selectedCountryId = city.countryId;
    await _loadCities(_selectedCountryId!);
  }

  Future<void> _loadCountries() async {
    final result = await context.read<CountryProvider>().get(filter: {'pageSize': 200});
    _countries = result.items;
  }

  Future<void> _loadCities(int countryId) async {
    final result = await context.read<CityProvider>().get(
      filter: {'countryId': countryId, 'pageSize': 500},
    );
    setState(() => _cities = result.items);
  }

  Future<void> _pickAndUploadImage() async {
    final uploadProvider = context.read<UploadProvider>();
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    try {
      final url = await uploadProvider.uploadImage(picked.path);
      setState(() => _profilePictureUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image.')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (_profileId == null && _firstNameCtrl.text.trim().isEmpty) {
      setState(() => _error = 'First name is required.');
      return;
    }
    setState(() { _saving = true; _error = null; });

    final addressProvider = context.read<AddressProvider>();
    final profileProvider = context.read<UserProfileProvider>();

    try {
      int? addressId = _addressId;
      if (_selectedCityId != null) {
        final addrBody = {
          'streetName': _streetCtrl.text.trim().isEmpty ? null : _streetCtrl.text.trim(),
          'number': _numberCtrl.text.trim().isEmpty ? null : _numberCtrl.text.trim(),
          'postalCode': _postalCtrl.text.trim().isEmpty ? null : _postalCtrl.text.trim(),
          'cityId': _selectedCityId,
        };
        if (addressId == null) {
          final addr = await addressProvider.insert(addrBody);
          addressId = addr.addressId;
        } else {
          await addressProvider.update(addressId, addrBody);
        }
      }

      final profileBody = {
        'firstName': _firstNameCtrl.text.trim(),
        'lastName': _lastNameCtrl.text.trim(),
        'phoneNumber': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'dateOfBirth': _dateOfBirth?.toIso8601String(),
        'profilePictureUrl': _profilePictureUrl,
        'addressId': addressId,
      };

      if (_profileId == null) {
        final saved = await profileProvider.insert(profileBody);
        setState(() { _profileId = saved.userProfileId; _addressId = addressId; _editing = false; });
      } else {
        await profileProvider.update(_profileId!, profileBody);
        setState(() { _addressId = addressId; _editing = false; });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully.')),
        );
      }
    } catch (e) {
      setState(() => _error = 'Failed to save profile. Please try again.');
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _changePassword() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _ChangePasswordDialog(),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password changed successfully.')),
      );
    }
  }

  Future<void> _deleteAccount() async {
    final accountProvider = context.read<AccountProvider>();
    final authProvider = context.read<AuthProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'This will permanently deactivate your account. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await accountProvider.deleteAccount();
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        title: Text(
          _editing ? 'Edit Profile' : 'Profile',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          if (!_loading && !_editing)
            TextButton(
              onPressed: () => setState(() => _editing = true),
              child: const Text('Edit'),
            ),
          if (_editing) ...[
            TextButton(
              onPressed: _saving ? null : () => setState(() { _editing = false; _loadAll(); }),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _profileId == null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!),
                      const SizedBox(height: 12),
                      FilledButton(onPressed: _loadAll, child: const Text('Retry')),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildAvatar(colorScheme),
                      const SizedBox(height: 24),
                      if (_error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: colorScheme.error.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 13)),
                        ),
                      ],
                      _buildSection('Personal Information', colorScheme, [
                        _buildField('First Name', _firstNameCtrl, colorScheme, editable: _editing),
                        _buildField('Last Name', _lastNameCtrl, colorScheme, editable: _editing),
                        _buildField('Phone Number', _phoneCtrl, colorScheme,
                            editable: _editing, keyboardType: TextInputType.phone),
                        _buildDobField(colorScheme),
                      ]),
                      const SizedBox(height: 16),
                      _buildSection('Address', colorScheme, [
                        _buildCountryDropdown(colorScheme),
                        if (_selectedCountryId != null) _buildCityDropdown(colorScheme),
                        if (_selectedCityId != null) ...[
                          _buildField('Street Name', _streetCtrl, colorScheme, editable: _editing),
                          _buildField('Number', _numberCtrl, colorScheme, editable: _editing),
                          _buildField('Postal Code', _postalCtrl, colorScheme, editable: _editing),
                        ],
                      ]),
                      const SizedBox(height: 24),
                      _buildActionButton('Change Password', Icons.lock_outline, colorScheme.primary, _changePassword),
                      const SizedBox(height: 10),
                      _buildActionButton('Log Out', Icons.logout, colorScheme.onSurfaceVariant, _logout),
                      const SizedBox(height: 10),
                      _buildActionButton('Delete Account', Icons.delete_outline, colorScheme.error, _deleteAccount),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
    );
  }

  Widget _buildAvatar(ColorScheme colorScheme) {
    final initials =
        '${_firstNameCtrl.text.isNotEmpty ? _firstNameCtrl.text[0] : ''}${_lastNameCtrl.text.isNotEmpty ? _lastNameCtrl.text[0] : ''}'
            .toUpperCase();
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        CircleAvatar(
          radius: 52,
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: _profilePictureUrl != null ? NetworkImage(_profilePictureUrl!) : null,
          child: _profilePictureUrl == null
              ? Text(
                  initials.isEmpty ? '?' : initials,
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: colorScheme.primary),
                )
              : null,
        ),
        if (_editing)
          GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
            ),
          ),
      ],
    );
  }

  Widget _buildSection(String title, ColorScheme colorScheme, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: colorScheme.primary)),
          const SizedBox(height: 12),
          Divider(color: colorScheme.outline.withValues(alpha: 0.3), height: 1),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, ColorScheme colorScheme,
      {bool editable = false, TextInputType? keyboardType}) {
    if (!editable) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110,
              child: Text(label, style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(
                ctrl.text.isEmpty ? '—' : ctrl.text,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
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
        ),
      ),
    );
  }

  Widget _buildDobField(ColorScheme colorScheme) {
    final text = _dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!) : '—';
    if (!_editing) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text('Date of Birth', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dateOfBirth ?? DateTime(1990),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) setState(() => _dateOfBirth = picked);
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Date of Birth',
            isDense: true,
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: colorScheme.outline),
            ),
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
          ),
          child: Text(
            _dateOfBirth != null ? DateFormat('dd/MM/yyyy').format(_dateOfBirth!) : 'Select date',
            style: TextStyle(
              fontSize: 14,
              color: _dateOfBirth != null ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCountryDropdown(ColorScheme colorScheme) {
    if (!_editing) {
      final country = _countries.where((c) => c.countryId == _selectedCountryId).firstOrNull;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text('Country', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(
                country?.name ?? '—',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_selectedCountryId),
        initialValue: _selectedCountryId,
        decoration: InputDecoration(
          labelText: 'Country',
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
        ),
        items: _countries
            .map((c) => DropdownMenuItem<int>(
                  value: c.countryId,
                  child: Text(c.name, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (val) async {
          setState(() { _selectedCountryId = val; _selectedCityId = null; _cities = []; });
          if (val != null) await _loadCities(val);
        },
        hint: const Text('Select country'),
      ),
    );
  }

  Widget _buildCityDropdown(ColorScheme colorScheme) {
    if (!_editing) {
      final city = _cities.where((c) => c.cityId == _selectedCityId).firstOrNull;
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text('City', style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant)),
            ),
            Expanded(
              child: Text(
                city?.name ?? '—',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DropdownButtonFormField<int>(
        key: ValueKey(_selectedCityId),
        initialValue: _selectedCityId,
        decoration: InputDecoration(
          labelText: 'City',
          isDense: true,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colorScheme.outline),
          ),
        ),
        items: _cities
            .map((c) => DropdownMenuItem<int>(
                  value: c.cityId,
                  child: Text(c.name, style: const TextStyle(fontSize: 14)),
                ))
            .toList(),
        onChanged: (val) => setState(() => _selectedCityId = val),
        hint: const Text('Select city'),
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18, color: color),
        label: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentCtrl = TextEditingController();
  final _newCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _saving = false;
  String? _error;
  String _newPassword = '';
  final _scrollCtrl = ScrollController();

  bool get _hasLength => _newPassword.length >= 8;
  bool get _hasUpper => RegExp(r'[A-Z]').hasMatch(_newPassword);
  bool get _hasLower => RegExp(r'[a-z]').hasMatch(_newPassword);
  bool get _hasDigit => RegExp(r'[0-9]').hasMatch(_newPassword);
  bool get _hasSpecial => RegExp(r'[!@#$%^&*()\-_=+{}|<>?]').hasMatch(_newPassword);
  bool get _passwordValid => _hasLength && _hasUpper && _hasLower && _hasDigit && _hasSpecial;

  @override
  void initState() {
    super.initState();
    _newCtrl.addListener(() => setState(() => _newPassword = _newCtrl.text));
  }

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _setError(String msg) {
    setState(() => _error = msg);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _submit() async {
    if (_newCtrl.text == _currentCtrl.text) {
      _setError('New password must be different from current password.');
      return;
    }
    if (!_passwordValid) {
      _setError('New password does not meet the requirements.');
      return;
    }
    if (_newCtrl.text != _confirmCtrl.text) {
      _setError('Passwords do not match.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    final accountProvider = context.read<AccountProvider>();
    try {
      await accountProvider.changePassword(_currentCtrl.text, _newCtrl.text);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _setError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        controller: _scrollCtrl,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field('Current password', _currentCtrl, _obscureCurrent,
                () => setState(() => _obscureCurrent = !_obscureCurrent)),
            const SizedBox(height: 12),
            _field('New password', _newCtrl, _obscureNew,
                () => setState(() => _obscureNew = !_obscureNew)),
            if (_newPassword.isNotEmpty) ...[
              const SizedBox(height: 8),
              _checkRow('At least 8 characters', _hasLength, colorScheme),
              _checkRow('One uppercase letter', _hasUpper, colorScheme),
              _checkRow('One lowercase letter', _hasLower, colorScheme),
              _checkRow('One number', _hasDigit, colorScheme),
              _checkRow('One special character (!@#\$%^&*)', _hasSpecial, colorScheme),
            ],
            const SizedBox(height: 12),
            _field('Confirm new password', _confirmCtrl, _obscureConfirm,
                () => setState(() => _obscureConfirm = !_obscureConfirm)),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_error!, style: TextStyle(color: colorScheme.error, fontSize: 13)),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _checkRow(String label, bool met, ColorScheme colorScheme) {
    final color = met ? colorScheme.secondary : colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          Icon(met ? Icons.check_circle : Icons.radio_button_unchecked, size: 14, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return TextField(
      controller: ctrl,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        isDense: true,
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: toggle,
        ),
      ),
    );
  }
}
