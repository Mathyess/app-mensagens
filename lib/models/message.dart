class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final String? imageUrl;
  final bool isFavorite;
  final bool isArchived;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.imageUrl,
    this.isFavorite = false,
    this.isArchived = false,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'],
      isFavorite: json['is_favorite'] ?? false,
      isArchived: json['is_archived'] ?? false,
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
    );
  }
}
