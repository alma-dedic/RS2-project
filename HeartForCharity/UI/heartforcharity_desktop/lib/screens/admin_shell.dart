import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/screens/login_screen.dart';
import 'package:heartforcharity_desktop/screens/reference_data_screen.dart';
import 'package:heartforcharity_desktop/screens/users_screen.dart';
import 'package:provider/provider.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.dataset_outlined, activeIcon: Icons.dataset, label: 'Reference Data'),
    _NavItem(icon: Icons.manage_accounts_outlined, activeIcon: Icons.manage_accounts, label: 'User Accounts'),
  ];

  void _onNavItemSelected(int index) => setState(() => _selectedIndex = index);

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _AdminSidebar(
            navItems: _navItems,
            selectedIndex: _selectedIndex,
            onItemSelected: _onNavItemSelected,
            onLogout: _logout,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: const [
                ReferenceDataScreen(),
                UsersScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem({required this.icon, required this.activeIcon, required this.label});
}

class _AdminSidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const _AdminSidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFF1A1A2E),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
            child: Column(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                  child: const Icon(Icons.admin_panel_settings, size: 32, color: Colors.white),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Admin Panel',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Administrator',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: navItems.length,
              itemBuilder: (context, index) {
                final item = navItems[index];
                final isSelected = selectedIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _NavTile(
                    icon: isSelected ? item.activeIcon : item.icon,
                    label: item.label,
                    isSelected: isSelected,
                    onTap: () => onItemSelected(index),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: _NavTile(
              icon: Icons.logout,
              label: 'Logout',
              isSelected: false,
              onTap: onLogout,
            ),
          ),
        ],
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({required this.icon, required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(50),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.white24,
        highlightColor: Colors.white12,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: isSelected ? Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5) : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: isSelected ? Colors.white : Colors.white60),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white60,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
