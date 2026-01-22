import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceProximityDetector {
  late FaceDetector _faceDetector;

  FaceProximityDetector() {
    // CRITICAL SETTINGS for "Half Face" detection:
    // 1. 'accurate': better at finding rotated/partial faces.
    // 2. 'minFaceSize': 0.3 means "ignore small faces in background".
    //    We only care about BIG faces near the camera.
    final options = FaceDetectorOptions(
      enableLandmarks: false,
      enableTracking: false,
      performanceMode: FaceDetectorMode.accurate,
      minFaceSize: 0.3,
    );
    _faceDetector = FaceDetector(options: options);
  }

  /// Returns [true] if a face is detected and it implies "Sujud" proximity
  Future<bool?> isFaceTooClose(InputImage inputImage) async {
    int _frameCounter = 0;
    _frameCounter++;
    if (_frameCounter % 5 != 0) return null;
    try {
      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) return false;

      final double screenWidth = inputImage.metadata!.size.width;
      final double screenHeight = inputImage.metadata!.size.height;
      final double screenArea = screenWidth * screenHeight;

      for (Face face in faces) {
        // LOGIC 1: Face Width Ratio
        // If the face width is > 60% of the screen width, it's very close.
        double widthRatio = face.boundingBox.width / screenWidth;

        // LOGIC 2: "Half Face" / Clipping Check
        // If the bounding box goes OUTSIDE the screen (negative coordinates),
        // it means the face is so close it doesn't fit in the frame.
        bool isClippingEdges =
            face.boundingBox.left < 0 ||
                face.boundingBox.top < 0 ||
                face.boundingBox.right > screenWidth ||
                face.boundingBox.bottom > screenHeight;

        // LOGIC 3: Area Ratio
        double faceArea = face.boundingBox.width * face.boundingBox.height;
        double areaRatio = faceArea / screenArea;
        debugPrint("Face area: $faceArea");
        debugPrint("area ratio: $areaRatio");
        debugPrint("isClip: $isClippingEdges");
        debugPrint("face width ratio: $widthRatio");
        // --- SUJUD DECISION ---
        // If face is Huge (> 60% width) OR (Large > 40% AND Cut off by edges)
        if (widthRatio > 0.60 || (areaRatio > 0.40 && isClippingEdges)) {
          // debugPrint("Face Close! Width: ${widthRatio.toStringAsFixed(2)}, Clipping: $isClippingEdges");
          return true;
        }
      }

    } catch (e) {
      debugPrint("Face error: $e");
    }

    return false;
  }

  void close() {
    _faceDetector.close();
  }
}