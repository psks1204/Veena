// Stub implementation of RecordLinux.
// This package exists solely to satisfy the Dart compiler when building
// for Android/iOS/Web. None of these methods are ever called at runtime.

import 'package:record_platform_interface/record_platform_interface.dart';

class RecordLinux extends RecordPlatform {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnsupportedError('Recording is not supported on Linux');
}
