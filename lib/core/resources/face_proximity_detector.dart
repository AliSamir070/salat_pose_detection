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

        for (Face face in faces) {
          // GET LANDMARKS
          final leftMouth = face.landmarks[FaceLandmarkType.leftMouth];
          final rightMouth = face.landmarks[FaceLandmarkType.rightMouth];
          final bottomMouth = face.landmarks[FaceLandmarkType.bottomMouth];

          // If we can't find a mouth, skip
          if (leftMouth == null || rightMouth == null || bottomMouth == null) {
            continue;
          }

          // LOGIC: Calculate "Mouth Width"
          // Distance between left and right mouth corners
          double mouthWidth = sqrt(
              pow(leftMouth.position.x - rightMouth.position.x, 2) +
                  pow(leftMouth.position.y - rightMouth.position.y, 2)
          );

          double mouthRatio = mouthWidth / screenWidth;

          // DEBUG: See how big the mouth is
          // debugPrint("👄 Mouth Ratio: ${mouthRatio.toStringAsFixed(2)}");

          // THRESHOLD:
          // If the mouth alone covers > 15% of the screen width,
          // the face is EXTREMELY close (Sujud).
          // (Normal standing distance, mouth ratio is usually < 0.05)
          if (mouthRatio > 0.15) {
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