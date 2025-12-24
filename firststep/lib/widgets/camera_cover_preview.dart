import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

class CameraCoverPreview extends StatelessWidget {
  final CameraController controller;
  final double radius;

  const CameraCoverPreview({
    super.key,
    required this.controller,
    this.radius = 16,
  });

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) return const SizedBox();

    final size = MediaQuery.of(context).size;
    final scale = 1 / (controller.value.aspectRatio * size.aspectRatio);

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: OverflowBox(
        alignment: Alignment.center,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: CameraPreview(controller),
        ),
      ),
    );
  }
}
