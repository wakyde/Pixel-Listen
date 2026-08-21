import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_ui/shared_ui.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});

class SettingsState {
  final String? cefrMinLevel;
  final String? cefrMaxLevel;
  final String backendUrl;
  final bool darkMode;
  final bool autoSync;
  final bool autoPlayNext;
  final double playbackSpeed;

  const SettingsState({
    this.cefrMinLevel,
    this.cefrMaxLevel,
    this.backendUrl = 'http://localhost:8000',
    this.darkMode = false,
    this.autoSync = false,
    this.autoPlayNext = false,
    this.playbackSpeed = 1.0,
  });

  SettingsState copyWith({
    String? cefrMinLevel,
    String? cefrMaxLevel,
    String? backendUrl,
    bool? darkMode,
    bool? autoSync,
    bool? autoPlayNext,
    double? playbackSpeed,
  }) {
    return SettingsState(
      cefrMinLevel: cefrMinLevel ?? this.cefrMinLevel,
      cefrMaxLevel: cefrMaxLevel ?? this.cefrMaxLevel,
      backendUrl: backendUrl ?? this.backendUrl,
      darkMode: darkMode ?? this.darkMode,
      autoSync: autoSync ?? this.autoSync,
      autoPlayNext: autoPlayNext ?? this.autoPlayNext,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final platformTheme = prefs.getString('platform_theme_mode');
    final darkMode = platformTheme != null
        ? platformTheme == 'dark'
        : prefs.getBool('dark_mode') ?? false;
    state = SettingsState(
      cefrMinLevel: prefs.getString('cefr_min_level'),
      cefrMaxLevel: prefs.getString('cefr_max_level'),
      backendUrl: prefs.getString('backend_url') ?? 'http://localhost:8000',
      darkMode: darkMode,
      autoSync: prefs.getBool('auto_sync') ?? false,
      autoPlayNext: prefs.getBool('auto_play_next') ?? false,
      playbackSpeed: prefs.getDouble('playback_speed') ?? 1.0,
    );
  }

  Future<void> setCefrMinLevel(String? level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level != null) {
      await prefs.setString('cefr_min_level', level);
    } else {
      await prefs.remove('cefr_min_level');
    }
    state = state.copyWith(cefrMinLevel: level);
  }

  Future<void> setCefrMaxLevel(String? level) async {
    final prefs = await SharedPreferences.getInstance();
    if (level != null) {
      await prefs.setString('cefr_max_level', level);
    } else {
      await prefs.remove('cefr_max_level');
    }
    state = state.copyWith(cefrMaxLevel: level);
  }

  Future<void> setBackendUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('backend_url', url);
    state = state.copyWith(backendUrl: url);
  }

  Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
    await prefs.setString('platform_theme_mode', value ? 'dark' : 'light');
    state = state.copyWith(darkMode: value);
  }

  Future<void> setAutoSync(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_sync', value);
    state = state.copyWith(autoSync: value);
  }

  Future<void> setAutoPlayNext(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_play_next', value);
    state = state.copyWith(autoPlayNext: value);
  }

  Future<void> setPlaybackSpeed(double speed) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('playback_speed', speed);
    state = state.copyWith(playbackSpeed: speed);
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _load();
  }
}

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _levelOptions = ['A1', 'A2', 'B1', 'B2', 'C1', 'C2'];
  static const _speedOptions = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          _buildSectionHeader(context, 'CEFR 词汇筛选'),
          _buildDropdownTile(
            '最低等级',
            settings.cefrMinLevel ?? '不限',
            _levelOptions,
            (v) => ref.read(settingsProvider.notifier).setCefrMinLevel(
                  v == '不限' ? null : v,
                ),
          ),
          _buildDropdownTile(
            '最高等级',
            settings.cefrMaxLevel ?? '不限',
            _levelOptions,
            (v) => ref.read(settingsProvider.notifier).setCefrMaxLevel(
                  v == '不限' ? null : v,
                ),
          ),
          const Divider(),
          _buildSectionHeader(context, '播放'),
          _buildSwitchTile(
            '自动播放下一条',
            settings.autoPlayNext,
            (v) => ref.read(settingsProvider.notifier).setAutoPlayNext(v),
          ),
          _buildDropdownTile(
            '播放速度',
            '${settings.playbackSpeed}x',
            _speedOptions.map((e) => '${e}x').toList(),
            (v) => ref.read(settingsProvider.notifier)
                .setPlaybackSpeed(double.parse(v.replaceAll('x', ''))),
          ),
          const Divider(),
          _buildSectionHeader(context, '同步'),
          _buildSwitchTile(
            '自动同步',
            settings.autoSync,
            (v) => ref.read(settingsProvider.notifier).setAutoSync(v),
          ),
          const Divider(),
          _buildSectionHeader(context, '外观'),
          _buildSwitchTile(
            '深色模式',
            settings.darkMode,
            (v) => ref.read(settingsProvider.notifier).setDarkMode(v),
          ),
          const Divider(),
          _buildSectionHeader(context, '后端'),
          ListTile(
            title: const Text('后端地址'),
            subtitle: Text(settings.backendUrl),
            onTap: () => _showBackendUrlDialog(context, ref),
          ),
          const Divider(),
          _buildSectionHeader(context, '数据'),
          ListTile(
            title: const Text('清除所有本地数据'),
            subtitle: const Text('删除收藏、闪卡、设置等'),
            leading: const Icon(Icons.delete_forever, color: PlatformColors.red),
            onTap: () => _showClearDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        PlatformSpacing.md,
        PlatformSpacing.md,
        PlatformSpacing.md,
        PlatformSpacing.xs,
      ),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: ThemeColors.of(context).onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: PlatformTextStyles.body),
      value: value,
      onChanged: onChanged,
      activeTrackColor: PlatformColors.primary,
    );
  }

  Widget _buildDropdownTile(
    String title,
    String currentValue,
    List<String> options,
    ValueChanged<String> onChanged,
  ) {
    return ListTile(
      title: Text(title, style: PlatformTextStyles.body),
      trailing: DropdownButton<String>(
        value: currentValue,
        items: [
          for (final opt in options)
            DropdownMenuItem(value: opt, child: Text(opt)),
        ],
        onChanged: (v) {
          if (v != null) onChanged(v);
        },
        underline: const SizedBox(),
      ),
    );
  }

  void _showBackendUrlDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController(
      text: ref.read(settingsProvider).backendUrl,
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('后端地址'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'http://localhost:8000',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).setBackendUrl(controller.text);
              Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text('将删除所有本地数据，包括收藏、闪卡记录和设置。此操作不可撤销。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).clearAllData();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清除所有本地数据')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: PlatformColors.red),
            child: const Text('清除'),
          ),
        ],
      ),
    );
  }
}