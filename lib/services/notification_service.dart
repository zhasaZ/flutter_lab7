import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'registration_channel',
    'Регистрация',
    description: 'Уведомления о регистрации пользователя',
    importance: Importance.high,
  );

  Future<void> init() async {
    // 1. Разрешение на показ уведомлений
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // 2. Локальные уведомления
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await _local.initialize(initSettings);
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);

    // 3. Push-уведомление, пришедшее при открытом приложении
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final n = message.notification;
      if (n != null) {
        show(n.title ?? 'Уведомление', n.body ?? '');
      }
    });

    // 4. Нажатие на уведомление, когда приложение было в фоне
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Открыто из уведомления: ${message.messageId}');
    });

    debugPrint('FCM token: ${await getToken()}');
  }

  Future<String?> getToken() => _messaging.getToken();

  Future<void> show(String title, String body) async {
    await _local.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }
}
