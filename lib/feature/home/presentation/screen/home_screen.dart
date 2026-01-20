import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Import needed for DeviceOrientation
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

import '../../../../core/resources/camera_utils.dart';
import '../../../../core/resources/prayer_detector.dart';
import '../widgets/pose_painter.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "home";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  PoseDetector? _poseDetector;
  bool _isBusy = false;
  List<Pose> _poses = [];
  CameraDescription? _camera;

  // Track current detected pose
  String _currentPose = "Waiting...";
  final _prayerDetector = PrayerPoseDetector();

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Stream mode focuses on speed over accuracy
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Select the rear camera (0) or front (1) - Default to Front for selfie-style prayer detection
    _camera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();

    // Important: Lock UI to Landscape if you want to force the user to hold it sideways
    // await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight]);

    _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _poseDetector == null) return;
    _isBusy = true;

    try {
      // --- LANDSCAPE ORIENTATION FIX ---
      // We need to calculate the rotation compensation based on how the user is holding the device.
      // This ensures ML Kit sees an "upright" person even if the phone is sideways.

      final int rotationCompensation = _getRotationCompensation(_camera!, _controller!.value.deviceOrientation);

      final rotation = CameraUtils.rotationIntToImageRotation(
        rotationCompensation,
      );

      final inputImage = CameraUtils.inputImageFromCameraImage(
          image,
          _camera!,
          rotation
      );

      final poses = await _poseDetector!.processImage(inputImage);

      if (poses.isNotEmpty) {
        String detectedStatus = _prayerDetector.detectPose(poses.first);
        if (mounted) {
          setState(() {
            _poses = poses;
            if(detectedStatus!=_currentPose){
              _currentPose = detectedStatus;
            }
          });
        }
      }
    } catch (e) {
      print("Error detecting pose: $e");
    } finally {
      _isBusy = false;
    }
  }

  // Helper to calculate correct rotation for ML Kit based on Device Orientation
  int _getRotationCompensation(CameraDescription camera, DeviceOrientation orientation) {
    int deviceOrientationDeg = 0;
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        deviceOrientationDeg = 0;
        break;
      case DeviceOrientation.landscapeLeft:
        deviceOrientationDeg = 90;
        break;
      case DeviceOrientation.portraitDown:
        deviceOrientationDeg = 180;
        break;
      case DeviceOrientation.landscapeRight:
        deviceOrientationDeg = 270;
        break;
    }

    int rotationCompensation;
    if (camera.lensDirection == CameraLensDirection.front) {
      rotationCompensation = (camera.sensorOrientation + deviceOrientationDeg) % 360;
    } else {
      rotationCompensation = (camera.sensorOrientation - deviceOrientationDeg + 360) % 360;
    }
    return rotationCompensation;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    // Reset orientation preference when leaving
    // SystemChrome.setPreferredOrientations([]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    // We recalculate rotation for the Painter to match the Preview
    // This assumes the Painter draws on top of the live preview which rotates with the device
    final int rotationCompensation = _getRotationCompensation(_camera!, _controller!.value.deviceOrientation);

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              if (_poses.isNotEmpty)
                CustomPaint(
                  painter: PosePainter(
                    _poses,
                    _controller!.value.previewSize!,
                    CameraUtils.rotationIntToImageRotation(rotationCompensation),
                    _camera!.lensDirection, // <--- Add this line
                  ),
                ),
            ],
          ),
          Container(
              margin: EdgeInsets.only(bottom: 20),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black.withOpacity(0.7),
              ),
              child: Text(
                _currentPose,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ))
        ],
      ),
    );
  }
}