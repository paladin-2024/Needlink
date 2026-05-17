import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'env.dart';
import 'firebase_options.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );

  runApp(const ProviderScope(child: NeedLinkApp()));
}

class NeedLinkApp extends ConsumerWidget {
  const NeedLinkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    NotificationService.setRouter(router);
    return MaterialApp.router(
      title: 'NeedLink',
      theme: needLinkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Initialize notifications after the widget tree is built so
        // permission dialogs have a valid context.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          NotificationService.initialize();
        });
        return child!;
      },
    );
  }
}
