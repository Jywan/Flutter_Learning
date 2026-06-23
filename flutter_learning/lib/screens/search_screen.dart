import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];

  void _searchUsers() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;

    // 이메일 prefix 검색 (시작 문자열 매칭)
    final emailResult = await FirebaseFirestore.instance
      .collection('users')
      .where('email', isGreaterThanOrEqualTo: query)
      .where('email', isLessThan: '$query\uf8ff')
      .get();

    // 닉네임 prefix 검색 (시작 문자열 매칭)
    final nicknameResult = await FirebaseFirestore.instance
      .collection('users')
      .where('nickname', isGreaterThanOrEqualTo: query)
      .where('nickname', isLessThan: '$query\uf8ff')
      .get();

    // 중복 제거후 합치기 작업
    final allDocs = <String, Map<String, dynamic>>{};
    for (final doc in [...emailResult.docs, ...nicknameResult.docs]) {
      if (doc['email'] != currentUser.email) {
        allDocs[doc.id] = {
          'uid': doc.id,
          'email': doc['email'],
          'nickname': doc['nickname'] ?? doc['email'],
        };
      }
    }

    setState(() {
      _searchResults = allDocs.values.toList();
    });
  }

  void _startChat(String otherUid, String otherEmail) async {
    final currentUser = FirebaseAuth.instance.currentUser!;

    // 이미 존재하는 채팅방 확인
    final existing = await FirebaseFirestore.instance
        .collection('chats')
        .where('users', arrayContains: currentUser.uid)
        .get();

    String? chatId;
    for (final doc in existing.docs) {
      final users = List<String>.from(doc['users']);
      if (users.contains(otherUid)) {
        chatId = doc.id;
        break;
      }
    }

    // 없으면 새로 생성
    if (chatId == null) {
      final newChat = await FirebaseFirestore.instance.collection('chats').add({
        'users': [currentUser.uid, otherUid],
        'userEmails': [currentUser.email, otherEmail],
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
      chatId = newChat.id;
    }

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: chatId!,
            otherUserEmail: otherEmail,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('유저 검색'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: '이메일 또는 닉네임으로 검색...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _searchUsers(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchUsers,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final user = _searchResults[index];
                  return ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(user['nickname']),
                    subtitle: Text(user['email']),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_bubble_outline),
                      onPressed: () => _startChat(user['uid'], user['email']),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
