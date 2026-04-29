import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/user_response.dart';
import 'package:heartforcharity_desktop/providers/user_admin_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<UserResponse> _users = [];
  bool _loading = true;
  String? _typeFilter;
  bool? _activeFilter;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final filter = <String, dynamic>{'pageSize': 200};
      if (_typeFilter != null) filter['userType'] = _typeFilter!;
      if (_activeFilter != null) filter['isActive'] = _activeFilter!;
      final result = await context.read<UserAdminProvider>().get(filter: filter);
      if (mounted) setState(() => _users = result.items);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<UserResponse> get _filtered {
    final q = _searchCtrl.text.toLowerCase();
    if (q.isEmpty) return _users;
    return _users.where((u) => u.username.toLowerCase().contains(q) || u.email.toLowerCase().contains(q)).toList();
  }

  Future<void> _toggleActive(UserResponse user) async {
    try {
      await context.read<UserAdminProvider>().toggleActive(user.userId, user);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(user.isActive ? 'User deactivated successfully.' : 'User activated successfully.')),
        );
      }
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('User Accounts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: colorScheme.onSurface)),
            const SizedBox(height: 20),
            _buildFiltersRow(colorScheme),
            const SizedBox(height: 16),
            Expanded(child: _buildTable(colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow(ColorScheme colorScheme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by username or email...',
              prefixIcon: Icon(Icons.search, size: 18, color: colorScheme.onSurfaceVariant),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: colorScheme.outline)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildChipFilter(
          colorScheme: colorScheme,
          label: 'All types',
          options: const {'All': null, 'User': 'User', 'Organisation': 'Organisation', 'Admin': 'Admin'},
          selected: _typeFilter,
          onChanged: (v) { setState(() => _typeFilter = v); _load(); },
        ),
        const SizedBox(width: 8),
        _buildChipFilter(
          colorScheme: colorScheme,
          label: 'All status',
          options: const {'All': null, 'Active': 'true', 'Inactive': 'false'},
          selected: _activeFilter == null ? null : _activeFilter! ? 'true' : 'false',
          onChanged: (v) {
            setState(() => _activeFilter = v == null ? null : v == 'true');
            _load();
          },
        ),
      ],
    );
  }

  Widget _buildChipFilter({
    required ColorScheme colorScheme,
    required String label,
    required Map<String, String?> options,
    required String? selected,
    required ValueChanged<String?> onChanged,
  }) {
    const allSentinel = '__all__';
    final entries = options.entries.toList();
    final currentLabel = entries.firstWhere(
      (e) => e.value == selected,
      orElse: () => MapEntry(label, null),
    ).key;

    return PopupMenuButton<String>(
      initialValue: selected ?? allSentinel,
      onSelected: (v) => onChanged(v == allSentinel ? null : v),
      itemBuilder: (_) => entries
          .map((e) => PopupMenuItem(
                value: e.value ?? allSentinel,
                child: Text(e.key),
              ))
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: colorScheme.outline),
        ),
        child: Row(
          children: [
            Text(currentLabel, style: TextStyle(fontSize: 13, color: colorScheme.onSurface)),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, size: 16, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(ColorScheme colorScheme) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final items = _filtered;
    if (items.isEmpty) {
      return Center(child: Text('No users found.', style: TextStyle(color: colorScheme.onSurfaceVariant)));
    }

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTableHeader(colorScheme),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => Divider(height: 1, color: colorScheme.outlineVariant),
              itemBuilder: (_, i) => _buildUserRow(items[i], colorScheme),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          Expanded(flex: 4, child: Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          Expanded(flex: 2, child: Text('Joined', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant))),
          const SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserResponse user, ColorScheme colorScheme) {
    final typeColor = switch (user.userType) {
      'Admin' => const Color(0xFF7C3AED),
      'Organisation' => const Color(0xFF3B82F6),
      _ => const Color(0xFF6B7280),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.12),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colorScheme.primary),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(user.username,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(user.email,
                style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(user.userType,
                  style: TextStyle(fontSize: 11, color: typeColor, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              DateFormat('dd MMM yyyy').format(user.createdAt.toLocal()),
              style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? colorScheme.secondary.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: user.isActive ? colorScheme.secondary : colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Switch(
              value: user.isActive,
              onChanged: (_) => _toggleActive(user),
            ),
          ),
        ],
      ),
    );
  }
}
