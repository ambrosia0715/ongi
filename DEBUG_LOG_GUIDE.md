# 디버깅 로그 가이드

## Xcode 로그 보는 방법

### 1. Xcode에서 직접 보기
1. Xcode에서 프로젝트 열기:
   ```bash
   open ios/Runner.xcworkspace
   ```

2. 하단 디버그 영역 열기:
   - 메뉴: `View` → `Debug Area` → `Show Debug Area`
   - 단축키: `Cmd + Shift + Y`

3. 콘솔 탭 선택:
   - 하단 패널에서 콘솔 아이콘 클릭
   - 또는 `All Output` 선택

4. 앱 실행:
   - `Cmd + R` 또는 상단 재생 버튼

5. 로그 필터링:
   - 콘솔 하단 검색창에 다음 키워드 입력:
     - `[_saveEntry]` - 저장 관련 로그
     - `[_generateAiComment]` - AI 코멘트 관련 로그
     - `Error` - 에러만 보기
     - `Exception` - 예외만 보기

### 2. 터미널에서 Flutter 로그 보기

#### iOS 시뮬레이터에서 실행:
```bash
flutter run -d ios
```

#### 특정 로그만 필터링:
```bash
flutter run -d ios 2>&1 | grep -E "\[_saveEntry\]|\[_generateAiComment\]|Error|Exception"
```

#### 모든 로그를 파일로 저장:
```bash
flutter run -d ios 2>&1 | tee flutter_log.txt
```

### 3. 실시간 로그 모니터링

#### 저장 관련 로그만 보기:
```bash
flutter run -d ios 2>&1 | grep "\[_saveEntry\]"
```

#### AI 코멘트 관련 로그만 보기:
```bash
flutter run -d ios 2>&1 | grep "\[_generateAiComment\]"
```

#### 에러와 예외만 보기:
```bash
flutter run -d ios 2>&1 | grep -E "Error|Exception|실패|오류"
```

## 주요 로그 메시지

### 저장 버튼 클릭 시:
- `[_saveEntry] 저장 시작`
- `[_saveEntry] 날짜: 2025-11-12`
- `[_saveEntry] 일기 내용: emotion=warm, goal=..., note=...`
- `[_saveEntry] DiaryRepository 가져옴, 저장 시작...`
- `[_saveEntry] 저장 결과 받음`
- `[_saveEntry] 저장 성공` 또는 `[_saveEntry] 저장 실패: ...`

### AI 코멘트 버튼 클릭 시:
- `[_generateAiComment] AI 코멘트 생성 시작`
- `[_generateAiComment] 사용 상태: count=0, canUseToday=true`
- `[_generateAiComment] 마음 한 줄 내용: ...`
- `[_generateAiComment] AiRepository 가져옴, API 호출 시작...`
- `[_generateAiComment] API 응답 받음`
- `[_generateAiComment] AI 코멘트 생성 성공: ...` 또는 `[_generateAiComment] AI 코멘트 생성 실패: ...`

## 문제 해결

### 저장이 안 될 때:
1. 로그에서 `[_saveEntry] 저장 실패` 메시지 확인
2. 에러 메시지 내용 확인
3. Firebase 연결 상태 확인
4. 로그인 상태 확인

### AI 코멘트가 안 될 때:
1. 로그에서 `[_generateAiComment]` 메시지 확인
2. `마음 한 줄이 비어있음` 메시지 확인
3. `사용 상태` 확인 (제한 초과 여부)
4. API 키 설정 확인 (`.env` 파일)
5. 네트워크 연결 확인



