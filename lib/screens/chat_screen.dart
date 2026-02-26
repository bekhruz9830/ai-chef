import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ai_chef/constants/theme.dart';
import 'package:ai_chef/services/gemini_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _gemini = GeminiService();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _loading = false;

  final List<String> _quickPrompts = [
    'What can I make with chicken?',
    'Quick 15-minute dinner ideas',
    'Healthy breakfast recipes',
    'Vegetarian meal ideas',
    'What to cook for a date?',
    'Budget-friendly meals',
  ];

  final List<String> _cuisinePrompts = [
    'Italian recipes 🇮🇹',
    'Asian recipes 🇯🇵',
    'Healthy meals 🥗',
    'Quick 15 min ⚡',
  ];

  @override
  void initState() {
    super.initState();
    _addWelcomeMessage();
  }

  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      text:
          "Hi! I'm CHEF AI 👨‍🍳\n\nI'm your personal cooking assistant! I can help you with:\n• Recipe suggestions\n• Cooking techniques\n• Ingredient substitutions\n• Meal planning\n\nWhat shall we cook today? 🍳",
      isUser: false,
      time: DateTime.now(),
    ));
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;
    HapticFeedback.mediumImpact();
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        text: trimmed,
        isUser: true,
        time: DateTime.now(),
      ));
      _loading = true;
    });

    _scrollToBottom();

    try {
      final response = await _gemini.chat(trimmed);
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(
          text: response.isNotEmpty ? response : 'Извините, не удалось получить ответ.',
          isUser: false,
          time: DateTime.now(),
        ));
      });
    } catch (e) {
      final errorMsg = _getChatErrorMessage(e);
      if (mounted) {
        setState(() {
          _messages.add(ChatMessage(
            text: errorMsg,
            isUser: false,
            time: DateTime.now(),
          ));
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  String _getChatErrorMessage(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('socket') || msg.contains('connection') || msg.contains('network')) {
      return 'No internet. Check connection and try again.';
    }
    if (msg.contains('401') || msg.contains('invalid') && msg.contains('key')) {
      return 'API key error. Check lib/config/keys.dart.';
    }
    if (msg.contains('quota') || msg.contains('429') || msg.contains('exceeded')) {
      return 'Too many requests. Wait a minute and try again.';
    }
    return 'Could not send message. Try again.';
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

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradient1, AppColors.gradient2],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('👨‍🍳', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CHEF AI',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Online',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {
              _gemini.resetChat();
              setState(() {
                _messages.clear();
                _addWelcomeMessage();
              });
            },
            icon: const Icon(Icons.refresh),
            tooltip: 'New chat',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _buildTypingIndicator();
                }
                return _buildMessage(_messages[index]);
              },
            ),
          ),
          if (_messages.length == 1) _buildQuickPrompts(),
          if (_messages.length == 1) _buildCuisineButtons(),
          _buildInput(),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.gradient1, AppColors.gradient2],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text('👨‍🍳', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: isUser ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Color.fromRGBO(0, 0, 0, 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.text,
                style: AppTextStyles.body.copyWith(
                  color: isUser ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradient1, AppColors.gradient2],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text('👨‍🍳', style: TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + index * 200),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 107, 53, 0.3 + value * 0.7),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }

  Widget _buildCuisineButtons() {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _cuisinePrompts.map((label) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              _sendMessage(label);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color.fromRGBO(255, 107, 53, 0.15),
                    Color.fromRGBO(255, 140, 90, 0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.fromRGBO(255, 107, 53, 0.4)),
              ),
              child: Text(
                label,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildQuickPrompts() {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _quickPrompts.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () => _sendMessage(_quickPrompts[index]),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Color.fromRGBO(255, 107, 53, 0.3)),
              ),
              child: Text(
                _quickPrompts[index],
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: 'Ask CHEF AI anything...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: _sendMessage,
                textInputAction: TextInputAction.send,
                maxLines: null,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                _sendMessage(_controller.text);
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradient1, AppColors.gradient2],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(255, 107, 53, 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
