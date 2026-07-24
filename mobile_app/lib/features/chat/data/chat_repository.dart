import '../../../core/network/api_client.dart';

class ChatTurn {
  const ChatTurn({required this.role, required this.content});
  final String role; // "user" | "assistant"
  final String content;

  Map<String, dynamic> toJson() => {'role': role, 'content': content};
}

/// Talks to the gateway's /chat/ask proxy (backend/services/ai_chat).
/// The farm context is assembled client-side from data the dashboard call
/// already loaded — same "client aggregates what it already has" pattern
/// as the Market/Fertilizer/Irrigation crop selectors.
class ChatRepository {
  Future<String> ask({
    required String question,
    required List<ChatTurn> history,
    required Map<String, dynamic> context,
    String language = 'en',
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/chat/ask',
      data: {
        'question': question,
        'history': history.map((t) => t.toJson()).toList(),
        'context': context,
        'language': language,
      },
    );
    final data = response.data!;
    final result = data['result'] as Map<String, dynamic>?;
    return result?['reply'] as String? ?? '';
  }
}
