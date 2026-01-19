import 'package:flutter/material.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PosePainter extends CustomPainter {
  final List<Pose> poses;
  final Size absoluteImageSize;
  final InputImageRotation rotation;

  PosePainter(this.poses, this.absoluteImageSize, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.green; // Default color

    final rukuPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.orange; // Color for bowing

    final sujudPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = Colors.blue; // Color for prostration

    for (final pose in poses) {
      // Helper to map coordinates
      Offset getPoint(PoseLandmarkType type) {
        final landmark = pose.landmarks[type]!;
        return Offset(
          translateX(landmark.x, size, absoluteImageSize, rotation),
          translateY(landmark.y, size, absoluteImageSize, rotation),
        );
      }

      void paintLine(PoseLandmarkType type1, PoseLandmarkType type2, Paint p) {
        canvas.drawLine(getPoint(type1), getPoint(type2), p);
      }

      // --- DRAW THE SKELETON (No Points) ---
      // We use the default paint for the skeleton lines

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

  // ... (Keep the translateX and translateY helper methods from the previous answer)
  double translateX(double x, Size canvasSize, Size imageSize, InputImageRotation rotation) {
    switch (rotation) {
      case InputImageRotation.rotation90deg:
      case InputImageRotation.rotation270deg:
        return x * canvasSize.width / imageSize.height;
      default:
        return x * canvasSize.width / imageSize.width;
    }
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