import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/theme/app_colors.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.fromUser, this.confidence});
  final String text;
  final bool fromUser;
  final double? confidence;
}

/// Canned keyword-matched replies so the AI Chat flow is demoable before
/// the RAG-grounded Chat Service (docs/architecture/MODULES.md §15) exists.
/// Real answers will come from tool calls into Weather/Crop/Market
/// services rather than from static strings.
///
/// [intent] is set when the question came from tapping a suggestion chip
/// (whose label is already translated) rather than typed keyword-matching
/// on the raw English question text, which wouldn't work once the
/// question itself is in Tamil.
String _mockReply(String question, AppStrings s, {String? intent}) {
  final q = question.toLowerCase();
  if (intent == 'rain' || q.contains('rain') || q.contains('weather')) {
    return s.chatReplyRain;
  }
  if (q.contains('coconut')) {
    return s.chatReplyCoconut;
  }
  if (intent == 'profit' || q.contains('profit') || q.contains('grow')) {
    return s.chatReplyProfit;
  }
  if (intent == 'disease' || q.contains('yellow') || q.contains('disease') || q.contains('leaf')) {
    return s.chatReplyDisease;
  }
  if (intent == 'irrigation' || q.contains('irrigat')) {
    return s.chatReplyIrrigation;
  }
  return s.chatReplyFallback;
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _greeted = false;
  bool _typing = false;

  void _send(String text, {String? intent}) {
    if (text.trim().isEmpty) return;
    final s = ref.read(appStringsProvider);
    setState(() {
      _messages.add(ChatMessage(text: text.trim(), fromUser: true));
      _typing = true;
    });
    _controller.clear();
    _scrollToBottom();

    Future.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: _mockReply(text, s, intent: intent), fromUser: false, confidence: 0.6));
        _typing = false;
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
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
    final s = ref.watch(appStringsProvider);

    if (!_greeted) {
      _greeted = true;
      _messages.add(ChatMessage(fromUser: false, text: s.chatGreeting));
    }

    final suggestions = [
      (label: s.chatSuggestion1, intent: 'rain'),
      (label: s.chatSuggestion2, intent: 'profit'),
      (label: s.chatSuggestion3, intent: 'irrigation'),
      (label: s.chatSuggestion4, intent: 'disease'),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(s.aiAdvisor)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _messages.length + (_typing ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _messages.length) return const _TypingBubble();
                return _MessageBubble(message: _messages[i]);
              },
            ),
          ),
          if (_messages.length <= 1)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) => ActionChip(
                  label: Text(suggestions[i].label),
                  onPressed: () => _send(suggestions[i].label, intent: suggestions[i].intent),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onSubmitted: (text) => _send(text),
                    decoration: InputDecoration(hintText: s.askAboutFarm),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: () => _send(_controller.text),
                  icon: const Icon(Icons.send_rounded),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(14)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});
  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          message.text,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isUser ? Colors.white : AppColors.textPrimary,
              ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(color: AppColors.surfaceAlt, borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 24,
          height: 12,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              3,
              (_) => const CircleAvatar(radius: 3, backgroundColor: AppColors.textSecondary),
            ),
          ),
        ),
      ),
    );
  }
}
