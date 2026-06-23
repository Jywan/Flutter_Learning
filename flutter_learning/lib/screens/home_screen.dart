import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'login_screen.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'profile_screen.dart';
import 'create_group_screen.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    if (date.day == now.day && date.month == now.month && date.year == now.year) {
      return DateFormat('HH:mm').format(date);
    }
    return DateFormat('MM/dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('채팅'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid != null) {
                await FirebaseFirestore.instance.collection('users').doc(uid).update({
                  'isOnline': false,
                  'lastSeen': FieldValue.serverTimestamp(),
                });
              }
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('users', arrayContains: currentUser.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data?.docs ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('채팅방이 없습니다.',
                      style: TextStyle(fontSize: 16, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('오른쪽 아래 버튼으로 대화를 시작하세요!',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index].data() as Map<String, dynamic>;
              final isGroup = chat['isGroup'] ?? false;
              final displayName = isGroup
                  ? chat['groupName'] ?? '그룹 채팅'
                  : null;
              final otherUserEmail = isGroup
                  ? ''
                  : (chat['userEmails'] as List<dynamic>)
                      .firstWhere((email) => email != currentUser.email,
                          orElse: () => '알 수 없음');

              final time = _formatTime(chat['lastMessageTime'] as Timestamp?);

              // 그룹이면 FutureBuilder 없이 바로 표시
              if (isGroup) {
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.group)),
                  title: Text(displayName!),
                  subtitle: Text(
                    chat['lastMessage'] ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Text(time,
                      style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          chatId: chats[index].id,
                          otherUserEmail: displayName!,
                        ),
                      ),
                    );
                  },
                );
              }

              // 1:1 채팅은 상대방 정보 조회
              return FutureBuilder<QuerySnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .where('email', isEqualTo: otherUserEmail)
                    .limit(1)
                    .get(),
                builder: (context, userSnapshot) {
                  String nickname = otherUserEmail;
                  String? profileUrl;

                  if (userSnapshot.hasData && userSnapshot.data!.docs.isNotEmpty) {
                    final userData = userSnapshot.data!.docs.first.data()
                        as Map<String, dynamic>;
                    nickname = userData['nickname'] ?? otherUserEmail;
                    profileUrl = userData['profileImageUrl'];
                  }

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          profileUrl != null ? NetworkImage(profileUrl) : null,
                      child: profileUrl == null
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(nickname),
                    subtitle: Text(
                      chat['lastMessage'] ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(time,
                          style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 4),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                            .collection('chats')
                            .doc(chats[index].id)
                            .collection('messages')
                            .where('readBy', whereNotIn: [[currentUser.uid]])
                            .snapshots(),
                          builder: (context, msgSnapshot) {
                            // readBy에 내 uid가 없는 메시지 수를 세야 함
                            return const SizedBox.shrink();
                          },
                        )
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            chatId: chats[index].id,
                            otherUserEmail: otherUserEmail,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'group',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CreateGroupScreen()),
              );
            },
            child: const Icon(Icons.group_add),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'chat',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
            child: const Icon(Icons.chat),
          ),
        ],
      ),
    );
  }
}
