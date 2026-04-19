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
    } catch (_) {} finally {
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
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('User Accounts',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
            const SizedBox(height: 20),
            _buildFiltersRow(),
            const SizedBox(height: 16),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltersRow() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchCtrl,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search by username or email...',
              prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF9CA3AF)),
              isDense: true,
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _buildChipFilter(
          label: 'All types',
          options: const {'All': null, 'User': 'User', 'Organisation': 'Organisation', 'Admin': 'Admin'},
          selected: _typeFilter,
          onChanged: (v) { setState(() => _typeFilter = v); _load(); },
        ),
        const SizedBox(width: 8),
        _buildChipFilter(
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: Row(
          children: [
            Text(currentLabel, style: const TextStyle(fontSize: 13, color: Color(0xFF374151))),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down, size: 16, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: Color(0xFFD1493F)));
    final items = _filtered;
    if (items.isEmpty) {
      return const Center(child: Text('No users found.', style: TextStyle(color: Color(0xFF9CA3AF))));
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (context, index) => const Divider(height: 1, color: Color(0xFFF3F4F6)),
              itemBuilder: (_, i) => _buildUserRow(items[i]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF9FAFB),
        borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Username', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
          Expanded(flex: 4, child: Text('Email', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
          Expanded(flex: 2, child: Text('Type', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
          Expanded(flex: 2, child: Text('Joined', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF6B7280)))),
          SizedBox(width: 60),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserResponse user) {
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
                  backgroundColor: const Color(0xFFD1493F).withValues(alpha: 0.12),
                  child: Text(
                    user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFD1493F)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(user.username,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E)),
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(user.email,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
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
              style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: user.isActive ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user.isActive ? 'Active' : 'Inactive',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: user.isActive ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 60,
            child: Switch(
              value: user.isActive,
              activeThumbColor: const Color(0xFF10B981),
              activeTrackColor: const Color(0xFF10B981).withValues(alpha: 0.4),
              onChanged: (_) => _toggleActive(user),
            ),
          ),
        ],
      ),
    );
  }
}
