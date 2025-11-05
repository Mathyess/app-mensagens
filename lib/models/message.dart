class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isFavorite;
  final bool isArchived;
  final bool isDeleted;
  final bool isDeletedForEveryone; // Nova propriedade para deletar para todos
  final bool isEdited;
  final DateTime? editedAt;
  final Map<String, List<String>>? reactions; // emoji -> lista de user_ids

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.imageUrl,
    this.isFavorite = false,
    this.isArchived = false,
    this.isDeleted = false,
    this.isDeletedForEveryone = false,
    this.isEdited = false,
    this.editedAt,
    this.reactions,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    // Parse reactions if they exist
    Map<String, List<String>>? reactions;
    if (json['reactions'] != null) {
      if (json['reactions'] is Map) {
        reactions = Map<String, List<String>>.from(
          (json['reactions'] as Map).map(
            (key, value) => MapEntry(
              key.toString(),
              List<String>.from(value ?? []),
            ),
          ),
        );
      }
    }

    // Converter data UTC para fuso horário local
    final createdAtUtc = DateTime.parse(json['created_at']);
    final createdAt = createdAtUtc.isUtc 
        ? createdAtUtc.toLocal() 
        : createdAtUtc;
    
    DateTime? editedAt;
    if (json['edited_at'] != null) {
      final editedAtUtc = DateTime.parse(json['edited_at']);
      editedAt = editedAtUtc.isUtc 
          ? editedAtUtc.toLocal() 
          : editedAtUtc;
    }
    
    return Message(
      id: json['id'],
      content: json['content'] ?? '',
      senderId: json['sender_id'],
      senderName: json['sender_name'] ?? 'Usuário',
      createdAt: createdAt,
      imageUrl: json['image_url'] ?? json['file_url'],
      isFavorite: json['is_favorite'] ?? false,
      isArchived: json['is_archived'] ?? false,
      isDeleted: json['is_deleted'] ?? false,
      isDeletedForEveryone: json['is_deleted_for_everyone'] ?? false,
      isEdited: json['is_edited'] ?? false,
      editedAt: editedAt,
      reactions: reactions,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender_id': senderId,
      'sender_name': senderName,
      'created_at': createdAt.toIso8601String(),
      'image_url': imageUrl,
      'is_favorite': isFavorite,
      'is_archived': isArchived,
      'is_deleted': isDeleted,
      'is_deleted_for_everyone': isDeletedForEveryone,
      'is_edited': isEdited,
      'edited_at': editedAt?.toIso8601String(),
      'reactions': reactions,
    };
  }

  Message copyWith({
    String? id,
    String? content,
    String? senderId,
    String? senderName,
    DateTime? createdAt,
    String? imageUrl,
    bool? isFavorite,
    bool? isArchived,
    bool? isDeleted,
    bool? isDeletedForEveryone,
    bool? isEdited,
    DateTime? editedAt,
    Map<String, List<String>>? reactions,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      createdAt: createdAt ?? this.createdAt,
      imageUrl: imageUrl ?? this.imageUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
      isDeletedForEveryone: isDeletedForEveryone ?? this.isDeletedForEveryone,
      isEdited: isEdited ?? this.isEdited,
      editedAt: editedAt ?? this.editedAt,
      reactions: reactions ?? this.reactions,
    );
  }

  // Verifica se a mensagem pode ser editada (até 15 minutos)
  bool canBeEdited() {
    if (isDeleted || isDeletedForEveryone) return false;
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    return difference.inMinutes <= 15;
  }
}
