import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:video_player/video_player.dart';

import '../../models/subtitle.dart';
import '../../providers/favorites_store.dart';
import '../../providers/player_provider.dart';
import '../../widgets/player/subtitle_panel.dart';
import '../../widgets/player/video_area.dart';

enum SubtitleSource { local, ai }

class PlayerNarrowLayout extends ConsumerWidget {
  const PlayerNarrowLayout({
    super.key,
    required this.controller,
    required this.isVideoInitialized,
    required this.videoHeight,
    required this.onVideoHeightChanged,
    required this.cues,
    required this.displayMode,
    required this.onDisplayModeChanged,
    required this.subtitleSource,
    required this.onSourceChanged,
    required this.isTranscribing,
    required this.transcribeError,
    required this.onCueTap,
    required this.onToggleFavorite,
    required this.onWordTap,
    required this.onCollocationTap,
    required this.onPlayPause,
    this.onMemoTap,
    this.onGrammarTap,
    this.getMemorizationScore,
    this.onAnyWordTap,
    this.onTextSelection,
  });

  final VideoPlayerController? controller;
  final bool isVideoInitialized;
  final double videoHeight;
  final ValueChanged<double> onVideoHeightChanged;
  final List<SubtitleCue> cues;
  final SubtitleDisplayMode displayMode;
  final ValueChanged<SubtitleDisplayMode> onDisplayModeChanged;
  final SubtitleSource subtitleSource;
  final ValueChanged<SubtitleSource> onSourceChanged;
  final bool isTranscribing;
  final String? transcribeError;
  final ValueChanged<int> onCueTap;
  final ValueChanged<SubtitleCue> onToggleFavorite;
  final void Function(String word, String? meaning) onWordTap;
  final void Function(String text, String? meaning) onCollocationTap;
  final void Function(String word)? onAnyWordTap;
  final void Function(String text)? onTextSelection;
  final VoidCallback onPlayPause;
  final void Function(SubtitleCue cue)? onMemoTap;
  final void Function(SubtitleCue cue)? onGrammarTap;
  final double? Function(int index)? getMemorizationScore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    return Column(
      children: [
        SizedBox(
          height: videoHeight,
          child: GestureDetector(
            onTap: onPlayPause,
            child: VideoArea(
              controller: controller,
              isInitialized: isVideoInitialized,
              onTap: onPlayPause,
            ),
          ),
        ),
        VideoResizeHandle(onVerticalDragUpdate: (delta) {
          onVideoHeightChanged((videoHeight + delta).clamp(80, 500));
        }),
        Expanded(
          child: SubtitlePanel(
            cues: cues,
            activeCueIndex: playerState.activeCueIndex,
            position: playerState.position,
            subtitleHeight: 260,
            displayMode: displayMode,
            onCueTap: onCueTap,
            isFavorited: (text) =>
                ref.read(favoritesStoreProvider.notifier).isFavorited(text),
            onToggleFavorite: onToggleFavorite,
            onMemoTap: onMemoTap,
            onGrammarTap: onGrammarTap,
            getMemorizationScore: getMemorizationScore,
            onWordTap: onWordTap,
            onCollocationTap: onCollocationTap,
            onAnyWordTap: onAnyWordTap,
            onTextSelection: onTextSelection,
          ),
        ),
        SubtitleModeSwitcher(
          displayMode: displayMode,
          onDisplayModeChanged: onDisplayModeChanged,
          subtitleSource: subtitleSource,
          onSourceChanged: onSourceChanged,
          isTranscribing: isTranscribing,
          transcribeError: transcribeError,
        ),
      ],
    );
  }
}

class PlayerWideLayout extends ConsumerWidget {
  const PlayerWideLayout({
    super.key,
    required this.controller,
    required this.isVideoInitialized,
    required this.wideVideoWidth,
    required this.onWideVideoWidthChanged,
    required this.cues,
    required this.displayMode,
    required this.onDisplayModeChanged,
    required this.subtitleSource,
    required this.onSourceChanged,
    required this.isTranscribing,
    required this.transcribeError,
    required this.onCueTap,
    required this.onToggleFavorite,
    required this.onWordTap,
    required this.onCollocationTap,
    required this.onPlayPause,
    this.onMemoTap,
    this.onGrammarTap,
    this.getMemorizationScore,
    this.onAnyWordTap,
    this.onTextSelection,
  });

