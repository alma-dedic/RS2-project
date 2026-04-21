import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heartforcharity_desktop/providers/auth_provider.dart';
import 'package:heartforcharity_desktop/providers/campaign_provider.dart';
import 'package:heartforcharity_desktop/providers/category_provider.dart';
import 'package:heartforcharity_desktop/providers/volunteer_job_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_profile_provider.dart';
import 'package:heartforcharity_desktop/providers/donation_provider.dart';
import 'package:heartforcharity_desktop/providers/volunteer_application_provider.dart';
import 'package:heartforcharity_desktop/providers/review_provider.dart';
import 'package:heartforcharity_desktop/providers/campaign_media_provider.dart';
import 'package:heartforcharity_desktop/providers/upload_provider.dart';
import 'package:heartforcharity_desktop/providers/city_provider.dart';
import 'package:heartforcharity_desktop/providers/country_provider.dart';
import 'package:heartforcharity_desktop/providers/dashboard_provider.dart';
import 'package:heartforcharity_desktop/providers/organisation_type_provider.dart';
import 'package:heartforcharity_desktop/providers/report_provider.dart';
import 'package:heartforcharity_desktop/providers/skill_provider.dart';
import 'package:heartforcharity_desktop/providers/user_admin_provider.dart';
import 'package:heartforcharity_desktop/screens/admin_shell.dart';
import 'package:heartforcharity_desktop/screens/login_screen.dart';
import 'package:heartforcharity_desktop/screens/main_shell.dart';
import 'package:provider/provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CampaignProvider()),
        ChangeNotifierProvider(create: (_) => CategoryProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerJobProvider()),
        ChangeNotifierProvider(create: (_) => OrganisationProfileProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerApplicationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => CampaignMediaProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        Provider(create: (_) => DashboardProvider()),
        Provider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => SkillProvider()),
        ChangeNotifierProvider(create: (_) => OrganisationTypeProvider()),
        ChangeNotifierProvider(create: (_) => CountryProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => UserAdminProvider()),
      ],
      child: MaterialApp(
        title: 'HeartForCharity',
        debugShowCheckedModeBanner: false,
        navigatorKey: navigatorKey,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: Color(0xFFD1493F),
            onPrimary: Colors.white,
            secondary: Color(0xFF10B981),
            onSecondary: Colors.white,
            error: Color(0xFFEF4444),
            onError: Colors.white,
            surface: Colors.white,
            onSurface: Color(0xFF1A1A2E),
            onSurfaceVariant: Color(0xFF6B7280),
            outline: Color(0xFFE5E7EB),
            outlineVariant: Color(0xFFD1D5DB),
            surfaceContainerLow: Color(0xFFF9FAFB),
            surfaceContainerHighest: Color(0xFFF0F2F5),
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F2F5),
          textTheme: GoogleFonts.redHatDisplayTextTheme().copyWith(
            // Screen titles: "Dashboard", "Campaigns", etc.
            headlineMedium: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            // Card/section titles
            titleMedium: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            // Dialog titles, row headings
            titleSmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            // Field labels
            labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF374151)),
            // Secondary/muted body text
            bodyMedium: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            // Timestamps, meta info
            bodySmall: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          cardTheme: CardThemeData(
            color: Colors.white,
            elevation: 0,
            shadowColor: Colors.black.withValues(alpha: 0.04),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            margin: EdgeInsets.zero,
          ),
          dialogTheme: DialogThemeData(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            titleTextStyle: const TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E),
              fontFamily: 'RedHatDisplay',
            ),
          ),
          dividerTheme: const DividerThemeData(
            color: Color(0xFFE5E7EB),
            thickness: 1,
            space: 1,
          ),
          tabBarTheme: const TabBarThemeData(
            labelColor: Color(0xFFD1493F),
            unselectedLabelColor: Color(0xFF6B7280),
            indicatorColor: Color(0xFFD1493F),
            labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            unselectedLabelStyle: TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
            dividerColor: Color(0xFFE5E7EB),
          ),
          chipTheme: ChipThemeData(
            backgroundColor: const Color(0xFFF9FAFB),
            selectedColor: const Color(0xFFD1493F),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            side: const BorderSide(color: Color(0xFFE5E7EB)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          popupMenuTheme: PopupMenuThemeData(
            color: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 4,
            textStyle: const TextStyle(fontSize: 13, color: Color(0xFF374151)),
          ),
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected) ? const Color(0xFF10B981) : Colors.white),
            trackColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.selected)
                    ? const Color(0xFF10B981).withValues(alpha: 0.4)
                    : const Color(0xFFE5E7EB)),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFD1493F),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
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
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1493F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ).copyWith(
              mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF374151),
              side: const BorderSide(color: Color(0xFFD1D5DB)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ).copyWith(
              mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: ButtonStyle(
              mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
            ),
          ),
          iconButtonTheme: IconButtonThemeData(
            style: ButtonStyle(
              mouseCursor: WidgetStateProperty.all(SystemMouseCursors.click),
            ),
          ),
        ),
        home: const AppStartup(),
      ),
    );
  }
}

class AppStartup extends StatefulWidget {
  const AppStartup({super.key});

  @override
  State<AppStartup> createState() => _AppStartupState();
}

class _AppStartupState extends State<AppStartup> {
  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.initializeFromStorage();

    if (!mounted) return;

    final type = AuthProvider.userType;
    final hasToken = AuthProvider.token != null;

    if (hasToken && (type == 'Organisation' || type == 'Admin')) {
      // Try refreshing token to ensure it's still valid
      final refreshed = await AuthProvider.tryRefresh();
      if (!mounted) return;

      if (refreshed) {
        final shell = type == 'Admin' ? const AdminShell() : const MainShell();
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => shell),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFFD1493F),
        ),
      ),
    );
  }
}
