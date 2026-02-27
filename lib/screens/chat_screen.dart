// lib/screens/chat_screen.dart
import 'package:chime_mobile/screens/chat_detail.dart';
import 'package:chime_mobile/screens/select_user.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

/// Encryption helper for message encryption/decryption
class EncryptionHelper {
  static final key = encrypt.Key.fromUtf8('1234567890123456'); // 16 chars
  static final iv = encrypt.IV.fromUtf8('1234567890123456'); // 16 chars

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

class ChatPage extends StatefulWidget {
  final String currentUserId;
  const ChatPage({super.key, required this.currentUserId});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<Map<String, dynamic>> chats = [];
  List<Map<String, dynamic>> filteredChats = [];
  bool loading = true;
  final TextEditingController _searchController = TextEditingController();

  // Base URL
   final String baseUrl = 'http://192.168.22.1:5000'; // Local
  //final String baseUrl = 'https://chime-api.onrender.com'; // Production

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

  /// Fetch chats using token + tenantId
  Future<void> fetchChats() async {
    setState(() => loading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('userId');

      if (token == null || userId == null) {
        print("User not logged in — token missing.");
        _logout();
        return;
      }

      final url = Uri.parse('$baseUrl/api/users/chats');

      final response = await http.get(
        url,
        headers: {
          "Authorization": "Bearer $token", // JWT for auth
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        print("Fetched ${data.length} chats for user $userId");
        if (data.isEmpty) {
          setState(() {
            chats = [];
            filteredChats = [];
            loading = false;
          });
          return;
        }

        final loadedChats = data.map<Map<String, dynamic>>((chat) {
          chat['LastMessage'] = chat['LastMessage'] != null
              ? safeDecrypt(chat['LastMessage'])
              : '';
          return chat;
        }).toList();

        // Sort newest first
        loadedChats.sort((a, b) {
          final aTime =
              DateTime.tryParse(a['LastMessageTime'] ?? '') ?? DateTime(0);
          final bTime =
              DateTime.tryParse(b['LastMessageTime'] ?? '') ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

        setState(() {
          chats = loadedChats;
          filteredChats = List.from(chats);
          loading = false;
        });
      } else if (response.statusCode == 401) {
        // Token invalid or expired
        print("🔒 Session expired — logging out.");
        _logout();
      } else {
        print("Failed to load chats: ${response.statusCode}");
        setState(() => loading = false);
      }
    } catch (e) {
      print("Error fetching chats: $e");
      setState(() => loading = false);
    }
  }

  void _filterChats() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredChats = chats
          .where((chat) =>
              (chat['Username'] ?? "Unknown")
                  .toString()
                  .toLowerCase()
                  .contains(query))
          .toList();
    });
  }

  String formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('hh:mm a').format(dateTime);
    } catch (_) {
      return "";
    }
  }

  void _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/login');
    }
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

          // 💬 Chat list
          Expanded(
            child: RefreshIndicator(
              onRefresh: fetchChats,
              child: loading
                  ? const Center(child: CircularProgressIndicator())
                  : filteredChats.isEmpty
                      ? Center(
                          child: Text(
                            chats.isEmpty
                                ? "No messages yet — start a chat 💬"
                                : "No chats found",
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
                              onTap: () async {
                                await Navigator.push(
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
                                fetchChats();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 6),
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
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  SelectUserPage(currentUserId: widget.currentUserId),
            ),
          );
          fetchChats();
        },
        backgroundColor: Colors.blueAccent,
        child: const Icon(Icons.chat),
      ),
      backgroundColor: const Color(0xFFF5F5F5),
    );
  }
}
