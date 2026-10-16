import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'providers/attendance_provider.dart';
import 'screens/home_shell.dart';
import 'services/local_storage_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline Hive storage service
  final storageService = LocalStorageService();
  await storageService.init();

  // Initialize attendance state provider
  final attendanceProvider = AttendanceProvider(storageService);
  await attendanceProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: attendanceProvider,
      child: const WardiatyApp(),
    ),
  );
}

class WardiatyApp extends StatelessWidget {
  const WardiatyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ورديتي - دفتر الحضور واليومية',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      // Full RTL Arabic localization
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const HomeShell(),
    );
  }
}
