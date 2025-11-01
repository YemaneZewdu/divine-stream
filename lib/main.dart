import 'package:audio_service/audio_service.dart';
import 'package:divine_stream/services/audio_handler_impl_service.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:divine_stream/app/app.bottomsheets.dart';
import 'package:divine_stream/app/app.dialogs.dart';
import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
    // await dotenv.load(fileName: ".env");

  // Firebase is used for playlist manifests and
  // needs to be ready before the app runs.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive and open the storage directory
  await Hive.initFlutter();

  // Open the box for storing playlists
  await Hive.openBox('playlistsBox');

  // Init AudioService (background playback and lock screen control)
  final handler = await AudioService.init(
    builder: () => AudioHandlerImplService(),
    config: AudioServiceConfig(
      androidNotificationChannelId: 'com.audio_streaming_app.channel.audio',
      androidNotificationChannelName: 'Audio Playback',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      preloadArtwork: true,
    ),
  );

  // Register manually before other services
  locator.registerSingleton<AudioHandler>(handler);

  await setupLocator();
  setupDialogUi();
  setupBottomSheetUi();
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Routes.startupView,
      onGenerateRoute: StackedRouter().onGenerateRoute,
      navigatorKey: StackedService.navigatorKey,
      navigatorObservers: [
        StackedService.routeObserver,
      ],
    );
  }
}
