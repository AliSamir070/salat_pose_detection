import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PrayerPoseDetector {

  String detectPose(Pose pose) {
    // 1. Get Key Landmarks
    final shoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final hip = pose.landmarks[PoseLandmarkType.leftHip];
    final knee = pose.landmarks[PoseLandmarkType.leftKnee];
    final ankle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final nose = pose.landmarks[PoseLandmarkType.nose];

    if (shoulder == null || hip == null || knee == null || ankle == null || nose == null) {
      return "Unknown";
    }

    // 2. Calculate Angles
    double hipAngle = _getAngle(shoulder, hip, knee);
    double kneeAngle = _getAngle(hip, knee, ankle);

    // 3. Logic for Sujud (Prostration)
    // In Sujud, the head (nose) is roughly at the same Y-level as the knee (on the ground).
    // Note: In image coordinates, larger Y means lower on the screen (closer to ground).
    // So Sujud means Nose Y is High (ground) and Hip Y is Low (air).

    // Check if Hips are significantly higher than Shoulders (Y value is smaller)
    bool isHipHigherThanShoulder = hip.y < shoulder.y;

    // Check if Nose is close to the ground (similar Y to Knee)
    bool isHeadOnGround = (nose.y - knee.y).abs() < 150; // Tolerance threshold

    if (isHipHigherThanShoulder && isHeadOnGround) {
      return "Sujud (Prostration)";
    }

    // 4. Logic for Ruku (Bowing)
    // In Ruku, the back is horizontal (Shoulder Y approx equals Hip Y)
    // And the Hip angle is roughly 90 degrees (70-110 range)

    bool isBackHorizontal = (shoulder.y - hip.y).abs() < 50; // Tolerance
    bool isHipAngle90 = hipAngle > 70 && hipAngle < 130;

    if (isBackHorizontal && isHipAngle90) {
      return "Ruku (Bowing)";
    }

    // 5. Logic for Standing (Qiyam)
    if (hipAngle > 160 && kneeAngle > 160) {
      return "Standing";
    }

    return "Transition";
  }

  // Helper to calculate angle between three points
  double _getAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    double result = math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    result = result * 180 / math.pi; // Convert to degrees
    result = result.abs(); // Absolute value
    if (result > 180) {
      result = 360.0 - result;
    }
    return result;
  }
}