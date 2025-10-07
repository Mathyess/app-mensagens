import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/message.dart';
import '../models/user.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Autenticação
  static Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
    );

    // Create profile after successful signup
    if (response.user != null) {
      await _client.from('profiles').insert({
        'id': response.user!.id,
        'name': name,
      });
    }

    return response;
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

  static Future<AppUser?> getCurrentUserProfile() async {
    final user = currentUser;
    if (user == null) return null;

    final response = await _client
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    return AppUser.fromJson({
      ...response,
      'email': user.email ?? '',
    });
  }

  // Mensagens
  static Future<List<Message>> getMessages() async {
    final response = await _client
        .from('messages')
        .select()
        .order('created_at', ascending: false)
        .limit(50);

    return (response as List).map((json) => Message.fromJson(json)).toList();
  }

  static Future<void> sendMessage(String content, {String? imageUrl}) async {
    final user = currentUser;
    if (user == null) return;

    final profile = await getCurrentUserProfile();
    final senderName = profile?.name ?? 'Usuário';

    await _client.from('messages').insert({
      'content': content,
      'sender_id': user.id,
      'sender_name': senderName,
      'image_url': imageUrl,
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

  static Future<void> updateProfile({String? name, String? avatarUrl}) async {
    final user = currentUser;
    if (user == null) return;

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

    await _client
        .from('profiles')
        .update(updates)
        .eq('id', user.id);
  }
}
