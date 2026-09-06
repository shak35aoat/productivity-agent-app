import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = 'https://productivity-agent-backend-f6gs.onrender.com'; 

  static Future<String> chat({
    required String userId,
    required String name,
    required String message,
    String recentSummary = '',
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/chat'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'name': name,
        'message': message,
        'recent_summary': recentSummary,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      
      // If the backend sent a valid reply, return it
      if (responseData.containsKey('reply') && responseData['reply'] != null) {
        return responseData['reply'] as String;
      }
      
      // If the backend sent an error message instead, show it in the chat
      if (responseData.containsKey('error') && responseData['error'] != null) {
        return 'Backend Error: ${responseData['error']}';
      }
      
      // Fallback if the format is completely unrecognized
      return 'Unknown response from server.';
    }
    
    throw Exception('Chat request failed: ${response.statusCode}');
  }

  static Future<String> morningCheckin(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checkin/morning'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('message') && responseData['message'] != null) {
        return responseData['message'] as String;
      }
      return 'Check-in successful, but no message returned.';
    }
    throw Exception('Morning check-in failed: ${response.statusCode}');
  }

  static Future<String> eveningCheckin(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/checkin/evening'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      if (responseData.containsKey('message') && responseData['message'] != null) {
        return responseData['message'] as String;
      }
      return 'Check-in successful, but no message returned.';
    }
    throw Exception('Evening check-in failed: ${response.statusCode}');
  }
}