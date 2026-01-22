import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

// Import the new file
import '../../../../core/resources/camera_utils.dart';
import '../../../../core/resources/face_proximity_detector.dart';
import '../../../../core/resources/object_camera_detection.dart';
import '../../../../core/resources/sujud_history_detector.dart';

class HomeScreen extends StatefulWidget {
  static const String routeName = "home";
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  CameraController? _controller;
  CameraDescription? _camera;
  // The new logic detector
  late SujudHistoryDetector _sujudDetector;

  bool _isSujud = false;
// 1. Define the detector
  late CameraBlockageDetector _blockageDetector;
  late FaceProximityDetector faceProximityDetector;
  @override
  void initState() {
    super.initState();
    _blockageDetector = CameraBlockageDetector(); // Init
    faceProximityDetector = FaceProximityDetector();
    _initializeCamera();
    // ... rest of init
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
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
    try { await _controller!.setFocusMode(FocusMode.auto); } catch (_) {}
    _controller!.startImageStream(_processCameraImage);
    if(mounted) setState(() {

    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    try {
      // --- STEP 1: CHECK BLOCKAGE FIRST (The "Sujud" Check) ---
      // We pass the raw image directly. No rotation/conversion needed.
      final rotation = CameraUtils.rotationIntToImageRotation(_camera!.sensorOrientation);
      final inputImage = CameraUtils.inputImageFromCameraImage(image, _camera!, rotation);
      bool? isBlocked = await faceProximityDetector.isFaceTooClose(inputImage);
      debugPrint("isBlocked:$isBlocked");
      if(isBlocked!=null){
        if (isBlocked) {
          if (mounted) {
            setState(() {
              _isSujud = true;
              debugPrint("isSujud:$_isSujud");

            });
          }

          return; // STOP HERE. Do not run heavy ML Kit if blocked.
        }
        if(mounted){
          setState(() {
            _isSujud = false;
          });
        }
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      //_isSujud = false;
    }
    debugPrint("isSujud:$_isSujud");

  }

  @override
  void dispose() {
    _controller?.dispose();
    _sujudDetector.close();
    faceProximityDetector.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(backgroundColor: Colors.black);
    }
    debugPrint("build : $_isSujud");
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          CameraPreview(_controller!),

          // Status Overlay
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 40),
                decoration: BoxDecoration(
                    color: _isSujud ? Colors.green : Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white, width: 2)
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isSujud ? Icons.check_circle : Icons.accessibility_new,
                      color: Colors.white,
                      size: 60,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _isSujud ? "SUJUD" : "Scanning...",
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}