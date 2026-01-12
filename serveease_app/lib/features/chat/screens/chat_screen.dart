import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../widgets/message_bubble.dart';
import '../widgets/typing_indicator.dart' as typing_widget;
import 'package:intl/intl.dart';
import 'package:serveease_app/shared/widgets/app_bar_language_toggle.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;

  const ChatScreen({
    super.key,
    required this.conversationId,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();

  bool _showEmojiPicker = false;
  Timer? _typingTimer;
  bool _isTyping = false;
  Message? _replyToMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversationId);
    });

    // Listen to text changes for typing indicator
    _messageController.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _typingTimer?.cancel();

    // Leave conversation when screen is disposed
    context.read<ChatProvider>().leaveCurrentConversation();
    super.dispose();
  }

  void _onTextChanged() {
    if (_messageController.text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      context.read<ChatProvider>().startTyping(widget.conversationId);
    }

    // Reset typing timer
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 2), () {
      if (_isTyping) {
        _isTyping = false;
        context.read<ChatProvider>().stopTyping(widget.conversationId);
      }
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    context.read<ChatProvider>().sendMessage(
          conversationId: widget.conversationId,
          content: text,
          replyToMessageId: _replyToMessage?.id,
        );

    _messageController.clear();
    _replyToMessage = null;
    _isTyping = false;
    context.read<ChatProvider>().stopTyping(widget.conversationId);

    // Scroll to bottom after sending
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null && mounted) {
      final file = File(image.path);
      context.read<ChatProvider>().sendFileMessage(
            conversationId: widget.conversationId,
            file: file,
            messageType: MessageType.image,
          );
    }
  }

  void _pickFile() async {
    final result = await FilePicker.platform.pickFiles();

    if (result != null && result.files.single.path != null && mounted) {
      final file = File(result.files.single.path!);
      context.read<ChatProvider>().sendFileMessage(
            conversationId: widget.conversationId,
            file: file,
            messageType: MessageType.file,
          );
    }
  }

  void _setReplyToMessage(Message message) {
    setState(() {
      _replyToMessage = message;
    });
    _messageFocusNode.requestFocus();
  }

  void _cancelReply() {
    setState(() {
      _replyToMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoadingMessages &&
              chatProvider.currentMessages.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return Column(
            children: [
              // Messages list
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: chatProvider.currentMessages.length +
                      1, // +1 for typing indicator
                  itemBuilder: (context, index) {
                    if (index == chatProvider.currentMessages.length) {
                      // Typing indicator at the end
                      return _buildTypingIndicator(chatProvider);
                    }

                    final message = chatProvider.currentMessages[index];
                    final previousMessage = index > 0
                        ? chatProvider.currentMessages[index - 1]
                        : null;
                    final showDateSeparator =
                        _shouldShowDateSeparator(message, previousMessage);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _buildDateSeparator(message.createdAt),
                        MessageBubble(
                          message: message,
                          onReply: () => _setReplyToMessage(message),
                          onEdit: (newContent) {
                            chatProvider.editMessage(message.id, newContent);
                          },
                          onDelete: () {
                            chatProvider.deleteMessage(message.id);
                          },
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Reply preview
              if (_replyToMessage != null) _buildReplyPreview(),

              // Message input
              _buildMessageInput(),

              // Emoji picker
              if (_showEmojiPicker) _buildEmojiPicker(),
            ],
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          final conversation = chatProvider.currentConversation;
          if (conversation == null) {
            return const Text('Chat');
          }

          final otherUser = conversation.otherParticipant;
          final isOnline = chatProvider.isUserOnline(otherUser.id);

          return Row(
            children: [
              CircleAvatar(
                radius: 18.r,
                backgroundColor: Colors.grey[300],
                backgroundImage: otherUser.avatarUrl != null
                    ? CachedNetworkImageProvider(otherUser.avatarUrl!)
                    : null,
                child: otherUser.avatarUrl == null
                    ? Text(
                        otherUser.name.isNotEmpty
                            ? otherUser.name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherUser.name,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isOnline)
                      Text(
                        'Online',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      actions: [
        // Language Toggle
        const AppBarLanguageToggle(
          iconColor: Colors.grey,
          textColor: Colors.black,
          isCompact: true,
        ),
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            return PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'archive':
                    chatProvider.archiveConversation(widget.conversationId);
                    Navigator.pop(context);
                    break;
                  case 'block':
                    _showBlockDialog(chatProvider);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'archive',
                  child: Text('Archive'),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block'),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildTypingIndicator(ChatProvider chatProvider) {
    final conversation = chatProvider.currentConversation;
    if (conversation == null) return const SizedBox.shrink();

    final otherUserId = conversation.otherParticipant.id;
    final isTyping = chatProvider.isUserTyping(otherUserId);

    if (!isTyping) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12.r,
            backgroundColor: Colors.grey[300],
            child: Text(
              conversation.otherParticipant.name[0].toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          const typing_widget.TypingIndicator(),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 4.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${_replyToMessage!.sender.name}',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  _replyToMessage!.content,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: _cancelReply,
            iconSize: 20.r,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Attachment button
          IconButton(
            icon: const Icon(Icons.attach_file),
            onPressed: () {
              _showAttachmentOptions();
            },
          ),

          // Text input
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: _messageFocusNode,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                      ),
                      maxLines: null,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                      if (_showEmojiPicker) {
                        _messageFocusNode.unfocus();
                      } else {
                        _messageFocusNode.requestFocus();
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          SizedBox(width: 8.w),

          // Send button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return SizedBox(
      height: 250.h,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          _messageController.text += emoji.emoji;
        },
        config: Config(
          height: 250.h,
          checkPlatformCompatibility: true,
          emojiViewConfig: EmojiViewConfig(
            emojiSizeMax: 28.r,
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo, color: Colors.blue),
              title: const Text('Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_file, color: Colors.grey),
              title: const Text('File'),
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBlockDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block User'),
        content: const Text(
            'Are you sure you want to block this user? You won\'t receive messages from them anymore.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              chatProvider.blockConversation(widget.conversationId);
              Navigator.pop(context);
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(Message current, Message? previous) {
    if (previous == null) return true;

    final currentDate = DateTime(
      current.createdAt.year,
      current.createdAt.month,
      current.createdAt.day,
    );
    final previousDate = DateTime(
      previous.createdAt.year,
      previous.createdAt.month,
      previous.createdAt.day,
    );

    return !currentDate.isAtSameMomentAs(previousDate);
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate.isAtSameMomentAs(today)) {
      return 'Today';
    } else if (messageDate.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('MMMM dd, yyyy').format(date);
    }
  }
}
