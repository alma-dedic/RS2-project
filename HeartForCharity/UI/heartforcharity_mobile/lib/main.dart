import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:heartforcharity_mobile/providers/account_provider.dart';
import 'package:heartforcharity_mobile/providers/address_provider.dart';
import 'package:heartforcharity_mobile/providers/auth_provider.dart';
import 'package:heartforcharity_mobile/providers/city_provider.dart';
import 'package:heartforcharity_mobile/providers/country_provider.dart';
import 'package:heartforcharity_mobile/providers/donation_provider.dart';
import 'package:heartforcharity_mobile/providers/review_provider.dart';
import 'package:heartforcharity_mobile/providers/upload_provider.dart';
import 'package:heartforcharity_mobile/providers/user_profile_provider.dart';
import 'package:heartforcharity_mobile/providers/notification_provider.dart';
import 'package:heartforcharity_mobile/providers/volunteer_application_provider.dart';
import 'package:heartforcharity_mobile/screens/login_screen.dart';
import 'package:heartforcharity_mobile/screens/main_shell.dart';
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
        ChangeNotifierProvider(create: (_) => UserProfileProvider()),
        ChangeNotifierProvider(create: (_) => AddressProvider()),
        ChangeNotifierProvider(create: (_) => CountryProvider()),
        ChangeNotifierProvider(create: (_) => CityProvider()),
        ChangeNotifierProvider(create: (_) => VolunteerApplicationProvider()),
        ChangeNotifierProvider(create: (_) => DonationProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
        ChangeNotifierProvider(create: (_) => UploadProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
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
            headlineMedium: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            titleMedium: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
            bodyMedium: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
            bodySmall: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFFD1493F),
            foregroundColor: Colors.white,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1493F),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            hintStyle: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFD1493F), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
          ),
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFFD1493F),
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

    if (hasToken && (type == 'Donor' || type == 'Volunteer')) {
      final refreshed = await AuthProvider.tryRefresh();
      if (!mounted) return;

      if (refreshed) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
        return;
      }
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFF0F2F5),
      body: Center(
        child: CircularProgressIndicator(color: Color(0xFFD1493F)),
      ),
    );
  }
}
