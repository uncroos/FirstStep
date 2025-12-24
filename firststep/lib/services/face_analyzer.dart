import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceScores {
  final bool faceDetected;
  final int gazeScore; // 0~100
  final int smileScore; // 0~100

  const FaceScores({
    required this.faceDetected,
    required this.gazeScore,
    required this.smileScore,
  });

  static const empty = FaceScores(
    faceDetected: false,
    gazeScore: 0,
    smileScore: 0,
  );
}

class FaceAnalyzer {
  final FaceDetector _detector;

  bool _running = false;
  bool _busy = false;
  int _lastMs = 0;

  final ValueNotifier<FaceScores> scores = ValueNotifier(FaceScores.empty);

  FaceAnalyzer()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableClassification: true,
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
        ),
      );

  bool get running => _running;

  Future<void> dispose() async {
    await stop();
    _detector.close();
    scores.dispose();
  }

  Future<void> start(CameraController cam) async {
    if (_running) return;
    if (!cam.value.isInitialized) return;

    _running = true;

    await cam.startImageStream((CameraImage image) async {
      if (!_running) return;
      if (_busy) return;

      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - _lastMs < 150) return; // 150ms throttle
      _lastMs = now;

      _busy = true;
      try {
        final input = _toInputImage(image, cam.description);
        if (input == null) return;

        final faces = await _detector.processImage(input);
        _applyFaces(faces);
      } catch (_) {
        // 필요하면 debugPrint
      } finally {
        _busy = false;
      }
    });
  }

  Future<void> stop({CameraController? cam}) async {
    _running = false;
    _busy = false;
    scores.value = FaceScores.empty;

    if (cam != null && cam.value.isStreamingImages) {
      try {
        await cam.stopImageStream();
      } catch (_) {}
    }
  }

  void _applyFaces(List<Face> faces) {
    if (faces.isEmpty) {
      scores.value = FaceScores.empty;
      return;
    }

    final f = faces.first;
    final yaw = f.headEulerAngleY ?? 999;
    final pitch = f.headEulerAngleX ?? 999;

    final front = yaw.abs() < 10 && pitch.abs() < 10;
    final smile = ((f.smilingProbability ?? 0) * 100).round().clamp(0, 100);

    scores.value = FaceScores(
      faceDetected: true,
      gazeScore: front ? 100 : 30,
      smileScore: smile,
    );
  }

  InputImage? _toInputImage(CameraImage image, CameraDescription desc) {
    final rotation = InputImageRotationValue.fromRawValue(
      desc.sensorOrientation,
    );
    if (rotation == null) return null;

    if (Platform.isIOS) {
      final format = InputImageFormatValue.fromRawValue(image.format.raw);
      if (format == null) return null;

      final bytes = image.planes.first.bytes;
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      );
      return InputImage.fromBytes(bytes: bytes, metadata: metadata);
    } else {
      final nv21 = _yuv420ToNv21(image);
      final metadata = InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      );
      return InputImage.fromBytes(bytes: nv21, metadata: metadata);
    }
  }

  Uint8List _yuv420ToNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;

    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBytes = yPlane.bytes;
    final uBytes = uPlane.bytes;
    final vBytes = vPlane.bytes;

    final yRowStride = yPlane.bytesPerRow;
    final uvRowStride = uPlane.bytesPerRow;
    final uvPixelStride = uPlane.bytesPerPixel ?? 1;

    final out = Uint8List(width * height + (width * height ~/ 2));
    int outIndex = 0;

    // Y
    for (int row = 0; row < height; row++) {
      final rowStart = row * yRowStride;
      out.setRange(
        outIndex,
        outIndex + width,
        yBytes.sublist(rowStart, rowStart + width),
      );
      outIndex += width;
    }

    // VU (NV21)
    final uvHeight = height ~/ 2;
    final uvWidth = width ~/ 2;

    for (int row = 0; row < uvHeight; row++) {
      for (int col = 0; col < uvWidth; col++) {
        final uvIndex = row * uvRowStride + col * uvPixelStride;
        out[outIndex++] = vBytes[uvIndex];
        out[outIndex++] = uBytes[uvIndex];
      }
    }

    return out;
  }
}
