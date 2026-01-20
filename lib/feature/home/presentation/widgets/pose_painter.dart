import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;
  final CameraLensDirection cameraLensDirection; // 1. Add this field

  PosePainter(
      this.poses,
      this.absoluteImageSize,
      this.rotation,
      this.cameraLensDirection, // 2. Update constructor
      );

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green;

    for (final pose in poses) {
      Offset getPoint(PoseLandmarkType type) {
        final landmark = pose.landmarks[type]!;
        return Offset(
          translateX(landmark.x, size, absoluteImageSize, rotation, cameraLensDirection),
          translateY(landmark.y, size, absoluteImageSize, rotation),
        );
      }

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint p) {
        canvas.drawLine(getPoint(type1), getPoint(type2), p);
      }

      // Arms
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow, paint);
      paintLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist, paint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow, paint);
      paintLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist, paint);

      // Torso
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder, paint);
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip, paint);
      paintLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip, paint);
      paintLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip, paint);

      // Legs
      paintLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee, paint);
      paintLine(PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle, paint);
      paintLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee, paint);
      paintLine(PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle, paint);
    }
  }

  // 3. Update translateX to handle mirroring
  double translateX(
      double x,
      Size canvasSize,
      Size imageSize,
      InputImageRotation rotation,
      CameraLensDirection cameraLensDirection,
      ) {
    // Calculate the standard X coordinate
    double value;
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        value = x * canvasSize.width / imageSize.height;
        break;
      default:
        value = x * canvasSize.width / imageSize.width;
        break;
    }

    // IF FRONT CAMERA: Flip the X coordinate (Mirroring)
    if (cameraLensDirection == CameraLensDirection.front) {
      return canvasSize.width - value;
    }

    return value;
  }

  double translateY(double y, Size canvasSize, Size imageSize, InputImageRotation rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return y * canvasSize.height / imageSize.width;
      default:
        return y * canvasSize.height / imageSize.height;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}