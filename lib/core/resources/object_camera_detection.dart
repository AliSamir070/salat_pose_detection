import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';

class CameraBlockageDetector {

  bool isCameraBlocked(CameraImage rawImage) {
    return _isLensObstructed(rawImage);
  }

  bool _isLensObstructed(CameraImage image) {
    final bytes = image.planes[0].bytes;

    int totalBrightness = 0;
    int sumSquares = 0;
    int sampleCount = 0;

    // Track limits to find "Hot Spots" (Lights)
    int maxBrightness = 0;
    int minBrightness = 255;

    // Check every 50th pixel for speed
    int step = Platform.isAndroid ? 50 : 200;

    for (int i = 0; i < bytes.length; i += step) {
      int val = bytes[i];
      totalBrightness += val;
      sumSquares += (val * val);
      sampleCount++;

      if (val > maxBrightness) maxBrightness = val;
      if (val < minBrightness) minBrightness = val;
    }

    if (sampleCount == 0) return false;

    double avgBrightness = totalBrightness / sampleCount;
    double variance = (sumSquares / sampleCount) - (avgBrightness * avgBrightness);

    // DEBUG: Tune these values based on your logs!
    // debugPrint("📸 RAW: Avg=${avgBrightness.toInt()} | Var=${variance.toInt()} | Max=${maxBrightness}");

    // --- DETECTION LOGIC ---

    // 1. DARKNESS (Phone on floor/carpet)
    // Raised to 100 to catch partial shadows
    bool isDark = avgBrightness < 100;

    // 2. BLUR / FLAT (Finger/Skin on lens)
    // A surface right against the lens is usually low variance
    bool isBlurry = variance < 800;

    // 3. DIFFUSED BODY BLOCKAGE (The "Not Near" Sujud Case)
    // Logic: If the body blocks the ceiling, we lose the "Ceiling Lights".
    // A clear ceiling usually has 'maxBrightness' near 255 (lights).
    // A body (even white clothes) usually has 'maxBrightness' lower (shadowed).

    bool hasNoDirectLights = maxBrightness < 200; // No super bright lights visible
    bool isMidBrightness = avgBrightness < 180;   // Not outdoor-bright
    bool isNotHighContrast = variance < 1500;     // Not a complex ceiling pattern

    // If it's somewhat dim, has no lights, and isn't super chaotic -> Likely Body
    bool isBodyBlocking = hasNoDirectLights && isMidBrightness && isNotHighContrast;

    if (isDark || isBlurry || isBodyBlocking) {
      return true;
    }

    return false;
  }
}