class ConversationModel {
  final String id;
  final String userId;
  final String chatbotId;
  final String title;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isArchived;
  final int messageCount;

  ConversationModel({
    required this.id,
    required this.userId,
    required this.chatbotId,
    required this.title,
    required this.createdAt,
    required this.updatedAt,
    this.isArchived = false,
    this.messageCount = 0,
  });

  factory ConversationModel.fromDatabase(Map<String, dynamic> map) {
    return ConversationModel(
      id: map['id'],
      userId: map['user_id'],
      chatbotId: map['chatbot_id'],
      title: map['title'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      isArchived: map['is_archived'] == 1,
      messageCount: map['message_count'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'chatbotId': chatbotId,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isArchived': isArchived,
      'messageCount': messageCount,
    };
  }
}
