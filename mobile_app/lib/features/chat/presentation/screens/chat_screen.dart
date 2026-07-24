import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/localization/app_strings.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../farms/presentation/providers/farm_provider.dart';
import '../../data/chat_repository.dart';

class ChatMessage {
  const ChatMessage({required this.text, required this.fromUser});
  final String text;
  final bool fromUser;
}

/// Grounded in the farm's real dashboard data (crop/weather/land-health/
/// water/market — already loaded by the dashboard tab, assembled into a
/// context object here rather than re-fetched) and answered by a single
/// live Claude call via the gateway's /chat/ask proxy. Replaces the earlier
/// keyword-matched canned-reply placeholder now that the backend exists.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _repository = ChatRepository();
  final List<ChatMessage> _messages = [];
  final List<ChatTurn> _history = [];
  bool _greeted = false;
  bool _typing = false;
  bool _triedInitialLoad = false;

  Map<String, dynamic> _buildContext() {
    final data = ref.read(dashboardControllerProvider).value;
    final farm = ref.read(activeFarmProvider);
    final crop = data?.cropRecommendation?.top;
    final market = data?.marketForecast;
    return {
      if (farm != null) 'farm_area_acres': farm.areaAcres,
      if (data?.landHealth != null) 'land_health_score': data!.landHealth!.score,
      if (crop != null) 'top_recommended_crop': crop.cropName,
      if (crop != null) 'crop_suitability_percent': crop.suitabilityPercent,
      if (data?.weather != null) 'avg_temp_c': data!.weather!.avgTempC,
      if (data?.weather != null) 'total_rainfall_mm_7d': data!.weather!.totalRainfallMm,
      if (data?.waterResources != null) 'irrigation_method': data!.waterResources!.irrigationMethod,
      if (data?.waterResources != null) 'groundwater_category': data!.waterResources!.groundwaterCategory,
      if (market != null) 'market_commodity': market.commodity,
      if (market != null) 'market_price_low_inr': market.nearTermLowInr,
      if (market != null) 'market_price_high_inr': market.nearTermHighInr,
    };
  }

  Future<void> _send(String text) async {
    if (text.trim().isEmpty || _typing) return;
    final question = text.trim();
    setState(() {
      _messages.add(ChatMessage(text: question, fromUser: true));
      _typing = true;
    });
    _controller.clear();
    _scrollToBottom();

    try {
      final reply = await _repository.ask(
        question: question,
        history: List.of(_history),
        context: _buildContext(),
        language: ref.read(languageProvider),
      );
      if (!mounted) return;
      final replyText = reply.isNotEmpty ? reply : ref.read(appStringsProvider).somethingWentWrong;
      setState(() {
        _messages.add(ChatMessage(text: replyText, fromUser: false));
        _history.add(ChatTurn(role: 'user', content: question));
        _history.add(ChatTurn(role: 'assistant', content: replyText));
        _typing = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(ChatMessage(text: ref.read(appStringsProvider).somethingWentWrong, fromUser: false));
        _typing = false;
      });
    }
    _scrollToBottom();
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
    final activeFarm = ref.watch(activeFarmProvider);
    final dashboardState = ref.watch(dashboardControllerProvider);

    if (!_triedInitialLoad && activeFarm != null && dashboardState.value == null && !dashboardState.isLoading) {
      _triedInitialLoad = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardControllerProvider.notifier).loadForFarm(activeFarm);
      });
    }

    if (!_greeted) {
      _greeted = true;
      _messages.add(ChatMessage(fromUser: false, text: s.chatGreeting));
    }

    final suggestions = [s.chatSuggestion1, s.chatSuggestion2, s.chatSuggestion3, s.chatSuggestion4];

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
                  label: Text(suggestions[i]),
                  onPressed: () => _send(suggestions[i]),
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
                    onSubmitted: _send,
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
