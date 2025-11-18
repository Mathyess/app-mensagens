import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class LocalStorageService {
  static Database? _database;

  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  static Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'connect.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE pending_messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            content TEXT NOT NULL,
            message_type TEXT DEFAULT 'text',
            file_url TEXT,
            created_at TEXT NOT NULL,
            is_group INTEGER DEFAULT 0
          )
        ''');

        await db.execute('''
          CREATE TABLE cached_messages (
            id TEXT PRIMARY KEY,
            conversation_id TEXT NOT NULL,
            sender_id TEXT NOT NULL,
            sender_name TEXT NOT NULL,
            content TEXT NOT NULL,
            message_type TEXT DEFAULT 'text',
            file_url TEXT,
            is_favorite INTEGER DEFAULT 0,
            is_archived INTEGER DEFAULT 0,
            is_deleted INTEGER DEFAULT 0,
            is_edited INTEGER DEFAULT 0,
            edited_at TEXT,
            reactions TEXT,
            created_at TEXT NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_cached_messages_conversation 
          ON cached_messages(conversation_id)
        ''');
      },
    );
  }

  static Future<void> savePendingMessage({
    required String conversationId,
    required String content,
    String? fileUrl,
    String messageType = 'text',
    bool isGroup = false,
  }) async {
    final db = await database;
    final id = 'pending_${DateTime.now().millisecondsSinceEpoch}';
    
    await db.insert('pending_messages', {
      'id': id,
      'conversation_id': conversationId,
      'content': content,
      'message_type': messageType,
      'file_url': fileUrl,
      'created_at': DateTime.now().toIso8601String(),
      'is_group': isGroup ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingMessages() async {
    final db = await database;
    return await db.query('pending_messages', orderBy: 'created_at ASC');
  }

  static Future<void> removePendingMessage(String id) async {
    final db = await database;
    await db.delete('pending_messages', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> clearPendingMessages() async {
    final db = await database;
    await db.delete('pending_messages');
  }

  static Future<void> cacheMessages(String conversationId, List<Message> messages) async {
    final db = await database;
    
    await db.delete('cached_messages', where: 'conversation_id = ?', whereArgs: [conversationId]);
    
    final batch = db.batch();
    for (final message in messages) {
      batch.insert('cached_messages', {
        'id': message.id,
        'conversation_id': conversationId,
        'sender_id': message.senderId,
        'sender_name': message.senderName,
        'content': message.content,
        'message_type': message.imageUrl != null ? 'image' : 'text',
        'file_url': message.imageUrl,
        'is_favorite': message.isFavorite ? 1 : 0,
        'is_archived': message.isArchived ? 1 : 0,
        'is_deleted': message.isDeleted ? 1 : 0,
        'is_edited': message.isEdited ? 1 : 0,
        'edited_at': message.editedAt?.toIso8601String(),
        'reactions': message.reactions != null ? jsonEncode(message.reactions) : null,
        'created_at': message.createdAt.toIso8601String(),
      });
    }
    await batch.commit(noResult: true);
  }

  static Future<List<Message>> getCachedMessages(String conversationId) async {
    final db = await database;
    final results = await db.query(
      'cached_messages',
      where: 'conversation_id = ?',
      whereArgs: [conversationId],
      orderBy: 'created_at ASC',
    );

    return results.map((row) {
      Map<String, List<String>>? reactions;
      if (row['reactions'] != null) {
        try {
          final reactionsMap = jsonDecode(row['reactions'] as String) as Map;
          reactions = Map<String, List<String>>.from(
            reactionsMap.map(
              (key, value) => MapEntry(
                key.toString(),
                List<String>.from(value ?? []),
              ),
            ),
          );
        } catch (e) {
          reactions = null;
        }
      }

      return Message(
        id: row['id'] as String,
        content: row['content'] as String,
        senderId: row['sender_id'] as String,
        senderName: row['sender_name'] as String,
        createdAt: DateTime.parse(row['created_at'] as String),
        imageUrl: row['file_url'] as String?,
        isFavorite: (row['is_favorite'] as int) == 1,
        isArchived: (row['is_archived'] as int) == 1,
        isDeleted: (row['is_deleted'] as int) == 1,
        isEdited: (row['is_edited'] as int) == 1,
        editedAt: row['edited_at'] != null ? DateTime.parse(row['edited_at'] as String) : null,
        reactions: reactions,
      );
    }).toList();
  }

  static Future<void> clearCache() async {
    final db = await database;
    await db.delete('cached_messages');
  }
}





