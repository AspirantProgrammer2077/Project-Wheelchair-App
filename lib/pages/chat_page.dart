// ignore_for_file: avoid_print, deprecated_member_use, unnecessary_to_list_in_spreads

import 'dart:convert';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:wheelchair_app/models/apikey.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'Wheelchair', lastName: 'User');

  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'AI', lastName: 'Companion');

  final List<ChatMessage> _messages = <ChatMessage>[];
  final List<ChatUser> _typingUser = <ChatUser>[];

  // ✅ Default model - Most reliable
  String _selectedModel = "google/gemini-2.0-flash-exp:free";
  String _selectedModelName = "General";

  // ✅ TOP TIER: Most reliable free models (verified January 31, 2025)
  final List<Map<String, String>> _models = [
    {
      'id': 'google/gemini-2.0-flash-exp:free',
      'name': 'General',
      'description': 'Answers quickly',
    },
    {
      'id': 'meta-llama/llama-3.3-70b-instruct:free',
      'name': 'Multilingual',
      'description': 'Supports multiple languages',
    },
    {
      'id': 'deepseek/deepseek-r1-0528:free',
      'name': 'Math & Reasoning',
      'description': 'Solves complex problems',
    },
    {
      'id': 'qwen/qwen3-coder:free',
      'name': 'Coder',
      'description': 'Programming & coding tasks',
    },
    {
      'id': 'tngtech/deepseek-r1t2-chimera:free',
      'name': 'Philosophical',
      'description': 'Advanced deep reasoning',
    },
  ];

  // Fallback models in case primary models fail
  final List<String> _fallbackModels = [
    'google/gemini-2.0-flash-exp:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-r1-0528:free',
    'nousresearch/hermes-3-llama-3.1-405b:free',
    'google/gemma-3-27b-it:free',
  ];

  final List<String> _availableModels = [
    'google/gemini-2.0-flash-exp:free',
    'meta-llama/llama-3.3-70b-instruct:free',
    'deepseek/deepseek-r1-0528:free',
    'qwen/qwen3-coder:free',
    'tngtech/deepseek-r1t2-chimera:free',
  ];

  // ================= MESSAGE QUEUE + COOLDOWN =================
  final List<ChatMessage> _messageQueue = [];
  bool _isProcessingQueue = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'AI Companion',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            const SizedBox(width: 8),
            MenuAnchor(
              builder: (context, controller, child) {
                return IconButton(
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  onPressed: () {
                    controller.isOpen ? controller.close() : controller.open();
                  },
                );
              },
              menuChildren: _models.map((model) {
                bool isSelected = _selectedModel == model['id'];
                return Container(
                  width: 280,
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.85),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7E22CE)
                          : Colors.white.withOpacity(0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: MenuItemButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.transparent),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        _selectedModel = model['id']!;
                        _selectedModelName = model['name']!;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                model['name']!,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isSelected
                                      ? Colors.white
                                      : const Color(0xFF1E3C72),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                model['description']!,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.8)
                                      : const Color(0xFF1E3C72).withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle, color: Color(0xFF7E22CE), size: 24),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E3C72), Color(0xFF2A5298), Color(0xFF7E22CE)],
          ),
        ),
        child: SafeArea(
          child: DashChat(
            currentUser: _currentUser,
            typingUsers: _typingUser,
            onSend: (m) => sendMessage(m),
            messages: _messages,
            messageOptions: MessageOptions(
              currentUserContainerColor: const Color(0xFF7E22CE),
              currentUserTextColor: Colors.white,
              containerColor: Colors.white.withOpacity(0.95),
              textColor: const Color(0xFF1E3C72),
              showTime: true,
              messagePadding: const EdgeInsets.all(12),
              messageDecorationBuilder: (message, _, __) {
                return BoxDecoration(
                  gradient: message.user.id == _currentUser.id
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF7E22CE), Color(0xFF2A5298)],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(0.95),
                            Colors.white.withOpacity(0.85),
                          ],
                        ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: message.user.id == _currentUser.id
                        ? const Color(0xFF7E22CE).withOpacity(0.3)
                        : Colors.white.withOpacity(0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                );
              },
            ),
            inputOptions: InputOptions(
              inputDecoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: TextStyle(
                  color: const Color(0xFF1E3C72).withOpacity(0.5),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.95),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.3), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: const BorderSide(color: Color(0xFF7E22CE), width: 2),
                ),
              ),
              inputTextStyle: const TextStyle(color: Color(0xFF1E3C72), fontSize: 16),
              sendButtonBuilder: (send) {
                return Container(
                  margin: const EdgeInsets.only(left: 8),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF7E22CE), Color(0xFF2A5298)],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7E22CE).withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: send),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  // ================= MESSAGE QUEUE LOGIC WITH FALLBACK =================
  void sendMessage(ChatMessage message) {
    _messageQueue.add(message);
    _processQueue();
  }

  Future<void> _processQueue() async {
    if (_isProcessingQueue || _messageQueue.isEmpty) return;
    _isProcessingQueue = true;

    while (_messageQueue.isNotEmpty) {
      ChatMessage message = _messageQueue.removeAt(0);

      setState(() {
        _messages.insert(0, message);
        _typingUser.add(_gptChatUser);
      });

      bool success = false;
      String? responseText;

      // Try selected model first, then fallback models
      List<String> modelsToTry = [_selectedModel, ..._fallbackModels];
      
      for (String modelId in modelsToTry) {
        if (success) break;

        try {
          String systemPrompt;
          switch (_selectedModelName) {
            case "General":
              systemPrompt = "You are a friendly AI Companion inside a smart wheelchair app. Answer quickly and helpfully.";
              break;
            case "Multilingual":
              systemPrompt = "You are a multilingual AI Companion inside a smart wheelchair app. Support multiple languages and help users communicate effectively.";
              break;
            case "Math & Reasoning":
              systemPrompt = "You are a math and reasoning specialist AI Companion inside a smart wheelchair app. Solve complex problems step-by-step with clear explanations.";
              break;
            case "Coder":
              systemPrompt = "You are a programming expert AI Companion inside a smart wheelchair app. Help with coding tasks, debugging, and software development.";
              break;
            case "Philosophical":
              systemPrompt = "You are a philosophical AI Companion inside a smart wheelchair app. Engage in deep reasoning and thoughtful discussions.";
              break;
            default:
              systemPrompt = "You are a friendly AI Companion inside a smart wheelchair app.";
          }

          List<Map<String, dynamic>> messagesHistory = [
            {"role": "system", "content": systemPrompt},
            ..._messages.reversed.map((m) => {
                  "role": m.user == _currentUser ? "user" : "assistant",
                  "content": m.text,
                }),
          ];

          final response = await http.post(
            Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
            headers: {
              'Authorization': 'Bearer $OpenROUTER_API_KEY',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'model': modelId, 'messages': messagesHistory}),
          ).timeout(const Duration(seconds: 60));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            responseText = data['choices'][0]['message']['content'];
            success = true;
          } else if (response.statusCode == 402) {
            // Quota exceeded, try next model
            print("Model $modelId quota exceeded, trying next...");
            continue;
          } else if (response.statusCode == 404) {
            // Model not found, try next model
            print("Model $modelId not found, trying next...");
            continue;
          } else if (response.statusCode == 429) {
            // Rate limited
            await Future.delayed(const Duration(seconds: 2));
            continue;
          }
        } catch (e) {
          print("Error with model $modelId: $e");
          continue;
        }
      }

      setState(() {
        if (success && responseText != null) {
          _messages.insert(
            0,
            ChatMessage(user: _gptChatUser, createdAt: DateTime.now(), text: responseText),
          );
        } else {
          _messages.insert(
            0,
            ChatMessage(
              user: _gptChatUser,
              createdAt: DateTime.now(),
              text: "⚠️ Free models quota exceeded. Please:\n\n1. Wait a few hours (50 requests/day limit)\n2. Or add \$10 credits to get 1000 requests/day\n3. Go to openrouter.ai/settings/privacy and enable 'Allow training'",
            ),
          );
        }
        _typingUser.remove(_gptChatUser);
      });

      await Future.delayed(const Duration(seconds: 2));
    }

    _isProcessingQueue = false;
  }
}