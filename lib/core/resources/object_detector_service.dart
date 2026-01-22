import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';

class ObjectDetectorService {
  late ObjectDetector _objectDetector;

  ObjectDetectorService() {
    // Stream mode is optimized for live camera feeds
    final options = ObjectDetectorOptions(
      mode: DetectionMode.stream,
      classifyObjects: true, // Enable to get labels (e.g., "Bottle", "Phone")
      multipleObjects: true,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<List<DetectedObject>> detectFromInputImage(InputImage inputImage) async {
    return await _objectDetector.processImage(inputImage);
  }

  void dispose() => _objectDetector.close();
}
