import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserEmail;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.otherUserEmail,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  String _otherUserNickname = '';
  String? _otherUserProfileUrl;
  bool _isUploading = false;
  bool _isGroup = false;
  int _memberCount = 0;

  @override
  void initState() {
    super.initState();
    _loadChatInfo();
  }

  Future<void> _loadChatInfo() async {
    final doc = await FirebaseFirestore.instance
      .collection('chats')
      .doc(widget.chatId)
      .get();

    if (doc.exists) {
      final data = doc.data()!;
      final users = data['users'] as List<dynamic>;
      setState(() {
        _isGroup = data['isGroup'] ?? false;
        _memberCount = users.length;
      });
    }

    if (!_isGroup) {
      _loadOtherUserInfo();
    }
  }

  Future<void> _loadOtherUserInfo() async {
    final query = await FirebaseFirestore.instance
        .collection('users')
        .where('email', isEqualTo: widget.otherUserEmail)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      final data = query.docs.first.data();
      setState(() {
        _otherUserNickname = data['nickname'] ?? widget.otherUserEmail;
        _otherUserProfileUrl = data['profileImageUrl'];
      });
    }
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = FirebaseAuth.instance.currentUser!;
    _messageController.clear();

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUser.uid,
      'senderEmail': currentUser.email,
      'type': 'text',
      'readBy': [currentUser.uid],
      'timestamp': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
      'lastMessage': text,
      'lastMessageTime': FieldValue.serverTimestamp(),
    });

    _scrollToBottom();
  }

  Future<void> _sendImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024);

    if (picked == null) return;

    setState(() => _isUploading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser!;
      final timestamp = DateTime.now().microsecondsSinceEpoch;
      final ref = FirebaseStorage.instance
        .ref()
        .child('chats/${widget.chatId}/$timestamp.jpg');
      
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      } else {
        await ref.putFile(File(picked.path));
      }

      final imageUrl = await ref.getDownloadURL();

      await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .add({
          'text': '',
          'imageUrl': imageUrl,
          'senderId': currentUser.uid,
          'senderEmail': currentUser.email,
          'type': 'image',
          'readBy': [currentUser.uid],
          'timestamp': FieldValue.serverTimestamp(),
        });
      
      await FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .update({
          'lastMessage': '사진',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('이미지 전송 실패: $e')),
        );
      }
    } finally {
      setState(() => _isUploading = false);
    }
  }

  void _markMessagesAsRead(List<QueryDocumentSnapshot> messages) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    for (final msg in messages) {
      final data = msg.data() as Map<String, dynamic>;
      final readBy = List<String>.from(data['readBy'] ?? []);

      if (!readBy.contains(currentUser.uid)) {
        msg.reference.update({
          'readBy': FieldValue.arrayUnion([currentUser.uid]),
        });
      }
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return DateFormat('HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundImage: (!_isGroup && _otherUserProfileUrl != null)
                  ? NetworkImage(_otherUserProfileUrl!)
                  : null,
              child: _isGroup
                ? const Icon(Icons.group, size: 16)
                : (_otherUserProfileUrl == null
                    ? const Icon(Icons.person, size: 16)
                    : null),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _isGroup
                    ? widget.otherUserEmail
                    : (_otherUserNickname.isNotEmpty
                        ? _otherUserNickname
                        : widget.otherUserEmail),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .doc(widget.chatId)
                  .collection('messages')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data?.docs ?? [];

                if (messages.isNotEmpty) {
                  _markMessagesAsRead(messages);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index].data() as Map<String, dynamic>;
                    final isMe = msg['senderId'] == currentUser.uid;
                    final time = _formatTime(msg['timestamp'] as Timestamp?);
                    final type = msg['type'] ?? 'text';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment:
                            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            CircleAvatar(
                              radius: 14,
                              backgroundImage: _otherUserProfileUrl != null
                                  ? NetworkImage(_otherUserProfileUrl!)
                                  : null,
                              child: _otherUserProfileUrl == null
                                  ? const Icon(Icons.person, size: 14)
                                  : null,
                            ),
                            const SizedBox(width: 6),
                          ],
                          if (isMe)
                            Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (_memberCount > 0) 
                                    Builder(builder: (context) {
                                      final readBy = List<String>.from(msg['readBy'] ?? []);
                                      final unreadCount = _memberCount - readBy.length;
                                      if (unreadCount > 0) {
                                        return Text(
                                          '$unreadCount',
                                          style: const TextStyle(fontSize: 11, color: Colors.amber),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }),
                                    Text(time, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                if (!isMe && _isGroup)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 2),
                                    child: Text(
                                      msg['senderEmail'] ?? '',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ),
                                Container(
                                  padding: type == 'image'
                                      ? const EdgeInsets.all(4)
                                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isMe ? Colors.blue[400] : Colors.grey[200],
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16),
                                      topRight: const Radius.circular(16),
                                      bottomLeft: Radius.circular(isMe ? 16 : 4),
                                      bottomRight: Radius.circular(isMe ? 4 : 16),
                                    ),
                                  ),
                                  child: type == 'image'
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(12),
                                          child: Image.network(
                                            msg['imageUrl'] ?? '',
                                            width: 200,
                                            fit: BoxFit.cover,
                                            loadingBuilder: (context, child, loadingProgress) {
                                              if (loadingProgress == null) return child;
                                              return const SizedBox(
                                                width: 200,
                                                height: 150,
                                                child: Center(child: CircularProgressIndicator()),
                                              );
                                            },
                                          ),
                                        )
                                      : Text(
                                          msg['text'] ?? '',
                                          style: TextStyle(
                                            color: isMe ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                ),
                              ],
                            ),
                          ),
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Text(time,
                                  style: const TextStyle(
                                      fontSize: 11, color: Colors.grey)),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          // 업로드 중 표시
          if (_isUploading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2,)),
                  SizedBox(width: 8),
                  Text('이미지 업로드 중...', style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),

          // 메시지 입력창
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200, 
                  blurRadius: 4, 
                  offset: const Offset(0, -1)),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.image, color: Colors.grey),
                    onPressed: _isUploading ? null : _sendImage,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: '메시지를 입력하세요...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 20),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
