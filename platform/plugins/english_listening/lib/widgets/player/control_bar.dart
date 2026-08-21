import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';
import '../../providers/ab_loop_history.dart';

class ControlBar extends StatelessWidget {
  final PlayerStatus playerState;
  final VoidCallback onPlayPause;
  final void Function(Duration position) onSeek;
  final VoidCallback onSetLoopStart;
  final VoidCallback onSetLoopEnd;
  final VoidCallback onToggleLoop;
  final VoidCallback onClearLoop;
  final void Function(String label)? onSaveLoop;
  final void Function(ABLoopEntry entry)? onLoadHistory;
  final VoidCallback? onSkipSilent;
  final VoidCallback? onPreviousCue;
  final VoidCallback? onNextCue;
  final bool skipSilentEnabled;
  final List<ABLoopEntry> loopHistory;
  final double playbackSpeed;
  final void Function(double speed)? onSpeedChanged;

  const ControlBar({
    super.key,
    required this.playerState,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSetLoopStart,
    required this.onSetLoopEnd,
    required this.onToggleLoop,
    required this.onClearLoop,
    this.onSaveLoop,
    this.onLoadHistory,
    this.onSkipSilent,
    this.onPreviousCue,
    this.onNextCue,
    this.skipSilentEnabled = false,
    this.loopHistory = const [],
    this.playbackSpeed = 1.0,
    this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isCompact = MediaQuery.of(context).size.width < 600;

    return Container(
      decoration: BoxDecoration(
        color: ThemeColors.of(context).surface,
        border: Border(
          top: BorderSide(color: ThemeColors.of(context).outline),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSeekBar(context),
            if (isCompact)
              _buildCompactControls(context)
            else
              _buildExpandedControls(context),
            if (playerState.loopStart != null || playerState.loopEnd != null)
              _buildLoopInfo(),
            if (loopHistory.isNotEmpty)
              _buildLoopHistory(context),
          ],
        ),
      ),
    );
  }

