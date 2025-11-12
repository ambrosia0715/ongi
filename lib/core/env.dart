import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 환경 변수 관리 클래스
class Env {
  /// OpenAI API 키
  /// .env 파일에서 OPENAI_API_KEY를 설정하세요
  static String get openAiApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  
  /// AdMob Android App ID
  /// .env 파일에서 ADMOB_APP_ID_ANDROID를 설정하세요
  static String get admobAppIdAndroid => 
      dotenv.env['ADMOB_APP_ID_ANDROID'] ?? '';
  
  /// AdMob Android Banner ID
  /// .env 파일에서 ADMOB_BANNER_ID_ANDROID를 설정하세요
  static String get admobBannerIdAndroid => 
      dotenv.env['ADMOB_BANNER_ID_ANDROID'] ?? '';
  
  /// AdMob iOS App ID
  /// .env 파일에서 ADMOB_APP_ID_IOS를 설정하세요
  static String get admobAppIdIos => 
      dotenv.env['ADMOB_APP_ID_IOS'] ?? '';
  
  /// AdMob iOS Banner ID
  /// .env 파일에서 ADMOB_BANNER_ID_IOS를 설정하세요
  static String get admobBannerIdIos => 
      dotenv.env['ADMOB_BANNER_ID_IOS'] ?? '';
  
  /// 무료 사용자 일일 AI 제한
  static int get dailyFreeAiLimit => 
      int.tryParse(dotenv.env['DAILY_FREE_AI_LIMIT'] ?? '1') ?? 1;
}

