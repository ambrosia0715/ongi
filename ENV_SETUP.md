# .env 파일 설정 가이드

## 문제
```
Error: DotEnv.env
OPENAI_API_KEY를 읽을 수 없습니다.
```

## 해결 방법

### 1. 프로젝트 루트에 `.env` 파일 생성

프로젝트 루트 디렉토리 (`/Users/ambrosia0715/Desktop/project/Ongi/`)에 `.env` 파일을 생성하세요.

### 2. `.env` 파일 내용

다음 내용을 `.env` 파일에 추가하세요:

```env
# OpenAI API 키 (필수)
# https://platform.openai.com/api-keys 에서 발급받으세요
OPENAI_API_KEY=sk-your-actual-api-key-here

# AdMob Android App ID (선택)
ADMOB_APP_ID_ANDROID=

# AdMob Android Banner ID (선택)
ADMOB_BANNER_ID_ANDROID=

# AdMob iOS App ID (선택)
ADMOB_APP_ID_IOS=

# AdMob iOS Banner ID (선택)
ADMOB_BANNER_ID_IOS=

# 무료 사용자 일일 AI 제한 (기본값: 1)
DAILY_FREE_AI_LIMIT=1
```

### 3. OpenAI API 키 발급 방법

1. **OpenAI Platform 접속:**
   - https://platform.openai.com/ 접속
   - 로그인 또는 회원가입

2. **API 키 생성:**
   - https://platform.openai.com/api-keys 접속
   - `Create new secret key` 클릭
   - 키 이름 입력 (예: "Ongi App")
   - 생성된 키 복사 (한 번만 표시됨!)

3. **`.env` 파일에 추가:**
   ```env
   OPENAI_API_KEY=sk-복사한-키-여기에-붙여넣기
   ```

### 4. 파일 위치 확인

`.env` 파일은 반드시 프로젝트 루트에 있어야 합니다:
```
/Users/ambrosia0715/Desktop/project/Ongi/.env
```

### 5. 앱 재시작

`.env` 파일을 생성/수정한 후:
1. 앱을 완전히 종료
2. 터미널에서 실행 중인 Flutter 프로세스 종료 (`Ctrl + C`)
3. 앱을 다시 실행:
   ```bash
   flutter run -d ios
   ```

## 주의사항

### ⚠️ 보안
- `.env` 파일은 **절대 Git에 커밋하지 마세요!**
- `.gitignore`에 `.env`가 포함되어 있는지 확인하세요
- API 키는 비밀로 유지하세요

### ✅ 확인 방법

앱 실행 후 로그에서 다음 메시지가 보이면 정상입니다:
```
Firebase initialized successfully
```

다음 메시지가 보이면 `.env` 파일이 없는 것입니다:
```
Warning: .env file not found. Using default values.
```

## 문제 해결

### 여전히 오류가 발생하는 경우:

1. **파일 위치 확인:**
   ```bash
   ls -la /Users/ambrosia0715/Desktop/project/Ongi/.env
   ```

2. **파일 내용 확인:**
   ```bash
   cat /Users/ambrosia0715/Desktop/project/Ongi/.env
   ```

3. **키 형식 확인:**
   - OpenAI API 키는 `sk-`로 시작해야 합니다
   - 공백이나 따옴표 없이 직접 입력하세요

4. **캐시 클리어:**
   ```bash
   flutter clean
   flutter pub get
   ```

5. **앱 완전 재시작:**
   - Xcode에서 완전히 종료
   - 터미널에서도 종료
   - 다시 실행



