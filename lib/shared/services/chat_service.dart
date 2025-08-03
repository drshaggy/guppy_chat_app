import 'package:dio/dio.dart';
import 'package:guppy_chat_app/shared/models/chat_message.dart';

class ChatService {
  final Dio _dio;
  
  ChatService({Dio? dio}) : _dio = dio ?? Dio() {
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          handler.next(options);
        },
        onError: (error, handler) {
          // Log error in debug mode only
          assert(() {
            print('Chat API Error: ${error.message}');
            return true;
          }());
          handler.next(error);
        },
      ),
    );
  }

  Future<ChatMessage> sendMessage({
    required String message,
    required String conversationId,
    String? baseUrl,
  }) async {
    try {
      final url = baseUrl ?? 'https://n8n.percy.network/webhook/e4cfbbff-9901-4331-82db-c2cf466bd7ce/chat';
      
      final response = await _dio.post(
        url,
        data: {
          'chatInput': message,
          'sessionId': conversationId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        // Handle the response format
        final responseData = response.data as Map<String, dynamic>;
        
        // Check for direct output field first
        if (responseData.containsKey('output')) {
          final content = responseData['output'] ?? '';
          
          return ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: content,
            role: MessageRole.assistant,
            timestamp: DateTime.now(),
            status: MessageStatus.sent,
          );
        }
        
        // Check if the server returned a workflow error
        if (responseData['message'] == 'Error in workflow') {
          throw Exception('The AI service is currently experiencing issues. Please try again later.');
        }
        
        return ChatMessage(
          id: responseData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
          content: responseData['response'] ?? responseData['message'] ?? '',
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          status: MessageStatus.sent,
          metadata: responseData['metadata'],
        );
      } else {
        throw Exception('Invalid response from server');
      }
    } on DioException catch (e) {
      // Log error in debug mode only
      assert(() {
        print('Dio error: ${e.message}');
        return true;
      }());
      throw _handleDioError(e);
    } catch (e) {
      assert(() {
        print('Unexpected error: $e');
        return true;
      }());
      throw Exception('Failed to send message: $e');
    }
  }

  Future<List<ChatMessage>> getConversationHistory(String conversationId) async {
    try {
      final response = await _dio.get('/conversations/$conversationId/messages');
      
      if (response.statusCode == 200 && response.data != null) {
        final List<dynamic> messagesData = response.data as List<dynamic>;
        return messagesData
            .map((data) => ChatMessage.fromJson(data as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception('Failed to load conversation history');
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      throw Exception('Failed to load conversation history: $e');
    }
  }

  Future<bool> testConnection({String? baseUrl}) async {
    try {
      final url = baseUrl ?? 'https://n8n.percy.network/webhook/e4cfbbff-9901-4331-82db-c2cf466bd7ce/chat';
      final response = await _dio.get(url);
      return response.statusCode == 200;
    } catch (e) {
      assert(() {
        print('Connection test failed: $e');
        return true;
      }());
      return false;
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timeout. Please check your internet connection.');
      case DioExceptionType.connectionError:
        return Exception('Network error. Please check your connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final responseData = e.response?.data;
        
        // Check for specific workflow error message in various formats
        if (responseData != null) {
          String? errorMessage;
          if (responseData is Map<String, dynamic>) {
            errorMessage = responseData['message'];
          } else if (responseData is String && responseData.contains('Error in workflow')) {
            errorMessage = 'Error in workflow';
          }
          
          if (errorMessage == 'Error in workflow') {
            return Exception('The AI service is currently experiencing issues. Please try again later.');
          }
        }
        
        if (statusCode == 401) {
          return Exception('Authentication failed. Please check your API key.');
        } else if (statusCode == 404) {
          return Exception('AI service unavailable. The n8n workflow is not active.');
        } else if (statusCode == 429) {
          return Exception('Rate limit exceeded. Please try again later.');
        } else if (statusCode == 500) {
          return Exception('The AI service is currently experiencing issues. Please try again later.');
        }
        return Exception('Server responded with error: $statusCode');
      case DioExceptionType.cancel:
        return Exception('Request was cancelled.');
      case DioExceptionType.unknown:
      default:
        return Exception('An unexpected error occurred: ${e.message}');
    }
  }

  void dispose() {
    _dio.close();
  }
}