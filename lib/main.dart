import 'package:flutter/material.dart';
import 'features/.authentication/data/auth_service.dart';
import 'features/.authentication/presentation/login_page.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('vi_VN', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Lấy Firebase config từ firebase_options.dart
    final firebaseConfig = DefaultFirebaseOptions.currentPlatform;
    final authService = AuthenticationService(
      apiKey: firebaseConfig.apiKey,
      projectId: firebaseConfig.projectId,
    );

    return MaterialApp(
      locale: const Locale('vi', 'VN'),
      title: 'Quản Lý Chung Cư',
      theme: ThemeData(
        primaryColor: Colors.white,
        scaffoldBackgroundColor: Colors.white, // Màu nền cho các trang
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white, // Màu nền của AppBar
        ),
      ),
      // Trang mở đầu của ứng dụng là trang đăng nhập
      home: LoginPage(authService: authService),
      debugShowCheckedModeBanner: false,
    );
  }
}
