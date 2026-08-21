import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:video_player/video_player.dart';

class VideoArea extends StatelessWidget {
  final VideoPlayerController? controller;
  final bool isInitialized;
  final VoidCallback onTap;

  const VideoArea({
    super.key,
    required this.controller,
    required this.isInitialized,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.black,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (!isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: PlatformColors.primary),
      );
    }

    if (controller == null) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.videocam_off, size: 48, color: Colors.white54),
            SizedBox(height: 12),
            Text(
              '视频不可用',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(controller!),
        if (!controller!.value.isPlaying)
          Container(
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(100),
            ),
            child: const Icon(
              Icons.play_arrow,
              size: 64,
              color: Colors.white,
            ),
          ),
      ],
    );
  }
}