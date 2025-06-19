import 'package:flutter/material.dart';

class ChatbotModel {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final String apiType;

  const ChatbotModel({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.apiType,
  });
}
