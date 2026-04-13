// lib/screens/chat_detail_page.dart
import 'package:chime_mobile/config.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('1234567890123456');
  static final iv = encrypt.IV.fromUtf8('1234567890123456');

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64;
  }

  static String decryptText(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (_) {
      return "[Decryption error]";
    }
  }
}

class ChatDetailPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;
  final String otherUsername;

  const ChatDetailPage({
    super.key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUsername,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  List<Map<String, dynamic>> messages = [];
  bool loading = true;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final baseUrl = AppConfig.baseUrl;
  late IO.Socket socket;

  @override
  void initState() {
    super.initState();
    initSocket();
    fetchMessages(); // 🔥 IMPORTANT
  }

  // ================= FETCH OLD MESSAGES =================
  Future<void> fetchMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final res = await http.get(
        Uri.parse('$baseUrl/api/messages/${widget.otherUserId}'),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);

        setState(() {
          messages = data.map((e) {
            final msg = Map<String, dynamic>.from(e);
            msg['timestamp'] = msg['createdAt'];
            msg['content'] =
                EncryptionHelper.decryptText(msg['content']);
            return msg;
          }).toList();
        });

        _scrollToBottom();
      }
    } catch (e) {
      debugPrint("Fetch error: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  // ================= SOCKET =================
  void initSocket() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('token');

  socket = IO.io(baseUrl, {
    'transports': ['websocket'],
    'autoConnect': false,
    'auth': {
      'token': token,
    }
  });

  socket.connect();

  socket.onConnect((_) {
    debugPrint("✅ Socket connected");

    final roomId = [widget.currentUserId, widget.otherUserId]..sort();
    socket.emit('joinRoom', roomId.join('_'));
  });

  socket.on('receiveMessage', (data) {
    final msg = Map<String, dynamic>.from(data);

    msg['timestamp'] = msg['createdAt'] ?? msg['timestamp'];
    msg['content'] = EncryptionHelper.decryptText(msg['content']);

    // ✅ FIX: remove using tempId ONLY
    if (msg['tempId'] != null) {
      messages.removeWhere((m) => m['tempId'] == msg['tempId']);
    }

    setState(() {
      messages.add(msg);
    });

    _scrollToBottom();
  });
}

  // ================= SEND =================
  void sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final encrypted = EncryptionHelper.encryptText(text);
    final tempId = DateTime.now().millisecondsSinceEpoch.toString();

    final tempMsg = {
      'tempId': tempId,
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'content': text,
      'timestamp': DateTime.now().toIso8601String(),
      'pending': true,
    };

    setState(() {
      messages.add(tempMsg);
      _controller.clear();
    });

    _scrollToBottom();

    socket.emit('sendMessage', {
      'tempId': tempId,
      'senderId': widget.currentUserId,
      'receiverId': widget.otherUserId,
      'content': encrypted,
    });
  }

  // ================= SCROLL =================
  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  String formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    try {
      final dt = DateTime.parse(timestamp.toString()).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return '';
    }
  }

  @override
  void dispose() {
    socket.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
      ),
      body: Column(
        children: [
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : messages.isEmpty
                    ? Center(
                        child: Text(
                          "No messages yet — say hi 👋",
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe =
                              msg['senderId'] == widget.currentUserId;

                          return Align(
                            alignment: isMe
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                  vertical: 6, horizontal: 12),
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isMe
                                    ? Colors.indigo
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    msg['content'],
                                    style: TextStyle(
                                      color: isMe
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatTime(msg['timestamp']),
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isMe
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),

          // INPUT
          SafeArea(
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration:
                        const InputDecoration(hintText: "Message..."),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: sendMessage,
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}