  final VideoPlayerController? controller;
  final bool isVideoInitialized;
  final double? wideVideoWidth;
  final ValueChanged<double> onWideVideoWidthChanged;
  final List<SubtitleCue> cues;
  final SubtitleDisplayMode displayMode;
  final ValueChanged<SubtitleDisplayMode> onDisplayModeChanged;
  final SubtitleSource subtitleSource;
  final ValueChanged<SubtitleSource> onSourceChanged;
  final bool isTranscribing;
  final String? transcribeError;
  final ValueChanged<int> onCueTap;
  final ValueChanged<SubtitleCue> onToggleFavorite;
  final void Function(String word, String? meaning) onWordTap;
  final void Function(String text, String? meaning) onCollocationTap;
  final VoidCallback onPlayPause;
  final void Function(SubtitleCue cue)? onMemoTap;
  final void Function(SubtitleCue cue)? onGrammarTap;
  final double? Function(int index)? getMemorizationScore;
  final void Function(String word)? onAnyWordTap;
  final void Function(String text)? onTextSelection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        final videoWidth = (wideVideoWidth ?? totalWidth * 0.6)
            .clamp(totalWidth * 0.3, totalWidth * 0.75);

        return Row(
          children: [
            SizedBox(
              width: videoWidth,
              child: GestureDetector(
                onTap: onPlayPause,
                child: VideoArea(
                  controller: controller,
                  isInitialized: isVideoInitialized,
                  onTap: onPlayPause,
                ),
              ),
            ),
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                onWideVideoWidthChanged(
                  (videoWidth + details.delta.dx * 5)
                      .clamp(totalWidth * 0.3, totalWidth * 0.75),
                );
              },
              child: kIsWeb
                  ? Container(
                      width: 16,
                      color: ThemeColors.of(context).outline.withAlpha(50),
                      child: Center(
                        child: Icon(
                          Icons.drag_handle,
                          size: 16,
                          color: ThemeColors.of(context).onSurfaceVariant.withAlpha(120),
                        ),
                      ),
                    )
                  : MouseRegion(
                      cursor: SystemMouseCursors.resizeColumn,
                      child: Container(
                        width: 16,
                        color: ThemeColors.of(context).outline.withAlpha(50),
                        child: Center(
                          child: Icon(
                            Icons.drag_handle,
                            size: 16,
                            color: ThemeColors.of(context).onSurfaceVariant.withAlpha(120),
                          ),
                        ),
                      ),
                    ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: SubtitlePanel(
                      cues: cues,
                      activeCueIndex: playerState.activeCueIndex,
                      position: playerState.position,
                      subtitleHeight: 260,
                      displayMode: displayMode,
                      onCueTap: onCueTap,
                      isFavorited: (text) =>
                          ref.read(favoritesStoreProvider.notifier).isFavorited(text),
                      onToggleFavorite: onToggleFavorite,
                      onMemoTap: onMemoTap,
                      onGrammarTap: onGrammarTap,
                      getMemorizationScore: getMemorizationScore,
                      onWordTap: onWordTap,
                      onCollocationTap: onCollocationTap,
                      onAnyWordTap: onAnyWordTap,
                      onTextSelection: onTextSelection,
                    ),
                  ),
                  SubtitleModeSwitcher(
                    displayMode: displayMode,
                    onDisplayModeChanged: onDisplayModeChanged,
                    subtitleSource: subtitleSource,
                    onSourceChanged: onSourceChanged,
                    isTranscribing: isTranscribing,
                    transcribeError: transcribeError,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class VideoResizeHandle extends StatelessWidget {
  const VideoResizeHandle({
    super.key,
    required this.onVerticalDragUpdate,
  });

  final ValueChanged<double> onVerticalDragUpdate;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onVerticalDragUpdate: (details) {
        onVerticalDragUpdate(details.delta.dy);
      },
      child: kIsWeb
          ? Container(
              height: 16,
              color: ThemeColors.of(context).outline.withAlpha(50),
              child: Center(
                child: Icon(
                  Icons.drag_handle,
                  size: 16,
                  color: ThemeColors.of(context).onSurfaceVariant.withAlpha(120),
                ),
              ),
            )
          : MouseRegion(
              cursor: SystemMouseCursors.resizeRow,
              child: Container(
                height: 16,
                color: ThemeColors.of(context).outline.withAlpha(50),
                child: Center(
                  child: Icon(
                    Icons.drag_handle,
                    size: 16,
                    color: ThemeColors.of(context).onSurfaceVariant.withAlpha(120),
                  ),
                ),
              ),
            ),
    );
  }
}

class SubtitleModeSwitcher extends StatelessWidget {
  const SubtitleModeSwitcher({
    super.key,
    required this.displayMode,
    required this.onDisplayModeChanged,
    required this.subtitleSource,
    required this.onSourceChanged,
    required this.isTranscribing,
    required this.transcribeError,
  });

