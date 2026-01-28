import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import 'audio_handler.dart';

/// Singleton manager for AudioService
/// 
/// Ensures AudioService.init() is called exactly once and provides
/// cached handler to all consumers.
class AudioServiceManager {
  static AudioServiceManager? _instance;
  static final Completer<VeenaAudioHandler> _handlerCompleter = Completer();
  
  VeenaAudioHandler? _handler;
  bool _isInitializing = false;
  
  AudioServiceManager._();
  
  static AudioServiceManager get instance {
    _instance ??= AudioServiceManager._();
    return _instance!;
  }
  
  /// Get the audio handler, initializing if necessary
  Future<VeenaAudioHandler?> getHandler() async {
    // If already initialized, return cached handler
    if (_handler != null) {
      return _handler;
    }
    
    // If initialization in progress, wait for it
    if (_isInitializing) {
      return await _handlerCompleter.future;
    }
    
    // Start initialization
    _isInitializing = true;
    
    try {
      debugPrint('[AudioServiceManager] Initializing AudioService...');
      
      final handler = await AudioService.init(
        builder: () => VeenaAudioHandler(),
        config: const AudioServiceConfig(
          androidNotificationChannelId: 'com.veena.app.channel.audio',
          androidNotificationChannelName: 'Veena Music',
          androidNotificationOngoing: true,
        ),
      );
      
      _handler = handler;
      if (!_handlerCompleter.isCompleted) {
        _handlerCompleter.complete(handler);
      }
      
      debugPrint('[AudioServiceManager] AudioService initialized successfully');
      return handler;
    } catch (e, stackTrace) {
      debugPrint('[AudioServiceManager] Error initializing AudioService: $e');
      debugPrint('[AudioServiceManager] Stack trace: $stackTrace');
      if (!_handlerCompleter.isCompleted) {
        _handlerCompleter.completeError(e);
      }
      _isInitializing = false;
      return null;
    }
  }
  
  /// Check if handler is ready
  bool get isReady => _handler != null;
}
