// lib/services/chat_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatService {
  static const String _baseUrl = 'http://localhost:8000'; // Changed from 5000 to 8000
  static const String _chatEndpoint = '/chat';
  static const String _clearEndpoint = '/clear_chat';
  static const String _healthEndpoint = '/health';
  
  final String conversationId;
  final http.Client _client;
  
  ChatService({String? conversationId}) 
    : conversationId = conversationId ?? const Uuid().v4(),
      _client = http.Client();

  // Send message to the Python backend
  Future<ChatResponse> sendMessage(String message) async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_chatEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'message': message,
          'conversation_id': conversationId,
        }),
      ).timeout(const Duration(seconds: 30));

      final responseData = json.decode(response.body);

      if (response.statusCode == 200 && responseData['success']) {
        return ChatResponse.success(
          message: responseData['response'],
          timestamp: DateTime.parse(responseData['timestamp']),
        );
      } else {
        return ChatResponse.error(
          error: responseData['error'] ?? 'Unknown error occurred',
        );
      }
    } on SocketException {
      return ChatResponse.error(
        error: 'No internet connection. Please check your network.',
      );
    } on http.ClientException {
      return ChatResponse.error(
        error: 'Connection failed. Please try again.',
      );
    } catch (e) {
      return ChatResponse.error(
        error: 'Something went wrong. Please try again.',
      );
    }
  }

  // Clear conversation history
  Future<bool> clearConversation() async {
    try {
      final response = await _client.post(
        Uri.parse('$_baseUrl$_clearEndpoint'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'conversation_id': conversationId,
        }),
      );

      final responseData = json.decode(response.body);
      return responseData['success'] ?? false;
    } catch (e) {
      return false;
    }
  }

  // Check if backend is healthy
  Future<bool> checkHealth() async {
    try {
      final response = await _client.get(
        Uri.parse('$_baseUrl$_healthEndpoint'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void dispose() {
    _client.close();
  }
}

// Response model
class ChatResponse {
  final bool isSuccess;
  final String? message;
  final String? error;
  final DateTime timestamp;

  ChatResponse._({
    required this.isSuccess,
    this.message,
    this.error,
    required this.timestamp,
  });

  factory ChatResponse.success({
    required String message,
    required DateTime timestamp,
  }) {
    return ChatResponse._(
      isSuccess: true,
      message: message,
      timestamp: timestamp,
    );
  }

  factory ChatResponse.error({
    required String error,
  }) {
    return ChatResponse._(
      isSuccess: false,
      error: error,
      timestamp: DateTime.now(),
    );
  }
}
