import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../models/conversation.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final VoidCallback? onReply;
  final Function(String)? onEdit;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    this.onReply,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isFromMe = message.isFromMe;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isFromMe) _buildAvatar(),
          if (!isFromMe) SizedBox(width: 8.w),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                decoration: BoxDecoration(
                  gradient: isFromMe 
                      ? LinearGradient(
                          colors: [
                            Colors.blue.shade500,
                            Colors.purple.shade500,
                          ],
                        )
                      : null,
                  color: isFromMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20.r),
                    topRight: Radius.circular(20.r),
                    bottomLeft: Radius.circular(isFromMe ? 20.r : 6.r),
                    bottomRight: Radius.circular(isFromMe ? 6.r : 20.r),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: isFromMe 
                          ? Colors.blue.withValues(alpha: 0.2)
                          : Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.replyTo != null) _buildReplyPreview(),
                    _buildMessageContent(isFromMe),
                    SizedBox(height: 6.h),
                    _buildMessageInfo(isFromMe),
                  ],
                ),
              ),
            ),
          ),
          if (isFromMe) SizedBox(width: 8.w),
          if (isFromMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 18.r,
        backgroundColor: Colors.grey[300],
        backgroundImage: message.sender.avatarUrl != null
            ? CachedNetworkImageProvider(message.sender.avatarUrl!)
            : null,
        child: message.sender.avatarUrl == null
            ? Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      Colors.blue.shade300,
                      Colors.purple.shade300,
                    ],
                  ),
                ),
                child: Center(
                  child: Text(
                    message.sender.name.isNotEmpty
                        ? message.sender.name[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border(
          left: BorderSide(
            color: message.isFromMe ? Colors.white70 : Colors.blue.shade400,
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.replyTo!.senderName,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: message.isFromMe ? Colors.white70 : Colors.blue.shade600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            message.replyTo!.content,
            style: TextStyle(
              fontSize: 13.sp,
              color: message.isFromMe ? Colors.white70 : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(bool isFromMe) {
    switch (message.messageType) {
      case MessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w400,
            color: isFromMe ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        );
      case MessageType.image:
        return _buildImageMessage();
      case MessageType.file:
        return _buildFileMessage(isFromMe);
      case MessageType.system:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 12.sp,
            fontStyle: FontStyle.italic,
            color: isFromMe ? Colors.white70 : Colors.grey[600],
          ),
        );
      default:
        return Text(
          message.content,
          style: TextStyle(
            fontSize: 14.sp,
            color: isFromMe ? Colors.white : Colors.black87,
          ),
        );
    }
  }

  Widget _buildImageMessage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.r),
      child: CachedNetworkImage(
        imageUrl: message.fileUrl!,
        width: 200.w,
        height: 200.h,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 200.w,
          height: 200.h,
          color: Colors.grey[300],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          width: 200.w,
          height: 200.h,
          color: Colors.grey[300],
          child: const Icon(Icons.error),
        ),
      ),
    );
  }

  Widget _buildFileMessage(bool isFromMe) {
    return Container(
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.attach_file,
            size: 20.r,
            color: isFromMe ? Colors.white70 : Colors.grey[600],
          ),
          SizedBox(width: 8.w),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.fileName ?? 'File',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isFromMe ? Colors.white : Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (message.fileSize != null)
                  Text(
                    _formatFileSize(message.fileSize!),
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: isFromMe ? Colors.white70 : Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInfo(bool isFromMe) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (message.isEdited)
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Text(
              'edited',
              style: TextStyle(
                fontSize: 10.sp,
                fontStyle: FontStyle.italic,
                color: isFromMe ? Colors.white70 : Colors.grey[500],
              ),
            ),
          ),
        Text(
          DateFormat('HH:mm').format(message.createdAt),
          style: TextStyle(
            fontSize: 10.sp,
            color: isFromMe ? Colors.white70 : Colors.grey[500],
          ),
        ),
        if (isFromMe) ...[
          SizedBox(width: 4.w),
          _buildMessageStatus(),
        ],
      ],
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color = Colors.white70;

    switch (message.status) {
      case MessageStatus.sending:
        icon = Icons.access_time;
        break;
      case MessageStatus.sent:
        icon = Icons.check;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        break;
      case MessageStatus.read:
        icon = Icons.done_all;
        color = Colors.blue;
        break;
      case MessageStatus.failed:
        icon = Icons.error;
        color = Colors.red;
        break;
    }

    return Icon(
      icon,
      size: 12.r,
      color: color,
    );
  }

  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(context);
                  onReply!();
                },
              ),
            if (message.isFromMe && onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(context);
                },
              ),
            if (message.isFromMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Message'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter new message...',
          ),
          maxLines: null,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit!(controller.text.trim());
              }
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              onDelete!();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}