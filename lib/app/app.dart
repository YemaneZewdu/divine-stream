import 'package:divine_stream/ui/bottom_sheets/notice/notice_sheet.dart';
import 'package:divine_stream/ui/dialogs/info_alert/info_alert_dialog.dart';
import 'package:divine_stream/ui/views/home/home_view.dart';
import 'package:divine_stream/ui/views/startup/startup_view.dart';
import 'package:stacked/stacked_annotations.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:divine_stream/services/google_drive_service.dart';
import 'package:divine_stream/services/connectivity_service.dart';
import 'package:divine_stream/ui/views/playlist/playlist_view.dart';
import 'package:divine_stream/services/audio_player_service.dart';
import 'package:divine_stream/services/audio_handler_impl_service.dart';
// @stacked-import

@StackedApp(
  routes: [
    MaterialRoute(page: HomeView),
    MaterialRoute(page: StartupView),
    MaterialRoute(page: PlaylistView),
// @stacked-route
  ],
  dependencies: [
    LazySingleton(classType: BottomSheetService),
    LazySingleton(classType: DialogService),
    LazySingleton(classType: NavigationService),
    LazySingleton(classType: PlaylistService),
    LazySingleton(classType: GoogleDriveService),
    LazySingleton(classType: ConnectivityService),
    LazySingleton(classType: AudioPlayerService),
    LazySingleton(classType: AudioHandlerImplService),
// @stacked-service
  ],
  bottomsheets: [
    StackedBottomsheet(classType: NoticeSheet),
    // @stacked-bottom-sheet
  ],
  dialogs: [
    StackedDialog(classType: InfoAlertDialog),
    // @stacked-dialog
  ],
)
class App {}
