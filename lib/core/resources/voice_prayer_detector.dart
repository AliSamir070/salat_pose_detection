import 'dart:async';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/foundation.dart';

class VoicePrayerDetector {
  late stt.SpeechToText _speech;
  bool _isListening = false;

  // Callback now helps you count or log events
  Function(String)? onSujudDetected;

  // Prevent double-triggering for the same phrase
  DateTime? _lastDetectionTime;

  VoicePrayerDetector({this.onSujudDetected}) {
    _speech = stt.SpeechToText();
  }

  Future<void> initialize() async {
    bool available = await _speech.initialize(
      onStatus: _onStatusChange,
      onError: (error) {
        debugPrint('Voice Error: $error');
        // If error is permanent (like "no match"), try restarting after delay
        _restartListening();
      },
    );

    if (available) {
      startListening();
    }
  }

  void startListening() {
    if (_isListening) return;

    _speech.listen(
      localeId: "ar_SA",
      listenFor: const Duration(seconds: 60), // Max allowed by Android is usually ~1 min
      pauseFor: const Duration(seconds: 5),   // Wait for short silence
      partialResults: true,
      cancelOnError: false, // Keep trying even if it fails once
      onResult: (val) {
        if (val.recognizedWords.isNotEmpty) {
          _analyzeSpeech(val.recognizedWords);
        }
      },
    );
    _isListening = true;
    debugPrint("🎤 Mic Started");
  }

  // Continuously restart when the engine stops
  void _onStatusChange(String status) {
    debugPrint("🎤 Voice Status: $status");

    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      // Restart automatically to keep it "Continuous"
      _restartListening();
    }
  }

  void _restartListening() {
    // Small delay to prevent CPU loop crash if mic is broken
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_isListening) {
        startListening();
      }
    });
  }

  void _analyzeSpeech(String text) {
    // 1. Cooldown Check (Don't trigger twice in 2 seconds)
    if (_lastDetectionTime != null &&
        DateTime.now().difference(_lastDetectionTime!) < const Duration(seconds: 2)) {
      return;
    }

    String normalizedText = _normalizeArabic(text);

    // 2. Check for Sujud Keywords
    if (normalizedText.contains("سبحان") &&
        (normalizedText.contains("الاعلي") || normalizedText.contains("الاعلى"))) {

      debugPrint("✅ SUJUD DETECTED BY VOICE!");
      _lastDetectionTime = DateTime.now();
      onSujudDetected?.call("Sujud");

      // 3. IMPORTANT: Reset the engine so it forgets this phrase
      // and is ready for the NEXT Sujud.
      stop();
      Future.delayed(const Duration(seconds: 1), startListening);
    }
  }

  String _normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // Remove Tashkeel
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه');
  }

  void stop() {
    _speech.stop();
    _isListening = false;
  }
}