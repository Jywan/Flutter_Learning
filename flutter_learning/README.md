# Flutter Chat App

Flutter + Firebase 기반의 실시간 채팅 애플리케이션입니다.

## 프로젝트 목적

Flutter 학습 및 포트폴리오용 프로젝트로, 모바일/웹 크로스플랫폼 채팅 앱을 구현합니다.

## 기술 스택

| 구분 | 기술 |
|------|------|
| Frontend | Flutter (Dart) |
| 인증 | Firebase Authentication |
| 데이터베이스 | Cloud Firestore |
| 스토리지 | Firebase Storage |
| 플랫폼 | Android, iOS, Web |

## 기능 스펙

### 완료

- [x] Firebase 프로젝트 연동
- [x] 이메일 회원가입
- [x] 이메일 로그인
- [x] 로그아웃

### 예정

- [ ] 채팅방 목록
- [ ] 1:1 실시간 채팅
- [ ] 유저 검색
- [ ] 프로필 (닉네임, 프로필 사진)
- [ ] 그룹 채팅
- [ ] 이미지/파일 전송
- [ ] 푸시 알림
- [ ] 읽음 표시

## 프로젝트 구조

```
lib/
├── main.dart              # 앱 진입점, Firebase 초기화
├── firebase_options.dart  # Firebase 설정 (자동 생성)
└── screens/
    └── login_screen.dart  # 로그인/회원가입 화면
```

## 실행 방법

```bash
cd flutter_learning
flutter pub get
flutter run
```

## 요구사항

- Flutter SDK
- Firebase CLI
- FlutterFire CLI
