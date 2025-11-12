import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드 (파일이 없어도 계속 진행)
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print('Warning: .env file not found. Using default values.');
  }
  
  // Firebase 초기화
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    print('Error initializing Firebase: $e');
    // Firebase 초기화 실패해도 앱은 계속 실행
  }
  
  // AdMob 초기화
  try {
    await MobileAds.instance.initialize();
  } catch (e) {
    print('Error initializing AdMob: $e');
    // AdMob 초기화 실패해도 앱은 계속 실행
  }
  
  // 앱 실행
  runApp(
    const ProviderScope(
      child: OngiApp(),
    ),
  );
}

class OngiApp extends ConsumerWidget {
  const OngiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('OngiApp build called');
    try {
      final themeMode = ref.watch(themeModeProvider);
      
      return MaterialApp.router(
        title: '온기',
        debugShowCheckedModeBanner: false,
        theme: OngiTheme.lightTheme,
        darkTheme: OngiTheme.darkTheme,
        themeMode: themeMode,
        routerConfig: AppRouter.router,
        // 에러 위젯 표시
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
            child: child ?? const Scaffold(
              body: Center(
                child: Text('로딩 중...'),
              ),
            ),
          );
        },
      );
    } catch (e, stackTrace) {
      print('Error in OngiApp build: $e');
      print('Stack trace: $stackTrace');
      // 에러 발생 시 간단한 화면 표시
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('앱 초기화 오류: $e'),
              ],
            ),
          ),
        ),
      );
    }
  }
}

