import 'package:flutter/material.dart';

/// 디자인 토큰 - 색상, 간격, 라운드 등
class OngiTokens {
  OngiTokens._();
  
  // 색상 팔레트
  static const Color bg = Color(0xFFF5F0E8); // 따뜻한 베이지 크림톤 배경 (로고 이미지와 조화)
  static const Color ink = Color(0xFF4C4036); // 브라운 텍스트
  static const Color primary = Color(0xFF8B6F5E);
  static const Color accent = Color(0xFFBFA58F);
  static const Color muted = Color(0xFFD9CFC7);
  static const Color success = Color(0xFF5DAA68);
  static const Color warn = Color(0xFFD98555);
  
  // 다크모드 색상
  static const Color bgDark = Color(0xFF2C2419);
  static const Color inkDark = Color(0xFFE8E0D6);
  static const Color primaryDark = Color(0xFFBFA58F);
  
  // 간격
  static const double spacingCard = 16.0;
  static const double spacingSection = 24.0;
  static const double spacingScreen = 20.0;
  
  // 라운드
  static const double radius = 24.0;
  static const double radiusSmall = 12.0;
  
  // 폰트 패밀리 (Fallback 스택 포함)
  static const String fontFamily = 'Pretendard';
  static const List<String> fontFamilyFallback = [
    'NotoSansKR',
    'Apple SD Gothic Neo',
    'Roboto',
    'Noto Sans',
    'system-ui',
    'sans-serif',
  ];
  
  // 라인 하이트 (폰트 변경 시에도 레이아웃 유지)
  static const double lineHeightTight = 1.2;
  static const double lineHeightNormal = 1.5;
  static const double lineHeightRelaxed = 1.8;
  
  // 터치 영역 최소 크기 (접근성)
  static const double minTouchTarget = 44.0;
}

