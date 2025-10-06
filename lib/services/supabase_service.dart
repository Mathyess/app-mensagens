import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user.dart' as app_models;

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Autenticação
  static Future<AuthResponse> signUp(String email, String password, String name) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  static Future<AuthResponse> signIn(String email, String password) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static User? get currentUser => _client.auth.currentUser;

  // Mensagens
  static Future<List<Message>> getMessages() async {
    final response = await _client
        .from('messages')
        .select('*, profiles(name)')
        .order('created_at', ascending: false)
        .limit(50);

    return response.map((json) => Message.fromJson(json)).toList();
  }

  static Future<void> sendMessage(String content) async {
    final user = currentUser;
    if (user == null) return;

    await _client.from('messages').insert({
      'content': content,
      'sender_id': user.id,
      'sender_name': user.userMetadata?['name'] ?? 'Usuário',
    });
  }

  // Stream de mensagens em tempo real
  static Stream<List<Message>> getMessagesStream() {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(50)
        .map((data) => data.map((json) => Message.fromJson(json)).toList());
  }
}
