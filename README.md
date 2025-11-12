# 온기 (Ongi) - 따뜻한 일기 앱

Flutter로 개발된 따뜻한 일기 작성 및 AI 코멘트 앱입니다.

## 주요 기능

- 🔐 이메일 로그인/회원가입 (Firebase Auth)
- 📝 일기 작성 (감정, 목표, 할 일, 마음 한 줄)
- 🤖 AI 코멘트 생성 (OpenAI GPT-3.5)
- 📊 일기 히스토리 및 통계
- 🎨 다크 모드 지원
- 📱 AdMob 광고 통합

## 기술 스택

- **Flutter 3.x**
- **Riverpod** - 상태 관리
- **Firebase** - 인증, Firestore, Storage
- **OpenAI API** - AI 코멘트 생성
- **AdMob** - 광고
- **go_router** - 라우팅

## 프로젝트 설정

### 1. 환경 변수 설정

프로젝트 루트에 `.env` 파일을 생성하고 다음 내용을 추가하세요:

```env
OPENAI_API_KEY=your_openai_api_key
ADMOB_APP_ID_ANDROID=ca-app-pub-xxxx~yyyy
ADMOB_BANNER_ID_ANDROID=ca-app-pub-xxxx/zzzz
ADMOB_APP_ID_IOS=ca-app-pub-aaaa~bbbb
ADMOB_BANNER_ID_IOS=ca-app-pub-aaaa/cccc
DAILY_FREE_AI_LIMIT=1
```

### 2. Firebase 설정

1. Firebase Console에서 프로젝트 생성
2. Flutter 프로젝트에 Firebase 추가:
   ```bash
   flutter pub global activate flutterfire_cli
   flutterfire configure
   ```
3. 생성된 `firebase_options.dart` 파일이 `lib/` 디렉토리에 있는지 확인
4. `lib/main.dart`에서 Firebase 초기화 주석 해제:
   ```dart
   await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform,
   );
   ```

### 3. 폰트 설정

#### Android
폰트 파일을 다음 경로에 배치:
- `assets/fonts/pretendard/*.ttf`
- `assets/fonts/noto/*.otf`

#### iOS
1. Xcode에서 `ios/Runner/Info.plist` 열기
2. `UIAppFonts` 배열에 폰트 파일명이 이미 추가되어 있는지 확인
3. 폰트 파일을 Xcode 프로젝트에 추가 (Runner 타겟에 포함)

### 4. AdMob 설정

#### Android
`android/app/src/main/AndroidManifest.xml`에 App ID가 이미 설정되어 있습니다:
```xml
<meta-data
    android:name="com.google.android.gms.ads.APPLICATION_ID"
    android:value="ca-app-pub-1444459980078427~5792855527"/>
```

#### iOS
`ios/Runner/Info.plist`에 App ID가 이미 설정되어 있습니다:
```xml
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-1444459980078427~5792855527</string>
```

## 실행 방법

1. 의존성 설치:
   ```bash
   flutter pub get
   ```

2. Firebase 설정 (아직 안 했다면):
   ```bash
   flutterfire configure
   ```

3. 앱 실행:
   ```bash
   flutter run
   ```

## 프로젝트 구조

```
lib/
├── main.dart                 # 앱 진입점
├── app_router.dart           # 라우팅 설정
├── core/
│   ├── env.dart             # 환경 변수 관리
│   ├── result.dart          # Result 타입
│   └── result_extension.dart # Result 확장 메서드
├── theme/
│   ├── theme.dart           # 테마 설정
│   └── tokens.dart          # 디자인 토큰
├── auth/
│   ├── data/
│   │   └── auth_repository.dart
│   └── ui/
│       ├── sign_in_page.dart
│       └── sign_up_page.dart
├── diary/
│   ├── data/
│   │   ├── diary_repository.dart
│   │   └── diary_providers.dart
│   └── ui/
│       ├── diary_editor_page.dart
│       ├── diary_history_page.dart
│       └── diary_detail_page.dart
├── ai/
│   ├── data/
│   │   └── ai_repository.dart
│   └── prompt_templates.dart
├── dashboard/
│   └── ui/
│       └── dashboard_page.dart
├── settings/
│   └── ui/
│       └── settings_page.dart
└── widgets/
    ├── app_button.dart
    ├── app_card.dart
    ├── app_text_field.dart
    └── ad_banner_widget.dart
```

## 주요 기능 설명

### 인증
- 이메일/비밀번호 로그인 및 회원가입
- 자동 로그인 (Firebase Auth 상태 관리)
- 로그아웃

### 일기 작성
- 감정 선택 (따뜻함, 편안함, 무덤덤, 차분)
- 오늘의 작은 목표 입력
- 할 일 목록 (체크박스)
- 마음 한 줄 적기
- Firestore에 저장

### AI 코멘트
- 일기 저장 후 AI 코멘트 생성 가능
- 무료 사용자: 하루 1회 제한
- Premium 사용자: 제한 없음 (구현 예정)

### 히스토리/통계
- 날짜별 일기 목록
- 감정 필터
- 주간/월간 통계 (간단한 표시)
- 감정 분포 차트

### 설정
- 다크 모드 토글
- 알림 설정 (스텁)
- 데이터 백업/복원 (스텁)
- 광고 표시 설정

## TODO

다음 기능들은 추후 구현 예정입니다:

- [ ] Premium 결제 모듈
- [ ] 알림 기능
- [ ] 데이터 백업/복원
- [ ] 차트 라이브러리 통합 (주간/월간 감정 추이)
- [ ] 이미지 첨부 기능
- [ ] 일기 검색 기능

## 라이선스

© 2025 Ambro (엠브로)

## 문의

문제가 발생하거나 제안사항이 있으시면 이슈를 등록해주세요.

