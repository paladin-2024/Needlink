import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level handler required by FCM for background/killed state messages.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  // FCM handles display automatically in background/killed state.
  // Nothing to do here unless you need local processing.
}

class NotificationService {
  NotificationService._();

  static GoRouter? _router;
  static final _fln = FlutterLocalNotificationsPlugin();
  static const _channelId = 'needlink_high';
  static const _channelName = 'NeedLink Alerts';

  static void setRouter(GoRouter router) => _router = router;

  static Future<void> initialize() async {
    await _setupLocalNotifications();
    await _requestPermission();
    _listenForeground();
    _listenTaps();
    await _checkInitialMessage();
    _listenAuthForToken();
  }

  // ── Local notifications setup ─────────────────────────────────────────────

  static Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    await _fln.initialize(
      const InitializationSettings(android: androidInit),
      onDidReceiveNotificationResponse: (details) => _handlePayload(details.payload),
    );

    await _fln
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            _channelId,
            _channelName,
            importance: Importance.high,
            enableVibration: true,
          ),
        );
  }

  // ── Permission ────────────────────────────────────────────────────────────

  static Future<void> _requestPermission() async {
    final settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await saveToken();
    }
  }

  // ── Token management ──────────────────────────────────────────────────────

  static Future<void> saveToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await Supabase.instance.client.from('push_tokens').upsert(
      {
        'user_id': user.id,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'user_id, token',
    );

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final current = Supabase.instance.client.auth.currentUser;
      if (current == null) return;
      await Supabase.instance.client.from('push_tokens').upsert(
        {
          'user_id': current.id,
          'token': newToken,
          'platform': Platform.isAndroid ? 'android' : 'ios',
          'updated_at': DateTime.now().toIso8601String(),
        },
        onConflict: 'user_id, token',
      );
    });
  }

  // ── Foreground message display ────────────────────────────────────────────

  static void _listenForeground() {
    FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification == null) return;

      _fln.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            importance: Importance.high,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
        ),
        payload: _payloadFromData(message.data),
      );
    });
  }

  // ── Notification tap handling ─────────────────────────────────────────────

  static void _listenTaps() {
    // App opened from background via notification tap
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handlePayload(_payloadFromData(message.data));
    });
  }

  static Future<void> _checkInitialMessage() async {
    // App launched from terminated state via notification tap
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      _handlePayload(_payloadFromData(initial.data));
    }
  }

  static String? _payloadFromData(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final pledgeId = data['pledge_id'] as String?;
    if (type == null) return null;
    return pledgeId != null ? '$type:$pledgeId' : type;
  }

  static void _handlePayload(String? payload) {
    if (payload == null || _router == null) return;
    final parts = payload.split(':');
    final type = parts[0];
    final id = parts.length > 1 ? parts[1] : null;

    switch (type) {
      case 'new_pledge':
        _router!.go('/ngo/pledges');
      case 'pledge_confirmed':
        if (id != null) {
          _router!.go('/donor/tracking/$id');
        } else {
          _router!.go('/donor/tracking');
        }
      case 'pledge_rejected':
        _router!.go('/donor/pledges');
    }
  }

  // ── Auto-save token on sign-in ────────────────────────────────────────────

  static void _listenAuthForToken() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedIn) {
        saveToken();
      }
    });
  }
}
