class MessageModel {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final int? tokenCount;

  MessageModel({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.tokenCount,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'tokenCount': tokenCount,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      text: json['text'],
      isUser: json['isUser'],
      timestamp: DateTime.parse(json['timestamp']),
      tokenCount: json['tokenCount'],
    );
  }

  factory MessageModel.fromDatabase(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      text: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
      tokenCount: map['token_count'],
    );
  }
}
