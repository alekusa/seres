import 'package:SERES/Provider/favorite_provider.dart';
import 'package:SERES/Provider/quantity.dart';
import 'package:SERES/Provider/user_provider.dart'; // Added
import 'package:SERES/views/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:SERES/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'package:SERES/views/app_main_screen.dart';
import 'package:flutter/material.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  try {
    debugPrint('Iniciando inicialización de la app...');
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('WidgetsFlutterBinding inicializado');

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase inicializado correctamente');

    // Set background messaging handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialize Notification Service
    await NotificationService().initialize();

    // Disable App Verification for testing (solves some simulator issues)
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
    debugPrint('Configuración de FirebaseAuth actualizada');

    runApp(const MyApp());
    debugPrint('App lanzada (runApp)');
  } catch (e, stack) {
    debugPrint('ERROR CRÍTICO EN MAIN: $e');
    debugPrint('STACK TRACE: $stack');
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => QuantityProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus?.unfocus();
          }
        },
        child: MaterialApp(
          title: 'SERES',
          debugShowCheckedModeBanner: false,
          home: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              // Show loading indicator while checking auth state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              // Show LoginScreen if user is not authenticated
              if (snapshot.data == null) {
                return const LoginScreen();
              }

              // Show main app if user is authenticated
              return const AppMainScreen();
            },
          ),
        ),
      ),
    );
  }
}