  Widget _buildSeekBar(BuildContext context) {
    final totalMs = playerState.duration.inMilliseconds;
    final posMs = playerState.position.inMilliseconds;
    final progress = totalMs > 0 ? posMs / totalMs : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: PlatformSpacing.sm),
      child: Row(
        children: [
          Text(
            _formatDuration(playerState.position),
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          ),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                activeTrackColor: PlatformColors.primary,
                inactiveTrackColor: ThemeColors.of(context).outline,
                thumbColor: PlatformColors.primary,
              ),
              child: Slider(
                value: progress.clamp(0.0, 1.0),
                onChanged: (value) {
                  final targetMs = (value * totalMs).round();
                  onSeek(Duration(milliseconds: targetMs));
                },
              ),
            ),
          ),
          Text(
            _formatDuration(playerState.duration),
            style: PlatformTextStyles.caption.copyWith(
              color: ThemeColors.of(context).onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PlatformSpacing.sm,
        0,
        PlatformSpacing.sm,
        PlatformSpacing.xs,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPlayPauseButton(),
              ..._buildLoopButtons(),
              _buildSpeedButton(context),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onPreviousCue != null)
                IconButton(
                  icon: const Icon(Icons.skip_previous, size: 20),
                  onPressed: onPreviousCue,
                  tooltip: '上一句',
                  visualDensity: VisualDensity.compact,
                ),
              if (onNextCue != null)
                IconButton(
                  icon: const Icon(Icons.skip_next, size: 20),
                  onPressed: onNextCue,
                  tooltip: '下一句',
                  visualDensity: VisualDensity.compact,
                ),
              if (onSkipSilent != null)
                _buildSkipSilentToggle(context),
              if (onSaveLoop != null &&
                  playerState.loopStart != null &&
                  playerState.loopEnd != null)
                IconButton(
                  icon: const Icon(Icons.save, size: 18),
                  onPressed: () => _showSaveLoopDialog(context),
                  tooltip: '保存 AB 片段',
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExpandedControls(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PlatformSpacing.sm,
        0,
        PlatformSpacing.sm,
        PlatformSpacing.xs,
      ),
      child: Row(
        children: [
          _buildPlayPauseButton(),
          if (onPreviousCue != null)
            IconButton(
              icon: const Icon(Icons.skip_previous, size: 18),
              onPressed: onPreviousCue,
              tooltip: '上一句',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          if (onNextCue != null)
            IconButton(
              icon: const Icon(Icons.skip_next, size: 18),
              onPressed: onNextCue,
              tooltip: '下一句',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          const SizedBox(width: PlatformSpacing.xs),
          ..._buildLoopButtons(),
          if (onSaveLoop != null &&
              playerState.loopStart != null &&
              playerState.loopEnd != null)
            IconButton(
              icon: const Icon(Icons.save, size: 16),
              onPressed: () => _showSaveLoopDialog(context),
              tooltip: '保存 AB 片段',
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          const Spacer(),
          if (onSkipSilent != null) _buildSkipSilentToggle(context),
          _buildSpeedButton(context),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton() {
    final isPlaying = playerState.state == PlayerState.playing;
    return IconButton(
      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
      onPressed: onPlayPause,
      tooltip: isPlaying ? '暂停' : '播放',
    );
  }

  List<Widget> _buildLoopButtons() {
    final hasA = playerState.loopStart != null;
    final hasB = playerState.loopEnd != null;
    final canLoop = hasA && hasB;

    return [
      _LoopButton(
        label: 'A',
        isActive: hasA,
        color: PlatformColors.green,
        onPressed: onSetLoopStart,
        tooltip: '设置起点',
      ),
      const SizedBox(width: 2),
      _LoopButton(
        label: 'B',
        isActive: hasB,
        color: PlatformColors.red,
        onPressed: onSetLoopEnd,
        tooltip: '设置终点',
      ),
      const SizedBox(width: 2),
      _LoopButton(
        label: playerState.isLooping ? '■' : '↻',
        isActive: playerState.isLooping,
        color: PlatformColors.primary,
        onPressed: canLoop ? onToggleLoop : null,
        tooltip: playerState.isLooping ? '停止循环' : '开始循环',
      ),
      if (hasA || hasB)
        IconButton(
          icon: const Icon(Icons.clear, size: 16),
          onPressed: onClearLoop,
          tooltip: '清除 AB 标记',
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
        ),
    ];
  }

  Widget _buildSkipSilentToggle(BuildContext context) {
    return IconButton(
      icon: Icon(
        skipSilentEnabled ? Icons.fast_forward : Icons.fast_forward_outlined,
        color: skipSilentEnabled ? PlatformColors.primary : PlatformColors.gray,
        size: 20,
      ),
      onPressed: onSkipSilent,
      tooltip: skipSilentEnabled ? '静音跳过: 开' : '静音跳过: 关',
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildSpeedButton(BuildContext context) {
    return TextButton(
      onPressed: () => _showSpeedPicker(context),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        '${playbackSpeed}x',
        style: PlatformTextStyles.caption.copyWith(
          color: playbackSpeed != 1.0
              ? PlatformColors.primary
              : ThemeColors.of(context).onSurfaceVariant,
          fontWeight: playbackSpeed != 1.0 ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }

  void _showSpeedPicker(BuildContext context) {
    if (onSpeedChanged == null) return;
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('播放速度', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ...speeds.map((s) => ListTile(
                  title: Text('${s}x'),
                  trailing: playbackSpeed == s
                      ? const Icon(Icons.check, color: PlatformColors.primary)
                      : null,
                  onTap: () {
                    onSpeedChanged?.call(s);
                    Navigator.pop(ctx);
                  },
                )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildLoopInfo() {
    final a = playerState.loopStart;
    final b = playerState.loopEnd;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.xs,
      ),
      color: PlatformColors.primary.withAlpha(15),
      child: Row(
        children: [
          Icon(Icons.loop, size: 14, color: PlatformColors.primary),
          const SizedBox(width: PlatformSpacing.xs),
          Text(
            'A: ${a != null ? _formatDuration(a) : "--"}  '
            'B: ${b != null ? _formatDuration(b) : "--"}'
            '${playerState.isLooping ? "  循环中" : ""}',
            style: PlatformTextStyles.caption.copyWith(
              color: PlatformColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoopHistory(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.xs,
      ),
      color: ThemeColors.of(context).surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history, size: 14, color: ThemeColors.of(context).onSurfaceVariant),
              const SizedBox(width: PlatformSpacing.xs),
              Text(
                'AB 历史',
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: PlatformSpacing.xs),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: loopHistory.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: PlatformSpacing.xs),
              itemBuilder: (_, index) {
                final entry = loopHistory[index];
                return GestureDetector(
                  onTap: () => onLoadHistory?.call(entry),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: ThemeColors.of(context).outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${entry.label} (${_formatDuration(entry.pointA)}-${_formatDuration(entry.pointB)})',
                      style: PlatformTextStyles.caption.copyWith(
                        color: ThemeColors.of(context).onSurfaceVariant,
                        fontSize: 10,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showSaveLoopDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('保存 AB 片段'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: '输入片段名称',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              final label = controller.text.trim();
              if (label.isNotEmpty) {
                onSaveLoop?.call(label);
                Navigator.pop(ctx);
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _LoopButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;
  final VoidCallback? onPressed;
  final String tooltip;

  const _LoopButton({
    required this.label,
    required this.isActive,
    required this.color,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: isActive ? color.withAlpha(30) : null,
            border: Border.all(
              color: isActive ? color : ThemeColors.of(context).outline,
            ),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? color : ThemeColors.of(context).onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}