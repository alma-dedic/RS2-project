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
import 'package:heartforcharity_desktop/screens/login_screen.dart';
import 'package:heartforcharity_desktop/screens/main_shell.dart';
import 'package:provider/provider.dart';

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
      ],
      child: MaterialApp(
        title: 'HeartForCharity',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFD1493F),
            primary: const Color(0xFFD1493F),
          ),
          textTheme: GoogleFonts.redHatDisplayTextTheme(),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(0xFFF5F5F5),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD1493F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
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
          inputDecorationTheme: const InputDecorationTheme(
            border: OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD1493F), width: 2),
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
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
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
