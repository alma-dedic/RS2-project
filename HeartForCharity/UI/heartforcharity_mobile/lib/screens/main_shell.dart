import 'package:flutter/material.dart';
import 'package:heartforcharity_mobile/screens/activity_screen.dart';
import 'package:heartforcharity_mobile/screens/explore_screen.dart';
import 'package:heartforcharity_mobile/screens/home_screen.dart';
import 'package:heartforcharity_mobile/screens/notifications_screen.dart';
import 'package:heartforcharity_mobile/screens/profile_screen.dart';

final GlobalKey<HomeScreenState> homeScreenKey = GlobalKey<HomeScreenState>();
final GlobalKey<ExploreScreenState> exploreScreenKey = GlobalKey<ExploreScreenState>();
final GlobalKey<ProfileScreenState> profileScreenKey = GlobalKey<ProfileScreenState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final int index;
  final int currentIndex;
  final void Function(int) onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: isActive ? Colors.white : colorScheme.onSurfaceVariant,
          size: 24,
        ),
      ),
    );
  }
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    HomeScreen(key: homeScreenKey),
    ExploreScreen(key: exploreScreenKey),
    const NotificationsScreen(),
    const ActivityScreen(),
    ProfileScreen(key: profileScreenKey),
  ];

  void _onTabTap(int index) {
    if (index == 0 && _currentIndex != 0) {
      homeScreenKey.currentState?.maybeShowOnboarding();
    }
    if (index == 1 && _currentIndex != 1) {
      exploreScreenKey.currentState?.refreshMode();
    }
    if (index == 4 && _currentIndex != 4) {
      profileScreenKey.currentState?.refreshSkills();
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: colorScheme.surface,
          border: Border(top: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2))),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(icon: Icons.home_outlined, activeIcon: Icons.home, index: 0, currentIndex: _currentIndex, onTap: _onTabTap),
                _NavItem(icon: Icons.search_outlined, activeIcon: Icons.search, index: 1, currentIndex: _currentIndex, onTap: _onTabTap),
                _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, index: 2, currentIndex: _currentIndex, onTap: _onTabTap),
                _NavItem(icon: Icons.volunteer_activism_outlined, activeIcon: Icons.volunteer_activism, index: 3, currentIndex: _currentIndex, onTap: _onTabTap),
                _NavItem(icon: Icons.person_outline, activeIcon: Icons.person, index: 4, currentIndex: _currentIndex, onTap: _onTabTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
