import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'firebase_options.dart';
import 'app_router.dart';
import 'theme/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // .env 파일 로드 (파일이 없어도 계속 진행)
  try {
    print('📂 .env 파일 로드 시도 중...');
    await dotenv.load(fileName: ".env");
    print('✅ .env 파일 로드 완료');
    
    // 디버깅: API 키가 제대로 로드되었는지 확인
    final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isNotEmpty) {
      print('✅ .env 파일 로드 성공: OPENAI_API_KEY가 설정되었습니다. (길이: ${apiKey.length})');
      print('🔑 API 키 앞 10자리: ${apiKey.substring(0, apiKey.length > 10 ? 10 : apiKey.length)}...');
    } else {
      print('⚠️ .env 파일은 로드되었지만 OPENAI_API_KEY가 비어있습니다.');
      print('📋 dotenv.env.keys: ${dotenv.env.keys.toList()}');
    }
  } catch (e, stackTrace) {
    print('❌ Warning: .env file not found or failed to load. Using default values.');
    print('Error details: $e');
    print('Stack trace: $stackTrace');
  }
  
  // Firebase 초기화 (반드시 완료되어야 함)
  try {
    print('🔥 Firebase 초기화 시작...');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✅ Firebase initialized successfully');
    
    // Firebase 초기화 확인
    final apps = Firebase.apps;
    print('📱 Firebase apps count: ${apps.length}');
    if (apps.isEmpty) {
      throw Exception('Firebase apps list is empty after initialization');
    }
    
    // Firestore 연결 테스트
    try {
      print('🔥 Firestore 연결 테스트 시작...');
      final firestore = FirebaseFirestore.instance;
      print('✅ Firestore 인스턴스 생성 완료');
      print('📊 Firestore 앱 이름: ${firestore.app.name}');
      print('📊 Firestore 프로젝트 ID: ${firestore.app.options.projectId}');
      
      // 간단한 연결 테스트 (타임아웃 5초)
      print('🔍 Firestore 서버 연결 테스트...');
      await firestore.collection('_test').limit(1).get().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⚠️ Firestore 연결 테스트 타임아웃 - API가 활성화되지 않았을 수 있습니다');
          throw TimeoutException('Firestore 연결 테스트 타임아웃');
        },
      );
      print('✅ Firestore 연결 테스트 성공!');
    } catch (e) {
      print('⚠️ Firestore 연결 테스트 실패: $e');
      print('⚠️ Firestore API가 활성화되지 않았거나 Database가 생성되지 않았을 수 있습니다');
      print('⚠️ Firebase Console에서 확인: https://console.firebase.google.com/project/ongi-1e17f/firestore');
      // Firestore 테스트 실패해도 앱은 계속 실행 (사용자가 나중에 활성화할 수 있음)
    }
  } catch (e, stackTrace) {
    print('❌ Error initializing Firebase: $e');
    print('Stack trace: $stackTrace');
    // 웹에서는 Firebase 초기화가 실패하면 앱이 제대로 작동하지 않으므로
    // 에러를 다시 throw하여 앱 시작을 막음
    rethrow;
  }
  
  // AdMob 초기화 (웹에서는 스킵)
  if (!kIsWeb) {
    try {
      await MobileAds.instance.initialize();
      print('AdMob initialized successfully');
    } catch (e) {
      print('Error initializing AdMob: $e');
      // AdMob 초기화 실패해도 앱은 계속 실행
    }
  } else {
    print('AdMob skipped on web platform');
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
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
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

