import 'dart:math' as math;
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

class PrayerPoseDetector {

  // We use this to establish what "Standing" looks like for this person
  double? _standingShoulderHeight;
  String savedPose = "Unknown";
  String detectPose(Pose pose) {
    final nose = pose.landmarks[PoseLandmarkType.nose];
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = pose.landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final rightHip = pose.landmarks[PoseLandmarkType.rightHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final rightKnee = pose.landmarks[PoseLandmarkType.rightKnee];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = pose.landmarks[PoseLandmarkType.rightWrist];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
    final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

    // 1. Safety Check
    if (nose == null || leftShoulder == null || rightShoulder == null ||
        leftHip == null || rightHip == null || leftKnee == null || rightKnee == null ||
        leftWrist == null || rightWrist == null || leftAnkle == null || rightAnkle == null) {
      savedPose = "Unkown";
      return savedPose;
    }

    // 2. Normalize Coordinates (Averages for stability)
    double shoulderY = (leftShoulder.y + rightShoulder.y) / 2;
    double hipY = (leftHip.y + rightHip.y) / 2;
    double kneeY = (leftKnee.y + rightKnee.y) / 2;
    double wristY = (leftWrist.y + rightWrist.y) / 2;
    double ankleY = (leftAnkle.y + rightAnkle.y) / 2;

    // Use the distance between Knee and Ankle as a "Ruler" (Shin Length).
    // This body part doesn't change length much in perspective during Ruku.
    double shinLength = (kneeY - ankleY).abs();
    // Safety fallback if shin is barely visible
    if (shinLength < 20) shinLength = 100;

    // 3. Calibration: Capture Standing Height
    // If Hips are high above Knees, we assume standing.
    if (hipY < (kneeY - shinLength)) {
      if (_standingShoulderHeight == null || shoulderY < _standingShoulderHeight!) {
        _standingShoulderHeight = shoulderY;
      }
    }

    // --- DETECTION LOGIC ---

    // 1. SUJUD CHECK
    // Logic: Nose is very close to the Knee level (ground level in camera frame).
    // And Shoulders are compressed down near the knees.
    bool isNoseOnGround = (nose.y - kneeY).abs() < (shinLength * 0.8);
    bool areShouldersLow = (shoulderY - kneeY).abs() < (shinLength * 0.8);

    if (isNoseOnGround && areShouldersLow) {
      if(savedPose=="Ruku"){
        savedPose = "Sujud";
      }else if(savedPose == "Sujud"){
        savedPose = "Sujud2";
      }
      return savedPose;
    }

    // 2. RUKU CHECK (The "Hands on Knees" Logic)
    // Logic A: Wrists are vertically close to Knees.
    // Logic B: Shoulders are dropped (lower than standing), but NOT on the ground.
    // Logic C: Hips are still HIGH (far from ankles), meaning legs are straight-ish.

    // A: Are hands near knees? (Tolerance: half a shin length)
    bool handsReachingKnees = (wristY - kneeY).abs() < (shinLength * 0.8);

    // B: Have shoulders dropped? (Shoulder Y is significantly larger/lower than standing baseline)
    // If we don't have a baseline, we assume shoulders are at least closer to hips than normal.
    bool shouldersDropped = shoulderY > (_standingShoulderHeight ?? 0) + (shinLength * 0.5);

    // C: Are hips high? (Distinguishes Ruku from Sitting/Tashahhud)
    // In Sitting, Hip Y is close to Ankle Y. In Ruku, Hip Y is far above Ankle Y.
    bool hipsAreHigh = (hipY - ankleY).abs() > (shinLength * 1.2);

    if (handsReachingKnees && hipsAreHigh && shouldersDropped) {
      savedPose =  "Ruku";
      return savedPose;
    }

    /*// 3. SITTING (TASHAHHUD) CHECK
    // Logic: Hands might be on knees, but Hips are LOW (near ankles/ground).
    bool hipsAreLow = (hipY - ankleY).abs() < (shinLength * 1.0);
    if (handsReachingKnees && hipsAreLow) {
      return "Sitting";
    }*/

    // 4. QIYAM (STANDING) CHECK
    // Logic: Hips are high, Shoulders are high.
    // Wrists are usually above hips or at hip level (folded or at sides), NOT at knees.
    bool wristsAboveKnees = wristY < (kneeY - shinLength * 0.5);

    if (hipsAreHigh && wristsAboveKnees) {
      if(savedPose=="Sujud2" || savedPose=="Ruku" || savedPose=="Unkown"){
        savedPose = "Qiyam";
      }
      return savedPose;
    }

    return savedPose ;
  }
}