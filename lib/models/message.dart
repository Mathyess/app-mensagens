class Message {
  final String id;
  final String content;
  final String senderId;
  final String senderName;
  final DateTime createdAt;
  final String? imageUrl;

  Message({
    required this.id,
    required this.content,
    required this.senderId,
    required this.senderName,
    required this.createdAt,
    this.imageUrl,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'],
      content: json['content'],
      senderId: json['sender_id'],
      senderName: json['sender_name'],
      createdAt: DateTime.parse(json['created_at']),
      imageUrl: json['image_url'],
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
    };
  }
}