  final SubtitleDisplayMode displayMode;
  final ValueChanged<SubtitleDisplayMode> onDisplayModeChanged;
  final SubtitleSource subtitleSource;
  final ValueChanged<SubtitleSource> onSourceChanged;
  final bool isTranscribing;
  final String? transcribeError;

  @override
  Widget build(BuildContext context) {
    final modes = [
      (SubtitleDisplayMode.english, '英文'),
      (SubtitleDisplayMode.native, '中文'),
      (SubtitleDisplayMode.bilingual, '双语'),
      (SubtitleDisplayMode.hidden, '隐藏'),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: ThemeColors.of(context).background,
            border: Border(
              bottom: BorderSide(color: ThemeColors.of(context).outline.withAlpha(60)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SubtitleSourceTab(
                source: SubtitleSource.local,
                label: '本地字幕',
                isSelected: subtitleSource == SubtitleSource.local,
                isTranscribing: isTranscribing,
                onTap: () => onSourceChanged(SubtitleSource.local),
              ),
              const SizedBox(width: 4),
              SubtitleSourceTab(
                source: SubtitleSource.ai,
                label: 'AI 字幕',
                isSelected: subtitleSource == SubtitleSource.ai,
                isTranscribing: isTranscribing,
                onTap: () => onSourceChanged(SubtitleSource.ai),
              ),
              if (isTranscribing) ...[
                const SizedBox(width: 8),
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 4),
                Text(
                  '转录中...',
                  style: PlatformTextStyles.caption.copyWith(
                    color: ThemeColors.of(context).onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
              if (transcribeError != null && !isTranscribing) ...[
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    transcribeError!,
                    style: PlatformTextStyles.caption.copyWith(
                      color: PlatformColors.error,
                      fontSize: 10,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: ThemeColors.of(context).background,
            border: Border(
              bottom: BorderSide(color: ThemeColors.of(context).outline.withAlpha(60)),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: modes.map((m) {
              final selected = displayMode == m.$1;
              return GestureDetector(
                onTap: () => onDisplayModeChanged(m.$1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: selected
                            ? PlatformColors.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      m.$2,
                      style: PlatformTextStyles.caption.copyWith(
                        color: selected
                            ? PlatformColors.primary
                            : ThemeColors.of(context).onSurfaceVariant,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class SubtitleSourceTab extends StatelessWidget {
  const SubtitleSourceTab({
    super.key,
    required this.source,
    required this.label,
    required this.isSelected,
    required this.isTranscribing,
    required this.onTap,
  });

  final SubtitleSource source;
  final String label;
  final bool isSelected;
  final bool isTranscribing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isTranscribing ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? PlatformColors.primary.withAlpha(25)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: PlatformTextStyles.caption.copyWith(
            color: isSelected
                ? PlatformColors.primary
                : ThemeColors.of(context).onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}