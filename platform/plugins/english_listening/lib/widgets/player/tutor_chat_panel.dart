import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

import '../../models/subtitle.dart';
import '../../services/ai_service.dart';

class TutorChatPanel extends StatefulWidget {
  final AIService aiService;
  final String currentSubtitle;
  final List<String> contextSubtitles;

  const TutorChatPanel({
    super.key,
    required this.aiService,
    required this.currentSubtitle,
    this.contextSubtitles = const [],
  });

  @override
  State<TutorChatPanel> createState() => _TutorChatPanelState();
}

class _TutorChatPanelState extends State<TutorChatPanel> {
  final List<TutorChatMessage> _messages = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _inputFocusNode = FocusNode();
  bool _isLoading = false;
  String? _error;

  static const _quickQuestions = [
    '这句话的语法怎么分析？',
    '这里有什么固定搭配吗？',
    '这句话用口语怎么说？',
    '有什么需要注意的发音？',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(TutorChatMessage(
      role: 'assistant',
      content: '你好！我是你的 AI 英语同桌 👋\n\n'
          '当前字幕：*${widget.currentSubtitle}*\n\n'
          '你可以问我任何关于这句话的问题，比如语法、词汇、发音、文化背景等。也可以直接点击下面的快捷问题。',
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _inputFocusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading) return;

    setState(() {
      _messages.add(TutorChatMessage(
        role: 'user',
        content: text.trim(),
        timestamp: DateTime.now(),
      ));
      _isLoading = true;
      _error = null;
    });
    _inputController.clear();
    _scrollToBottom();

    final answer = await widget.aiService.tutorChat(
      question: text.trim(),
      currentSubtitle: widget.currentSubtitle,
      contextSubtitles: widget.contextSubtitles,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (answer != null) {
        _messages.add(TutorChatMessage(
          role: 'assistant',
          content: answer,
          timestamp: DateTime.now(),
        ));
      } else {
        _error = 'AI 服务暂时不可用，请检查后端是否启动';
      }
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        const Divider(height: 1),
        _buildQuickQuestions(),
        const Divider(height: 1),
        Expanded(child: _buildMessageList()),
        if (_error != null) _buildErrorBanner(),
        _buildInputArea(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.sm,
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PlatformColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.school, size: 20, color: PlatformColors.primary),
          ),
          const SizedBox(width: PlatformSpacing.sm),
          const Expanded(
            child: Text(
              'AI 英语同桌',
              style: PlatformTextStyles.title,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: '关闭',
          ),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.xs,
      ),
      child: Wrap(
        spacing: PlatformSpacing.xs,
        runSpacing: PlatformSpacing.xs,
        children: _quickQuestions.map((q) {
          return ActionChip(
            label: Text(q, style: const TextStyle(fontSize: 12)),
            onPressed: _isLoading ? null : () => _sendMessage(q),
            visualDensity: VisualDensity.compact,
            backgroundColor: PlatformColors.primary.withAlpha(15),
            side: BorderSide.none,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: PlatformSpacing.md,
        vertical: PlatformSpacing.sm,
      ),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildLoadingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlatformSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: PlatformColors.primary.withAlpha(30),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.school, size: 16, color: PlatformColors.primary),
          ),
          const SizedBox(width: PlatformSpacing.sm),
          Container(
            constraints: const BoxConstraints(maxWidth: 280),
            padding: const EdgeInsets.all(PlatformSpacing.sm),
            decoration: BoxDecoration(
              color: ThemeColors.of(context).background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const SizedBox(
              width: 60,
              height: 20,
              child: Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(TutorChatMessage message) {
    final isUser = message.isUser;
    final theme = ThemeColors.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PlatformSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: PlatformColors.primary.withAlpha(30),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.school, size: 16, color: PlatformColors.primary),
            ),
            const SizedBox(width: PlatformSpacing.sm),
          ],
          Flexible(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 280),
              padding: const EdgeInsets.all(PlatformSpacing.sm),
              decoration: BoxDecoration(
                color: isUser ? PlatformColors.primary : theme.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SelectableText(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: isUser ? Colors.white : theme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: PlatformSpacing.sm),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: PlatformColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.person, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PlatformSpacing.sm),
      color: PlatformColors.error.withAlpha(20),
      child: Row(
        children: [
          const Icon(Icons.warning_amber, size: 16, color: PlatformColors.error),
          const SizedBox(width: PlatformSpacing.xs),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(fontSize: 12, color: PlatformColors.error),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _error = null),
            child: const Text('关闭', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(PlatformSpacing.sm),
      decoration: BoxDecoration(
        color: ThemeColors.of(context).background,
        border: Border(
          top: BorderSide(color: ThemeColors.of(context).outline),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              focusNode: _inputFocusNode,
              autofocus: false,
              decoration: InputDecoration(
                hintText: '输入你的问题...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: ThemeColors.of(context).background,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: PlatformSpacing.md,
                  vertical: PlatformSpacing.sm,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              textInputAction: TextInputAction.send,
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: PlatformSpacing.xs),
          IconButton(
            icon: Icon(
              Icons.send,
              color: _isLoading
                  ? ThemeColors.of(context).onSurfaceVariant
                  : PlatformColors.primary,
            ),
            onPressed: _isLoading
                ? null
                : () => _sendMessage(_inputController.text),
            tooltip: '发送',
          ),
        ],
      ),
    );
  }
}