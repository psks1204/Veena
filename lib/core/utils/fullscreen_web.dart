// Helper file for web fullscreen API  
// This uses JS interop to call browser fullscreen APIs
@JS()
library fullscreen_web;

import 'package:js/js.dart';

@JS('document.documentElement.requestFullscreen')
external void requestFullscreen();

@JS('document.exitFullscreen')
external void exitFullscreen();

@JS('document.fullscreenElement')
external dynamic get fullscreenElement;
