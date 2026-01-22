import 'package:flutter/material.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class SujudHistoryDetector {
  late ObjectDetector _objectDetector;
  bool _isBusy = false;

  // --- HISTORY STATE ---
  double _lastCoverage = 0.0;
  int _framesWithoutObject = 0;
  bool _isSujudLocked = false; // "True" means we are currently in the 'Blocked/Sujud' state

  SujudHistoryDetector() {
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true,
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  /// Returns TRUE if currently in Sujud (based on current view OR history)
  Future<bool> checkSujud(InputImage inputImage) async {
    if (_isBusy) return _isSujudLocked; // Return last known state if busy
    _isBusy = true;

    try {
      final objects = await _objectDetector.processImage(inputImage);

      double screenArea = inputImage.metadata!.size.width * inputImage.metadata!.size.height;

      // CASE 1: Object is Visible
      if (objects.isNotEmpty) {
        _framesWithoutObject = 0; // Reset counter

        // Find largest object
        DetectedObject largest = objects.reduce((curr, next) =>
        curr.boundingBox.area > next.boundingBox.area ? curr : next
        );

        double objArea = largest.boundingBox.area;
        double currentCoverage = (screenArea == 0) ? 0 : (objArea / screenArea);

        // Update history
        _lastCoverage = currentCoverage;

        // LOGIC:
        // If coverage is huge (> 60%), we are definitely in/going to Sujud
        if (currentCoverage > 0.60) {
          _isSujudLocked = true;
          return true;
        }

        // If coverage is small (< 40%), we are definitely NOT in Sujud (Sitting/Standing)
        if (currentCoverage < 0.40) {
          _isSujudLocked = false;
          return false;
        }

        // Between 40-60%, keep the previous state (Transitioning)
        return _isSujudLocked;
      }

      // CASE 2: No Object Visible (The "Blind Spot")
      else {
        _framesWithoutObject++;

        // If we were ALREADY locked in Sujud, or the last thing we saw was HUGE,
        // assume we are still blocked by the body.
        if (_isSujudLocked || _lastCoverage > 0.50) {
          // We assume the object is still there, just too close to see.
          _isSujudLocked = true;
          return true;
        }

        // If we were Standing (small coverage) and now see nothing (ceiling),
        // we remain Standing.
        _isSujudLocked = false;
        return false;
      }

    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      _isBusy = false;
    }

    return _isSujudLocked;
  }

  void close() {
    _objectDetector.close();
  }
}

extension RectArea on Rect {
  double get area => width * height;
}