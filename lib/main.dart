import 'package:flutter/material.dart';
import 'package:divine_stream/app/app.bottomsheets.dart';
import 'package:divine_stream/app/app.dialogs.dart';
import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/app/app.router.dart';
import 'package:hive_flutter/adapters.dart';
import 'package:stacked_services/stacked_services.dart';

Future<void> main() async {

  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Hive and open the storage directory
  await Hive.initFlutter();

  // Open the box for storing playlists
  await Hive.openBox('playlistsBox');

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
