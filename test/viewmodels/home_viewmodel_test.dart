import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:divine_stream/app/app.bottomsheets.dart';
import 'package:divine_stream/app/app.locator.dart';
import 'package:divine_stream/ui/common/app_strings.dart';
import 'package:divine_stream/ui/views/home/home_viewmodel.dart';

import '../helpers/test_helpers.dart';

void main() {
  HomeViewModel getModel() => HomeViewModel();

  group('HomeViewmodelTest -', () {
    setUp(() => registerServices());
    tearDown(() => locator.reset());
  });
}
