import '../models/message_model.dart';
import '../models/chat_model.dart';
import '../models/user_model.dart';

class SearchResultModel {
  final String id;
  final MessageModel message;
  final ChatModel chat;
  final String highlightedText;
  final List<int> matchPositions;
  final DateTime searchedAt;

  SearchResultModel({
    required this.id,
    required this.message,
    required this.chat,
    required this.highlightedText,
    required this.matchPositions,
    required this.searchedAt,
  });

  factory SearchResultModel.fromMap(
    Map<String, dynamic> map, {
    required MessageModel message,
    required ChatModel chat,
    required String query,
  }) {
    final content = message.content.toLowerCase();
    final queryLower = query.toLowerCase();
    final matchPositions = <int>[];

    int index = content.indexOf(queryLower);
    while (index != -1) {
      matchPositions.add(index);
      index = content.indexOf(queryLower, index + 1);
    }

    final highlightedText = _highlightMatches(
      message.content,
      query,
      matchPositions,
    );

    return SearchResultModel(
      id: '${message.id}_${chat.id}',
      message: message,
      chat: chat,
      highlightedText: highlightedText,
      matchPositions: matchPositions,
      searchedAt: DateTime.now(),
    );
  }

  static String _highlightMatches(
    String text,
    String query,
    List<int> positions,
  ) {
    if (positions.isEmpty) return text;

    const highlightStart = '<mark>';
    const highlightEnd = '</mark>';
    final queryLength = query.length;

    String result = text;
    int offset = 0;

    for (int pos in positions) {
      final adjustedPos = pos + offset;
      result =
          result.substring(0, adjustedPos) +
          highlightStart +
          result.substring(adjustedPos, adjustedPos + queryLength) +
          highlightEnd +
          result.substring(adjustedPos + queryLength);
      offset += highlightStart.length + highlightEnd.length;
    }

    return result;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'messageId': message.id,
      'chatId': chat.id,
      'highlightedText': highlightedText,
      'matchPositions': matchPositions,
      'searchedAt': searchedAt.millisecondsSinceEpoch,
    };
  }
}

class GlobalSearchResult {
  final List<SearchResultModel> messages;
  final List<ChatModel> chats;
  final List<UserModel> users;
  final String query;
  final int totalResults;
  final DateTime searchedAt;

  GlobalSearchResult({
    required this.messages,
    required this.chats,
    required this.users,
    required this.query,
    required this.totalResults,
    required this.searchedAt,
  });

  bool get hasResults => totalResults > 0;
}
