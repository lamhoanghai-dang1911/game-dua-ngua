import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/login_screen.dart';
import 'services/audio_service.dart';

/// ============================================================================
/// MINI RACING GAME – FLUTTER UI PROJECT (GAME ĐUA NGỰA)
/// Áp dụng toàn diện kiến thức từ MODULE 1 đến MODULE 4:
/// - Module 1: Widget Tree, Flutter Engine, runApp(), hot-reload architecture.
/// - Module 2: Dart Essentials (Type inference, Final/Const, Null Safety, Collections).
/// - Module 3: Dart OOP (Classes, Named Constructors, Immutability, Separation of Concerns).
/// - Module 4: Flutter UI Layout (Column, Row, Stack), StatefulWidget & setState,
///             Navigation (Navigator.push/pop), "Slider giả" (AnimatedPositioned + Container).
/// ============================================================================

void main() async {
  // Đảm bảo Flutter framework đã sẵn sàng trước khi nạp tài nguyên
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo audio service
  await AudioService.instance.init();

  // Mặc định Home/Result dùng màn hình dọc. RaceScreen sẽ tạm chuyển sang landscape.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Cấu hình thanh trạng thái hệ thống trong suốt hòa vào nền game
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F172A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const MiniRacingGameApp());
}

class MiniRacingGameApp extends StatelessWidget {
  const MiniRacingGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Đấu Trường Đua Ngựa - Mini Racing',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B132B),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF16A34A), // Emerald Green
          secondary: Color(0xFFFBBF24), // Gold Amber
          surface: Color(0xFF1E293B), // Slate Card
          error: Color(0xFFEF4444),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F172A),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1E293B),
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const LoginScreen(),
    );
  }
}
