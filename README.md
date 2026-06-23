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
- [x] 로그인 상태 유지 (새로고침 시 자동 로그인)
- [x] 채팅방 목록 (실시간)
- [x] 1:1 실시간 채팅
- [x] 그룹 채팅 (다수 참여자)
- [x] 유저 검색 (이메일/닉네임 prefix 검색)
- [x] 채팅방 자동 생성
- [x] 프로필 사진 업로드 (Firebase Storage)
- [x] 닉네임 설정/수정
- [x] 채팅에 닉네임/프로필 사진 표시
- [x] 그룹 채팅에서 발신자 이름 표시
- [x] 메시지 시간 표시
- [x] 채팅 이미지 전송
- [x] 읽음 표시 (안 읽은 사람 수 표시)
- [x] 메시지 삭제 (길게 눌러서 삭제)
- [x] 그룹 채팅방 나가기
- [x] 온라인/오프라인 상태 표시 (실시간)
- [x] 다크 모드
- [x] 비밀번호 찾기 (이메일 재설정)

### 예정

- [ ] 푸시 알림
- [ ] 앱 배포

## 참고 사항

### 온라인/오프라인 상태
- 브라우저 탭이 활성화(포커스)되면 온라인, 비활성화되면 오프라인으로 전환됩니다.
- 로컬에서 브라우저 2개로 테스트 시 한 번에 하나의 탭만 포커스 가능하므로 한쪽만 온라인으로 보일 수 있습니다.
- 실제 환경에서는 각자 다른 기기로 접속하면 동시에 온라인 표시됩니다.

## 프로젝트 구조

```
lib/
├── main.dart                  # 앱 진입점, Firebase 초기화, 인증 상태 관리
├── firebase_options.dart      # Firebase 설정 (자동 생성)
└── screens/
    ├── login_screen.dart      # 로그인/회원가입 화면
    ├── home_screen.dart       # 채팅방 목록 화면
    ├── chat_screen.dart       # 채팅 화면 (텍스트 + 이미지, 1:1 + 그룹)
    ├── search_screen.dart     # 유저 검색 화면
    ├── create_group_screen.dart # 그룹 채팅방 생성 화면
    └── profile_screen.dart    # 프로필 화면
```

## Firestore 데이터 구조

```
users/{uid}
├── email
├── uid
├── nickname
├── profileImageUrl
└── createdAt

chats/{chatId}
├── users: [uid1, uid2, ...]
├── userEmails: [email1, email2, ...]
├── isGroup: true/false
├── groupName (그룹인 경우)
├── lastMessage
├── lastMessageTime
└── messages/{messageId}
    ├── text
    ├── imageUrl (이미지 메시지인 경우)
    ├── type: "text" | "image"
    ├── readBy: [uid1, uid2, ...]
    ├── senderId
    ├── senderEmail
    └── timestamp
```

## Firestore 인덱스 (필수)

| 컬렉션 | 필드 1 | 필드 2 |
|--------|--------|--------|
| chats | users (배열 포함) | lastMessageTime (내림차순) |

## 실행 방법

```bash
cd flutter_learning
flutter pub get
flutter run
```

## 환경 설정

### Firebase Storage CORS 설정 (웹 실행 시 필요)

```bash
echo '[{"origin": ["*"], "method": ["GET"], "maxAgeSeconds": 3600}]' > cors.json
gsutil cors set cors.json gs://<your-bucket>.firebasestorage.app
rm cors.json
```

## 요구사항

- Flutter SDK
- Firebase CLI
- FlutterFire CLI
- Firebase Blaze 플랜 (Storage 사용)
- gsutil (Firebase Storage CORS 설정용)
