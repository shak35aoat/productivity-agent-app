import 'package:flutter/foundation.dart';
import '../services/api_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  ChatMessage({required this.text, required this.isUser});
}

class AgentProvider extends ChangeNotifier {
  bool _loading = false;
  final List<ChatMessage> _messages = [];

  bool get loading => _loading;
  List<ChatMessage> get messages => List.unmodifiable(_messages);

  AgentProvider() {
    _messages.add(ChatMessage(
      text: 'Hi! I am your productivity agent. I know you are a 3rd year EEE student at RUET preparing for BCS. Ask me anything — study tips, task help, or career guidance!',
      isUser: false,
    ));
  }

  void addMessage(ChatMessage msg) {
    _messages.add(msg);
    notifyListeners();
  }

  Future<String> sendMessage({
    required String userId,
    required String name,
    required String message,
    String recentSummary = '',
  }) async {
    _loading = true;
    notifyListeners();

    try {
      final reply = await ApiService.chat(
        userId: userId,
        name: name,
        message: message,
        recentSummary: recentSummary,
      );
      _messages.add(ChatMessage(text: reply, isUser: false));
      return reply;
    } catch (e) {
      final err = 'Error: ${e.toString()}';
      _messages.add(ChatMessage(text: err, isUser: false));
      return err;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> getMorningBriefing(Map<String, dynamic> userData) async {
    _loading = true;
    notifyListeners();
    try {
      final message = await ApiService.morningCheckin(userData);
      _messages.add(ChatMessage(text: message, isUser: false));
      return message;
    } catch (e) {
      const err = 'Error fetching morning briefing';
      _messages.add(ChatMessage(text: err, isUser: false));
      return err;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String> getEveningReview(Map<String, dynamic> userData) async {
    _loading = true;
    notifyListeners();
    try {
      final message = await ApiService.eveningCheckin(userData);
      _messages.add(ChatMessage(text: message, isUser: false));
      return message;
    } catch (e) {
      const err = 'Error fetching evening review';
      _messages.add(ChatMessage(text: err, isUser: false));
      return err;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}

