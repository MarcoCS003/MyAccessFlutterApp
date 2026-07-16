import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../models/notification_item.dart';

final notificationProvider =
    StateNotifierProvider<NotificationNotifier, List<NotificationItem>>((ref) {
      return NotificationNotifier();
    });

class NotificationNotifier extends StateNotifier<List<NotificationItem>> {
  NotificationNotifier() : super([]) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    try {
      final box = Hive.box(AppConstants.notificationsBox);
      final items = box.get('items', defaultValue: <Map<dynamic, dynamic>>[]);
      state = (items as List)
          .map((e) => NotificationItem.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      debugPrint('Error loading notifications from Hive: $e');
      state = [];
    }
  }

  Future<void> addFromFcm(Map<String, dynamic> data) async {
    final notification = NotificationItem.fromFcm(data);
    state = [notification, ...state];
    await _saveToHive();
  }

  Future<void> addNotification(NotificationItem notification) async {
    state = [notification, ...state];
    await _saveToHive();
  }

  Future<void> markAsRead(String id) async {
    state = state
        .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
        .toList();
    await _saveToHive();
  }

  Future<void> markAllAsRead() async {
    state = state.map((n) => n.copyWith(isRead: true)).toList();
    await _saveToHive();
  }

  Future<void> dismiss(String id) async {
    state = state.where((n) => n.id != id).toList();
    await _saveToHive();
  }

  Future<void> clearAll() async {
    state = [];
    await _saveToHive();
  }

  Future<void> _saveToHive() async {
    try {
      final box = Hive.box(AppConstants.notificationsBox);
      await box.put('items', state.map((n) => n.toJson()).toList());
    } catch (e) {
      debugPrint('Error saving notifications to Hive: $e');
    }
  }

  int get unreadCount => state.where((n) => !n.isRead).length;
}
