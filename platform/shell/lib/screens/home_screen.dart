import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shared_auth/shared_auth.dart';
import '../providers/theme_provider.dart';
import '../registry.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(themeModeProvider.notifier).refreshFromPrefs();
    });

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return const SizedBox.shrink();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Platform'),
        actions: [
          IconButton(
            icon: Icon(ref.watch(themeModeProvider.notifier).icon),
            tooltip: ref.watch(themeModeProvider.notifier).label,
            onPressed: () {
              ref.read(themeModeProvider.notifier).toggle();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ResponsiveLayout(
        compact: (_) => _buildGrid(context, 2),
        medium: (_) => _buildGrid(context, 3),
        expanded: (_) => _buildGrid(context, 4),
      ),
    );
  }

  Widget _buildGrid(BuildContext context, int crossAxisCount) {
    final sorted = List<PlatformPlugin>.from(pluginRegistry)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

    return Padding(
      padding: const EdgeInsets.all(PlatformSpacing.md),
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: PlatformSpacing.md,
          crossAxisSpacing: PlatformSpacing.md,
          childAspectRatio: 1.1,
        ),
        itemCount: sorted.length,
        itemBuilder: (context, index) {
          final plugin = sorted[index];
          return _PluginCard(plugin: plugin);
        },
      ),
    );
  }
}

class _PluginCard extends StatelessWidget {
  const _PluginCard({required this.plugin});

  final PlatformPlugin plugin;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: () => context.go(plugin.routePath),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(PlatformSpacing.md),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(plugin.icon, size: 40, color: PlatformColors.primary),
              const SizedBox(height: PlatformSpacing.sm),
              Text(
                plugin.name,
                style: PlatformTextStyles.title,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: PlatformSpacing.xs),
              Text(
                plugin.description,
                style: PlatformTextStyles.caption.copyWith(
                  color: ThemeColors.of(context).onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}