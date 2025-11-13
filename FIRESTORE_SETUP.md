# Firestore API 활성화 가이드

## 오류 메시지
```
Permission denied: Cloud Firestore API has not been used in project ongi-1e17f before or it is disabled.
```

## 해결 방법

### 방법 1: Google Cloud Console에서 직접 활성화 (권장)

1. **링크로 바로 이동:**
   ```
   https://console.developers.google.com/apis/api/firestore.googleapis.com/overview?project=ongi-1e17f
   ```

2. **또는 수동으로:**
   - https://console.cloud.google.com/ 접속
   - 프로젝트 선택: `ongi-1e17f`
   - 왼쪽 메뉴에서 `API 및 서비스` → `라이브러리` 클릭
   - 검색창에 `Cloud Firestore API` 입력
   - `Cloud Firestore API` 클릭
   - `사용 설정` 버튼 클릭

3. **활성화 확인:**
   - 몇 분 정도 기다린 후 앱을 다시 실행
   - API가 활성화되면 Firestore 사용 가능

### 방법 2: Firebase Console에서 활성화

1. **Firebase Console 접속:**
   - https://console.firebase.google.com/ 접속
   - 프로젝트 `ongi-1e17f` 선택

2. **Firestore Database 생성:**
   - 왼쪽 메뉴에서 `Firestore Database` 클릭
   - `데이터베이스 만들기` 버튼 클릭
   - 프로덕션 모드 또는 테스트 모드 선택
   - 위치 선택 (가장 가까운 지역 선택, 예: `asia-northeast3 (Seoul)`)
   - `사용 설정` 클릭

3. **보안 규칙 설정 (테스트 모드):**
   ```
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /{document=**} {
         allow read, write: if request.auth != null;
       }
     }
   }
   ```

4. **활성화 확인:**
   - Firestore가 생성되면 자동으로 API가 활성화됨
   - 몇 분 정도 기다린 후 앱을 다시 실행

## 확인 방법

### 1. Google Cloud Console에서 확인:
- https://console.cloud.google.com/apis/library/firestore.googleapis.com?project=ongi-1e17f
- "사용 설정됨" 상태인지 확인

### 2. Firebase Console에서 확인:
- https://console.firebase.google.com/project/ongi-1e17f/firestore
- Firestore Database가 생성되어 있는지 확인

## 주의사항

1. **API 활성화 후 대기 시간:**
   - API를 활성화한 후 몇 분(보통 1-5분) 정도 기다려야 함
   - 즉시 적용되지 않을 수 있음

2. **Firestore 보안 규칙:**
   - 프로덕션 환경에서는 적절한 보안 규칙 설정 필요
   - 테스트 중에는 인증된 사용자만 읽기/쓰기 가능하도록 설정

3. **비용:**
   - Firestore는 무료 할당량이 있지만, 사용량에 따라 비용 발생 가능
   - Firebase Console에서 사용량 모니터링 권장

## 문제 해결

### 여전히 오류가 발생하는 경우:

1. **프로젝트 ID 확인:**
   - `lib/firebase_options.dart` 파일에서 프로젝트 ID 확인
   - `ongi-1e17f`가 맞는지 확인

2. **Firebase 초기화 확인:**
   - `lib/main.dart`에서 Firebase 초기화가 제대로 되는지 확인

3. **인증 상태 확인:**
   - 사용자가 로그인되어 있는지 확인
   - Firestore 보안 규칙이 인증을 요구하는 경우

4. **캐시 클리어:**
   ```bash
   flutter clean
   flutter pub get
   ```

5. **앱 재시작:**
   - 완전히 종료 후 다시 실행



