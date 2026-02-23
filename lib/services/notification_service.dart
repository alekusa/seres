import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // 1. Android Initialization Settings
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // 2. iOS Initialization Settings
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings:
          initSettings, // I'll try one more time as 'initializationSettings' but very carefully.
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Notification tapped: ${response.payload}');
      },
    );

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // 4. Handle Background/Terminated Messages Taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageTapped);

    // Create High Importance Channel for Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            'high_importance_channel', // id
            'High Importance Notifications', // title
            description:
                'This channel is used for important notifications.', // description
            importance: Importance.max,
          ),
        );

    _isInitialized = true;
    debugPrint('NotificationService inicializado');
  }

  Future<void> requestPermission() async {
    // Request FCM permissions
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('Permiso de notificaciones otorgado');
      // Get FCM Token with retry logic for iOS APNS token
      String? token;
      int retryCount = 0;
      const int maxRetries = 5;

      while (retryCount < maxRetries) {
        try {
          debugPrint(
            'Intentando obtener token FCM (intento ${retryCount + 1})...',
          );
          token = await _fcm.getToken();
          if (token != null) break;
        } catch (e) {
          if (e.toString().contains('apns-token-not-set')) {
            // APNS token not ready, waiting...
            retryCount++;
            debugPrint(
              'Token APNS no listo. Reintentando en ${2 * retryCount}s...',
            );
            await Future.delayed(Duration(seconds: 2 * retryCount));
          } else {
            // Other error getting FCM token
            break;
          }
        }
      }

      if (token != null) {
        debugPrint('FCM Token obtenido: $token');
        // FCM Token available
      } else {
        debugPrint(
          'No se pudo obtener el token de FCM tras $maxRetries reintentos.',
        );
      }
    } else if (settings.authorizationStatus ==
        AuthorizationStatus.provisional) {
      // User granted provisional permission
    } else {
      // User declined or has not accepted permission
      if (await Permission.notification.isPermanentlyDenied) {
        openAppSettings();
      }
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && android != null && !kIsWeb) {
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel', // id
            'High Importance Notifications', // name
            channelDescription:
                'This channel is used for important notifications.',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  void _handleMessageTapped(RemoteMessage message) {
    // Add navigation logic here if needed
  }
}
