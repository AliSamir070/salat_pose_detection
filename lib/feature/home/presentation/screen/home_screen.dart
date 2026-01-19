import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
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
  bool _isBusy = false; // Prevents dropping frames if detection is slow
  List<Pose> _poses = [];
  CameraDescription? _camera;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Initialize the detector
    // mode: Stream mode focuses on speed over accuracy
    final options = PoseDetectorOptions(mode: PoseDetectionMode.stream);
    _poseDetector = PoseDetector(options: options);
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    // Select the rear camera (0) or front (1)
    _camera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first);

    _controller = CameraController(
      _camera!,
      ResolutionPreset.medium, // Lower resolution = faster processing
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21 // Required for Android
          : ImageFormatGroup.bgra8888, // Required for iOS
    );

    await _controller!.initialize();

    // Start Streaming
    _controller!.startImageStream(_processCameraImage);

    if (mounted) setState(() {});
  }
  String _currentPose = "Waiting...";
  final _prayerDetector = PrayerPoseDetector();
  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy || _poseDetector == null) return;
    _isBusy = true;

    try {
      // Calculate rotation
      final rotation = CameraUtils.rotationIntToImageRotation(
        _camera!.sensorOrientation,
      );

      // Convert image
      final inputImage = CameraUtils.inputImageFromCameraImage(
          image,
          _camera!,
          rotation
      );

      // Detect Poses
      final poses = await _poseDetector!.processImage(inputImage);
      if (poses.isNotEmpty) {
        // We analyze the first detected person
        String detectedStatus = _prayerDetector.detectPose(poses.first);
      if (mounted) {
        setState(() {
          _poses = poses;
          _currentPose = detectedStatus;
          print('pose: $_currentPose');
        });
      }
    }
    } catch (e) {
      print("Error detecting pose: $e");
    } finally {
      _isBusy = false;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Container();
    }

    return Scaffold(
      body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Stack(
            fit: StackFit.expand,
            children: [
              CameraPreview(_controller!),
              // Overlay the painter
              if (_poses.isNotEmpty)
                CustomPaint(
                  painter: PosePainter(
                    _poses,
                    _controller!.value.previewSize!,
                    CameraUtils.rotationIntToImageRotation(_camera!.sensorOrientation), // Add this!
                  ),
                ),
            ],
          ),
          Container(
              margin: EdgeInsets.only(
                bottom: 10
              ),
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.black
              ),
              child: Text(_currentPose,style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color:Colors.white
              ),))
        ],
      ),
    );
  }
}
