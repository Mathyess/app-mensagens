import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class GroupService {
  static final SupabaseClient _client = Supabase.instance.client;
  static const String _conversationsTable = 'conversations';
  static const String _participantsTable = 'conversation_participants';
  static const String _messagesTable = 'messages';

  /// Creates a new group conversation
  static Future<String> createGroup(
    String name, 
    List<String> participantIds, {
    bool isPublic = false,
  }) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      // Start a transaction
      return await _client.rpc('create_group_conversation', params: {
        'group_name': name,
        'is_public': isPublic,
        'user_ids': participantIds,
        'created_by_user_id': currentUserId,
      });
    } catch (e) {
      throw Exception('Failed to create group: $e');
    }
  }

  /// Gets detailed information about a group
  static Future<Map<String, dynamic>> getGroupInfo(String groupId) async {
    try {
      // Get group details
      final groupData = await _client
          .from(_conversationsTable)
          .select('*')
          .eq('id', groupId)
          .single();

      // Get participants
      final participants = await _client
          .from(_participantsTable)
          .select('''
            user_id,
            profiles:profiles(id, name, email, avatar_url),
            joined_at,
            left_at
          ''')
          .eq('conversation_id', groupId)
          .isFilter('left_at', null);

      // Get message count
      final messageCountResponse = await _client
          .from(_messagesTable)
          .select('id')
          .eq('conversation_id', groupId)
          .eq('is_deleted', false);
      
      final messageCount = messageCountResponse.length;

      return {
        ...groupData,
        'participants': participants,
        'message_count': messageCount,
      };
    } catch (e) {
      throw Exception('Failed to get group info: $e');
    }
  }

  /// Updates group information
  static Future<void> updateGroupInfo(
    String groupId, {
    String? name,
    bool? isPublic,
  }) async {
    try {
      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (isPublic != null) updates['is_public'] = isPublic;
      
      if (updates.isNotEmpty) {
        await _client
            .from(_conversationsTable)
            .update(updates)
            .eq('id', groupId);
      }
    } catch (e) {
      throw Exception('Failed to update group: $e');
    }
  }

  /// Adds participants to a group
  static Future<void> addGroupParticipants(
    String groupId, 
    List<String> userIds,
  ) async {
    try {
      await _client.rpc('add_group_participants', params: {
        'group_id': groupId,
        'user_ids': userIds,
      });
    } catch (e) {
      throw Exception('Failed to add participants: $e');
    }
  }

  /// Removes a participant from a group
  static Future<void> removeGroupParticipant(
    String groupId, 
    String userId,
  ) async {
    try {
      await _client.rpc('remove_group_participant', params: {
        'group_id': groupId,
        'user_id_to_remove': userId,
      });
    } catch (e) {
      throw Exception('Failed to remove participant: $e');
    }
  }

  /// Makes a user leave a group
  static Future<void> leaveGroup(String groupId) async {
    try {
      final currentUserId = _client.auth.currentUser?.id;
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }
      
      await _client.rpc('remove_group_participant', params: {
        'group_id': groupId,
        'user_id_to_remove': currentUserId,
      });
    } catch (e) {
      throw Exception('Failed to leave group: $e');
    }
  }

  /// Deletes a group (admin only)
  static Future<void> deleteGroup(String groupId) async {
    try {
      await _client.from(_conversationsTable).delete().eq('id', groupId);
    } catch (e) {
      throw Exception('Failed to delete group: $e');
    }
  }

  /// Gets a list of groups the current user is a member of
  static Future<List<Map<String, dynamic>>> getUserGroups() async {
    try {
      final response = await _client.rpc('get_user_groups');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to get user groups: $e');
    }
  }

  /// Searches for public groups
  static Future<List<Map<String, dynamic>>> searchPublicGroups(String query) async {
    try {
      final response = await _client.rpc('search_public_groups', params: {
        'search_term': query,
      });
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search groups: $e');
    }
  }

  /// Gets the message retention stats for a conversation
  static Future<Map<String, dynamic>> getMessageRetentionStats(String conversationId) async {
    try {
      final response = await _client.rpc('get_conversation_retention_stats', params: {
        'conversation_id_param': conversationId,
      });
      return response[0]; // Return first row
    } catch (e) {
      throw Exception('Failed to get retention stats: $e');
    }
  }

  /// Manually triggers message archiving for a conversation
  static Future<Map<String, dynamic>> triggerMessageArchiving(String conversationId) async {
    try {
      final response = await _client.rpc('trigger_message_archiving');
      return response;
    } catch (e) {
      throw Exception('Failed to trigger message archiving: $e');
    }
  }

  /// Gets a list of users matching the search query
  static Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final response = await _client
          .from('profiles')
          .select('*')
          .or('name.ilike.%$query%,email.ilike.%$query%')
          .limit(50);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }
}
