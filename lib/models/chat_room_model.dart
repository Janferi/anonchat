import 'package:flutter/material.dart';

class ChatRoomModel {
  final String id;
  final String name;
  final int memberCount;
  final double distance; // in meters
  final double lat;
  final double lon;
  final bool isSystem;
  final Color? themeColor;

  ChatRoomModel({
    required this.id,
    required this.name,
    required this.memberCount,
    required this.distance,
    required this.lat,
    required this.lon,
    this.isSystem = false,
    this.themeColor,
  });
}
