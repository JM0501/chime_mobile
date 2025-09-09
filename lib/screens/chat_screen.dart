// lib/screens/chat_page.dart
import 'package:chime_mobile/screens/chat_detail.dart';
import 'package:chime_mobile/screens/select_user.dart';
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

class ChatPage extends StatefulWidget {
  final int currentUserId;
  const ChatPage({super.key, required this.currentUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();
  final String baseUrl = 'https://chime-api.onrender.com';

  @override
  void initState() {
    super.initState();
    fetchChats();
    _searchController.addListener(_filterChats);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String safeDecrypt(String encryptedText) {
    try {
      return EncryptionHelper.decryptText(encryptedText);
    } catch (_) {
      return "[Decryption error]";
    }
  }

  Future<void> fetchChats() async {
    setState(() => loading = true);
    try {
      final url = Uri.parse(
        "$baseUrl/api/users/chats?userId=${widget.currentUserId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          chats = data.map((e) {
            final chat = e as Map<String, dynamic>;
            // 🔓 Decrypt last message
            chat['LastMessage'] =
                chat['LastMessage'] != null ? safeDecrypt(chat['LastMessage']) : '';
            return chat;
          }).toList();
          filteredChats = List.from(chats);
          loading = false;
        });
      } else {
        throw Exception("Failed to load chats");
      }
    } catch (e) {
      setState(() => loading = false);
      print("Error fetching chats: $e");
    }
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredChats = chats
          .where((c) => (c['Username'] ?? "Unknown")
              .toString()
              .toLowerCase()
              .contains(query))
          .toList();
    });
  }

  String formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return DateFormat('hh:mm a').format(dateTime);
  }

  void _logout() {
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Chime",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: "Logout",
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          // 🔍 Search bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search chats...",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchChats,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredChats.isEmpty
                      ? Center(
                          child: Text(
                            "No chats found",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 12,
                          ),
                          itemCount: filteredChats.length,
                          itemBuilder: (context, index) {
                            final chat = filteredChats[index];
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailPage(
                                      currentUserId: widget.currentUserId,
                                      otherUserId: chat['Id'],
                                      otherUsername:
                                          chat['Username'] ?? "Unknown",
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 26,
                                      backgroundColor: Colors.blue[100],
                                      child: const Icon(
                                        Icons.person,
                                        size: 28,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            chat['Username'] ?? "Unknown",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            chat['LastMessage'] ?? "",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      chat['LastMessageTime'] != null
                                          ? formatTimestamp(
                                              chat['LastMessageTime'])
                                          : "",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SelectUserPage(currentUserId: widget.currentUserId),
            ),
          );
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
