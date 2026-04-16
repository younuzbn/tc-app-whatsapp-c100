import 'package:flutter/material.dart';

class GameChatData {
  const GameChatData({
    required this.name,
    required this.timeSlot,
    required this.snippet,
    required this.time,
    required this.avatarText,
    required this.avatarColor,
    required this.closeLabel,
    this.unread,
  });

  final String name;
  final String timeSlot;
  final String snippet;
  final String time;
  final String avatarText;
  final Color avatarColor;
  final String closeLabel;
  final int? unread;
}

const List<GameChatData> gameChats = [
  GameChatData(
    name: 'DEAR 1PM',
    timeSlot: '1pm',
    snippet: 'Tap to play / view ledger',
    time: '1:00 PM',
    avatarText: '1',
    avatarColor: Color(0xFF77C34F),
    closeLabel: 'Closes at 1:00 PM',
    unread: 1,
  ),
  GameChatData(
    name: 'KERALA 3PM',
    timeSlot: '3pm',
    snippet: 'Tap to play / view ledger',
    time: '3:00 PM',
    avatarText: '3',
    avatarColor: Color(0xFFFFC83D),
    closeLabel: 'Closes at 3:00 PM',
    unread: 1,
  ),
  GameChatData(
    name: 'DEAR 6PM',
    timeSlot: '6pm',
    snippet: 'Tap to play / view ledger',
    time: '6:00 PM',
    avatarText: '6',
    avatarColor: Color(0xFFF89A2C),
    closeLabel: 'Closes at 6:00 PM',
    unread: 1,
  ),
  GameChatData(
    name: 'DEAR 8PM',
    timeSlot: '8pm',
    snippet: 'Tap to play / view ledger',
    time: '8:00 PM',
    avatarText: '8',
    avatarColor: Color(0xFFE85A4F),
    closeLabel: 'Closes at 8:00 PM',
    unread: 1,
  ),
];
