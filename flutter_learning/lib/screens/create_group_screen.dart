import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'chat_screen.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _groupNameController = TextEditingController();
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _searchResults = [];
  List<Map<String, dynamic>> _selectedUsers = [];

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

  // 중복 제거 후 합치기
  final allDocs = <String, Map<String, dynamic>>{};
  for (final doc in [...emailResult.docs, ...nicknameResult.docs]) {
    if (doc['email'] != currentUser.email &&
        !_selectedUsers.any((selected) => selected['uid'] == doc.id)) {
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

  void _addUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.add(user);
      _searchResults.remove(user);
      _searchController.clear();
    });
  }

  void _removeUser(Map<String, dynamic> user) {
    setState(() {
      _selectedUsers.remove(user);
    });
  }

  void _createGroup() async {
    final groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('그룹 이름을 입력해주세요.')),
      );
      return;
    }

    if (_selectedUsers.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('2명 이상 선택해주세요.'))
      );
      return;
    }

    final currentUser = FirebaseAuth.instance.currentUser!;

    final allUids = [currentUser.uid, ..._selectedUsers.map((u) => u['uid'])];
    final allEmails = [currentUser.email, ..._selectedUsers.map((u) => u['email'])];

    final newChat = await FirebaseFirestore.instance.collection('chats').add({
      'users': allUids,
      'userEmails': allEmails,
      'groupName': groupName,
      'isGroup': true,
      'lastMessage': '',
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            chatId: newChat.id, 
            otherUserEmail: groupName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('그룹 채팅 만들기'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 그룹이름
            TextField(
              controller: _groupNameController,
              decoration: const InputDecoration(
                labelText: '그룹 이름',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.group),
              ),
            ),
            const SizedBox(height: 16),

            // 선택된 유저들
            if (_selectedUsers.isNotEmpty) ...[
              const Text('참여자', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _selectedUsers.map((user) {
                  return Chip(
                    label: Text(user['nickname']),
                    onDeleted: () => _removeUser(user),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            // 유저 검색
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
            const SizedBox(height: 8),

            // 검색 결과
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
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: () => _addUser(user),
                    ),
                  );
                },
              ),
            ),

            // 생성 버튼
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text('그룹 만들기 (${_selectedUsers.length}명 선택)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}