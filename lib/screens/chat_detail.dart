// lib/screens/chat_detail_page.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;

class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('1234567890123456'); // 16 chars
  static final iv = encrypt.IV.fromUtf8('1234567890123456');   // 16 chars

  static String encryptText(String plainText) {
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encrypt(plainText, iv: iv);
    return encrypted.base64; // store as base64
  }

  static String decryptText(String encryptedText) {
    try {
      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      return encrypter.decrypt64(encryptedText, iv: iv);
    } catch (e) {
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
  bool sending = false;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String baseUrl = 'https://chime-api.onrender.com';
  //final String baseUrl = 'http://192.168.1.177:5000';

  @override
  void initState() {
    super.initState();
    fetchMessages();
  }

  String safeDecrypt(String encryptedText) {
    try {
      return EncryptionHelper.decryptText(encryptedText);
    } catch (_) {
      return "[Decryption error]";
    }
  }

  Future<void> fetchMessages() async {
    setState(() => loading = true);
    try {
      final url = Uri.parse(
        '$baseUrl/api/messages?user1=${widget.currentUserId}&user2=${widget.otherUserId}',
      );
      final res = await http.get(url);

      if (res.statusCode == 200) {
        final List data = json.decode(res.body);
        print("Raw data $data");
        setState(() {
          messages = data.map((e) {
            final msg = Map<String, dynamic>.from(e);
            msg['content'] = safeDecrypt(msg['content']);
            return msg;
          }).toList();
          print("Fetched ${messages.length} messages");
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        debugPrint('Failed to load messages: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => sending = true);
    try {
      final url = Uri.parse('$baseUrl/api/messages');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'senderId': widget.currentUserId,
          'receiverId': widget.otherUserId,
          'content': EncryptionHelper.encryptText(text), // 🔒 encrypt
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final Map<String, dynamic> newMsg =
            Map<String, dynamic>.from(json.decode(res.body));

        //Force SenderId to current user for instant alignment
        setState(() {
          messages.add({
            ...newMsg,
            'senderId': widget.currentUserId,
            'receiverId': widget.otherUserId,
            'content': text,
            'timestamp': DateTime.now().toIso8601String(),
          });
          _controller.clear();
        });

        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      } else {
        final Map<String, dynamic> err = json.decode(res.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err['error'] ?? 'Failed to send message')),
        );
      }
    } catch (e) {
      debugPrint('Send error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error sending message')),
      );
    } finally {
      setState(() => sending = false);
    }
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    _scrollController.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUsername),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
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
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final msg = messages[index];
                          final isMe = msg['senderId'] == widget.currentUserId;

                          final content = msg['content'] ?? '';
                          final time = formatTime(msg['timestamp'] ?? '');

                          return Align(
                            alignment:
                                isMe ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.of(context).size.width * 0.75),
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 10, horizontal: 12),
                              decoration: BoxDecoration(
                                color: isMe ? Colors.indigo : Colors.grey[200],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    content,
                                    style: TextStyle(
                                        color: isMe ? Colors.white : Colors.black87),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    time,
                                    style: TextStyle(
                                        fontSize: 11,
                                        color: isMe
                                            ? Colors.white70
                                            : Colors.black54),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
          ),
          SafeArea(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 6)
                  ]),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: "Type a message...",
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  sending
                      ? Container(
                          width: 44,
                          height: 44,
                          padding: const EdgeInsets.all(10),
                          child:
                              const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : GestureDetector(
                          onTap: sendMessage,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withOpacity(0.08),
                                    blurRadius: 4)
                              ],
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 20),
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
