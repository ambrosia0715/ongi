# 웹용 Google Sign-In 설정 가이드

현재 웹에서 Google Sign-In이 작동하지 않는 이유는 **웹용 OAuth 클라이언트 ID**가 없기 때문입니다.

## 문제
- iOS 클라이언트 ID를 웹에서 사용하면 "NATIVE_IOS" 오류 발생
- 웹용 전용 OAuth 클라이언트 ID가 필요함

## 해결 방법

### 1. Google Cloud Console에서 웹용 클라이언트 ID 생성

1. **Google Cloud Console 접속**
   - https://console.cloud.google.com/ 접속
   - 프로젝트 선택: `ongi-1e17f`

2. **API 및 서비스 > 사용자 인증 정보** 이동
   - 좌측 메뉴에서 "API 및 서비스" > "사용자 인증 정보" 클릭

3. **OAuth 2.0 클라이언트 ID 생성**
   - 상단의 "+ 사용자 인증 정보 만들기" 클릭
   - "OAuth 클라이언트 ID" 선택
   - 애플리케이션 유형: **웹 애플리케이션** 선택
   - 이름: "Ongi Web Client" (또는 원하는 이름)
   - 승인된 JavaScript 원본: `http://localhost` 추가 (개발용)
   - 승인된 리디렉션 URI: `http://localhost` 추가 (개발용)
   - "만들기" 클릭

4. **클라이언트 ID 복사**
   - 생성된 클라이언트 ID를 복사 (예: `742257714445-xxxxxxxxxxxxx.apps.googleusercontent.com`)

### 2. 코드에 클라이언트 ID 적용

#### `lib/auth/data/auth_repository.dart` 수정
```dart
_googleSignIn = GoogleSignIn(
  scopes: ['email', 'profile'],
  clientId: kIsWeb 
      ? 'YOUR_WEB_CLIENT_ID.apps.googleusercontent.com'  // 여기에 웹용 클라이언트 ID 입력
      : null,
);
```

#### `web/index.html` 수정
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

### 3. 웹에서 Google Sign-In 버튼 표시

`lib/auth/ui/sign_in_page.dart`와 `lib/auth/ui/sign_up_page.dart`에서:
```dart
// 현재는 웹에서 숨김 처리되어 있음
if (!kIsWeb) ...[
  // Google Sign-In 버튼
]
```

웹용 클라이언트 ID를 설정한 후에는 이 조건을 제거하거나 `if (true)`로 변경하세요.

## 참고
- 프로덕션 환경에서는 실제 도메인을 "승인된 JavaScript 원본"과 "승인된 리디렉션 URI"에 추가해야 합니다.
- 예: `https://yourdomain.com`, `https://yourdomain.com/auth/callback`




