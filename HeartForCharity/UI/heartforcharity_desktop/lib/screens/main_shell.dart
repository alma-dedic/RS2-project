import 'package:flutter/material.dart';
import 'package:heartforcharity_desktop/model/responses/organisation_profile.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_profile_provider.dart';
import 'package:heartforcharity_desktop/screens/campaigns_screen.dart';
import 'package:heartforcharity_desktop/screens/dashboard_screen.dart';
import 'package:heartforcharity_desktop/screens/login_screen.dart';
import 'package:heartforcharity_desktop/screens/profile_screen.dart';
import 'package:heartforcharity_desktop/screens/volunteer_jobs_screen.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  OrganisationProfile? _orgProfile;

  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Dashboard'),
    _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism, label: 'Campaigns'),
    _NavItem(icon: Icons.monitor_heart_outlined, activeIcon: Icons.monitor_heart, label: 'Volunteer jobs'),
    _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, label: 'Profile'),
  ];

  @override
  void initState() {
    super.initState();
    _loadOrgProfile();
  }

  Future<void> _loadOrgProfile() async {
    try {
      final profile = await context.read<OrganisationProfileProvider>().getMe();
      if (mounted) setState(() => _orgProfile = profile);
    } catch (_) {}
  }

  void _onNavItemSelected(int index) {
    if (_selectedIndex == index) {
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(
            navItems: _navItems,
            selectedIndex: _selectedIndex,
            orgProfile: _orgProfile,
            onItemSelected: _onNavItemSelected,
            onLogout: _logout,
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildNavigator(0, const DashboardScreen()),
                _buildNavigator(1, const CampaignsScreen()),
                _buildNavigator(2, const VolunteerJobsScreen()),
                _buildNavigator(3, ProfileScreen(onProfileUpdated: _loadOrgProfile)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigator(int index, Widget root) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (_) => MaterialPageRoute(builder: (_) => root),
    );
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final OrganisationProfile? orgProfile;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.orgProfile,
    required this.onItemSelected,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      color: const Color(0xFFD1493F),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 28),
            child: Column(
              children: [
                // Avatar
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                  child: ClipOval(
                    child: orgProfile?.logoUrl != null && orgProfile!.logoUrl!.isNotEmpty
                        ? Image.network(
                            orgProfile!.logoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => _buildInitials(),
                          )
                        : _buildInitials(),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  orgProfile?.name ?? 'Organisation',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
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

  Widget _buildInitials() {
    final initials = (orgProfile?.name ?? 'O').substring(0, 1).toUpperCase();
    return Center(
      child: Text(
        initials,
        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700, color: Colors.white),
      ),
    );
  }
}

class _NavTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(50),
            border: isSelected
                ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5)
                : null,
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white,
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
