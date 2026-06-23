# Flutter Chat App

> Flutter + Firebase로 구현한 실시간 채팅 애플리케이션

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?style=for-the-badge&logo=firebase&logoColor=black)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)

---

## 주요 기능

### 인증
- 이메일/비밀번호 회원가입 & 로그인
- 자동 로그인 상태 유지 (Firebase Auth 세션)
- 비밀번호 재설정 이메일 발송

### 채팅
- **1:1 실시간 채팅** — Firestore `onSnapshot` 기반 실시간 동기화
- **그룹 채팅** — 다수 참여자, 발신자 이름 표시, 채팅방 나가기
- **이미지 전송** — 갤러리 선택 → Firebase Storage 업로드 → 채팅에 표시
- **메시지 삭제** — 본인 메시지 길게 눌러 삭제
- **읽음 표시** — 아직 읽지 않은 참여자 수 실시간 표시
- **타이핑 인디케이터** — "입력 중..." 실시간 표시

### 소셜
- 이메일 / 닉네임 **prefix 검색**으로 유저 탐색
- 온라인 / 오프라인 **실시간 접속 상태** 표시
- 채팅방 목록에서 마지막 메시지 & 시간 표시

### 프로필 & UX
- 프로필 사진 업로드 (Firebase Storage)
- 닉네임 설정 / 수정
- **다크 모드** 지원 (전역 테마 토글)
- Android / iOS / Web 크로스플랫폼

---

## 기술 스택

```
Firestore StreamBuilder
  └─ chats/{chatId}/messages → 메시지 실시간 수신
  └─ chats/{chatId}/typing/{uid} → 타이핑 상태 실시간 감지
  └─ users/{uid}.isOnline → 접속 상태 실시간 감지
```

### Firestore 데이터 모델
```
users/{uid}
  ├── email, uid, nickname
  ├── profileImageUrl
  ├── isOnline, lastSeen
  └── createdAt

chats/{chatId}
  ├── users: [uid, ...]
  ├── userEmails: [email, ...]
  ├── isGroup, groupName
  ├── lastMessage, lastMessageTime
  └── messages/{messageId}
        ├── text, imageUrl
        ├── type: "text" | "image"
        ├── senderId, senderEmail
        ├── readBy: [uid, ...]
        └── timestamp
```

### 구현 포인트
- **읽음 처리** — `readBy` 배열에 UID 추가, 멤버 수와 비교해 미확인 수 계산
- **타이핑 감지** — `Timer(1s)` 디바운싱으로 Firestore 쓰기 최적화
- **이미지 전송** — 웹(`readAsBytes`) / 네이티브(`File`) 환경 분기 처리
- **유저 검색** — Firestore 범위 쿼리(``)로 prefix 검색 구현, 결과 중복 제거

---

## 프로젝트 구조

```
lib/
├── main.dart                    # 앱 진입점, Firebase 초기화, 전역 테마 관리
├── firebase_options.dart        # FlutterFire CLI 자동 생성
└── screens/
    ├── login_screen.dart        # 로그인 / 회원가입 / 비밀번호 재설정
    ├── home_screen.dart         # 채팅방 목록
    ├── chat_screen.dart         # 채팅 화면 (1:1 + 그룹, 텍스트 + 이미지)
    ├── search_screen.dart       # 유저 검색
    ├── create_group_screen.dart # 그룹 채팅방 생성
    └── profile_screen.dart      # 프로필 편집 + 다크모드
```

---

## 실행 방법

```bash
git clone <repo-url>
cd flutter_learning
flutter pub get
flutter run
```

> Firebase 연동을 위해 `firebase_options.dart` 및 `google-services.json` / `GoogleService-Info.plist` 파일이 필요합니다.

---

## 개발 이력

| 커밋 | 기능 |
|------|------|
| `7334b16` | Firebase 연동 및 이메일 로그인/회원가입 |
| `3e0ed27` | 실시간 1:1 채팅 |
| `771c3df` | 프로필 (닉네임, 사진) |
| `56eb12b` | 채팅 이미지 전송 |
| `44ed2ae` | 그룹 채팅 |
| `eaa6d60` | 읽음 표시 |
| `df05b42` | 닉네임/이메일 prefix 검색 |
| `404a078` | 메시지 삭제 & 그룹 나가기 |
| `c2f76ff` | 온라인/오프라인 상태 |
| `d532a3e` | 다크 모드 & 비밀번호 찾기 |
| `3212ca0` | 타이핑 중 표시 |
