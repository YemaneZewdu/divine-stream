import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:divine_stream/app/app.locator.dart';
import 'package:stacked_services/stacked_services.dart';
import 'package:divine_stream/services/playlist_service.dart';
import 'package:divine_stream/services/google_drive_service.dart';
import 'package:divine_stream/services/audio_player_service.dart';
import 'package:divine_stream/services/audio_handler_impl_service.dart';
// @stacked-import

import 'test_helpers.mocks.dart';

@GenerateMocks([], customMocks: [
  MockSpec<NavigationService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<BottomSheetService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<DialogService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<PlaylistService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<GoogleDriveService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<AudioPlayerService>(onMissingStub: OnMissingStub.returnDefault),
  MockSpec<AudioHandlerImplService>(onMissingStub: OnMissingStub.returnDefault),
// @stacked-mock-spec
])
void registerServices() {
  getAndRegisterNavigationService();
  getAndRegisterBottomSheetService();
  getAndRegisterDialogService();
  //getAndRegisterPlaylistService();
  getAndRegisterGoogleDriveService();
  getAndRegisterAudioPlayerService();
  getAndRegisterAudioHandlerImplService();
// @stacked-mock-register
}

MockNavigationService getAndRegisterNavigationService() {
  _removeRegistrationIfExists<NavigationService>();
  final service = MockNavigationService();
  locator.registerSingleton<NavigationService>(service);
  return service;
}

MockBottomSheetService getAndRegisterBottomSheetService<T>({
  SheetResponse<T>? showCustomSheetResponse,
}) {
  _removeRegistrationIfExists<BottomSheetService>();
  final service = MockBottomSheetService();

  when(service.showCustomSheet<T, T>(
    enableDrag: anyNamed('enableDrag'),
    enterBottomSheetDuration: anyNamed('enterBottomSheetDuration'),
    exitBottomSheetDuration: anyNamed('exitBottomSheetDuration'),
    ignoreSafeArea: anyNamed('ignoreSafeArea'),
    isScrollControlled: anyNamed('isScrollControlled'),
    barrierDismissible: anyNamed('barrierDismissible'),
    additionalButtonTitle: anyNamed('additionalButtonTitle'),
    variant: anyNamed('variant'),
    title: anyNamed('title'),
    hasImage: anyNamed('hasImage'),
    imageUrl: anyNamed('imageUrl'),
    showIconInMainButton: anyNamed('showIconInMainButton'),
    mainButtonTitle: anyNamed('mainButtonTitle'),
    showIconInSecondaryButton: anyNamed('showIconInSecondaryButton'),
    secondaryButtonTitle: anyNamed('secondaryButtonTitle'),
    showIconInAdditionalButton: anyNamed('showIconInAdditionalButton'),
    takesInput: anyNamed('takesInput'),
    barrierColor: anyNamed('barrierColor'),
    barrierLabel: anyNamed('barrierLabel'),
    customData: anyNamed('customData'),
    data: anyNamed('data'),
    description: anyNamed('description'),
  )).thenAnswer((realInvocation) =>
      Future.value(showCustomSheetResponse ?? SheetResponse<T>()));

  locator.registerSingleton<BottomSheetService>(service);
  return service;
}

MockDialogService getAndRegisterDialogService() {
  _removeRegistrationIfExists<DialogService>();
  final service = MockDialogService();
  locator.registerSingleton<DialogService>(service);
  return service;
}

// MockPlaylistServiceService getAndRegisterPlaylistServiceService() {
//   _removeRegistrationIfExists<PlaylistService>();
//   final service = MockPlaylistServiceService();
//   locator.registerSingleton<PlaylistService>(service as PlaylistService);
//   return service;
// }

MockGoogleDriveService getAndRegisterGoogleDriveService() {
  _removeRegistrationIfExists<GoogleDriveService>();
  final service = MockGoogleDriveService();
  locator.registerSingleton<GoogleDriveService>(service);
  return service;
}

MockAudioPlayerService getAndRegisterAudioPlayerService() {
  _removeRegistrationIfExists<AudioPlayerService>();
  final service = MockAudioPlayerService();
  locator.registerSingleton<AudioPlayerService>(service);
  return service;
}

MockAudioHandlerImplService getAndRegisterAudioHandlerImplService() {
  _removeRegistrationIfExists<AudioHandlerImplService>();
  final service = MockAudioHandlerImplService();
  locator.registerSingleton<AudioHandlerImplService>(service);
  return service;
}
// @stacked-mock-create

void _removeRegistrationIfExists<T extends Object>() {
  if (locator.isRegistered<T>()) {
    locator.unregister<T>();
  }
}
