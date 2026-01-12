// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/conversation.dart';
import 'package:intl/intl.dart';

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
    final isMe = message.isFromMe;
    
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) _buildAvatar(),
          if (!isMe) SizedBox(width: 8.w),
          
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showMessageOptions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                child: Column(
                  crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    // Reply preview
                    if (message.replyTo != null) _buildReplyPreview(context),
                    
                    // Message content
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: isMe 
                            ? Theme.of(context).primaryColor 
                            : Colors.grey[200],
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.r),
                          topRight: Radius.circular(16.r),
                          bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
                          bottomRight: Radius.circular(isMe ? 4.r : 16.r),
                        ),
                      ),
                      child: _buildMessageContent(context),
                    ),
                    
                    // Message info
                    SizedBox(height: 2.h),
                    _buildMessageInfo(context),
                  ],
                ),
              ),
            ),
          ),
          
          if (isMe) SizedBox(width: 8.w),
          if (isMe) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return CircleAvatar(
      radius: 12.r,
      backgroundColor: Colors.grey[300],
      backgroundImage: message.sender.avatarUrl != null
          ? CachedNetworkImageProvider(message.sender.avatarUrl!)
          : null,
      child: message.sender.avatarUrl == null
          ? Text(
              message.sender.name.isNotEmpty
                  ? message.sender.name[0].toUpperCase()
                  : '?',
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  Widget _buildReplyPreview(BuildContext context) {
    final reply = message.replyTo!;
    final isMe = message.isFromMe;
    
    return Container(
      margin: EdgeInsets.only(bottom: 4.h),
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isMe 
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
        border: Border(
          left: BorderSide(
            color: isMe 
                ? Colors.white 
                : Theme.of(context).primaryColor,
            width: 3.w,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            reply.senderName,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: isMe 
                  ? Colors.white.withOpacity(0.8)
                  : Theme.of(context).primaryColor,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            reply.content,
            style: TextStyle(
              fontSize: 12.sp,
              color: isMe 
                  ? Colors.white.withOpacity(0.7)
                  : Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (message.messageType) {
      case MessageType.text:
        return _buildTextMessage(context);
      case MessageType.image:
        return _buildImageMessage(context);
      case MessageType.file:
        return _buildFileMessage(context);
      case MessageType.location:
        return _buildLocationMessage(context);
      case MessageType.system:
        return _buildSystemMessage(context);
    }
  }

  Widget _buildTextMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 14.sp,
        color: message.isFromMe ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildImageMessage(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.content.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Text(
              message.content,
              style: TextStyle(
                fontSize: 14.sp,
                color: message.isFromMe ? Colors.white : Colors.black87,
              ),
            ),
          ),
        GestureDetector(
          onTap: () => _showImageViewer(context),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: 200.w,
              maxHeight: 200.h,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              color: Colors.grey[300],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8.r),
              child: message.fileUrl != null
                  ? CachedNetworkImage(
                      imageUrl: message.fileUrl!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => SizedBox(
                        height: 100.h,
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => SizedBox(
                        height: 100.h,
                        child: const Center(
                          child: Icon(Icons.error),
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 100.h,
                      child: const Center(
                        child: Icon(Icons.image),
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFileMessage(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFile(),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: message.isFromMe 
              ? Colors.white.withOpacity(0.1)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.insert_drive_file,
              color: message.isFromMe ? Colors.white : Colors.grey[600],
              size: 24.r,
            ),
            SizedBox(width: 8.w),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.fileName ?? 'File',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: message.isFromMe ? Colors.white : Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (message.fileSize != null)
                    Text(
                      _formatFileSize(message.fileSize!),
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: message.isFromMe 
                            ? Colors.white.withOpacity(0.7)
                            : Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationMessage(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: message.isFromMe 
            ? Colors.white.withOpacity(0.1)
            : Colors.grey[100],
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_on,
            color: message.isFromMe ? Colors.white : Colors.red,
            size: 24.r,
          ),
          SizedBox(width: 8.w),
          Text(
            'Location',
            style: TextStyle(
              fontSize: 14.sp,
              color: message.isFromMe ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemMessage(BuildContext context) {
    return Text(
      message.content,
      style: TextStyle(
        fontSize: 12.sp,
        color: Colors.grey[600],
        fontStyle: FontStyle.italic,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildMessageInfo(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edited indicator
        if (message.isEdited)
          Padding(
            padding: EdgeInsets.only(right: 4.w),
            child: Text(
              'edited',
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.grey[500],
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        
        // Time
        Text(
          DateFormat('HH:mm').format(message.createdAt),
          style: TextStyle(
            fontSize: 10.sp,
            color: Colors.grey[500],
          ),
        ),
        
        // Read status (for sent messages)
        if (message.isFromMe) ...[
          SizedBox(width: 4.w),
          Icon(
            message.readCount > 0 ? Icons.done_all : Icons.done,
            size: 12.r,
            color: message.readCount > 0 ? Colors.blue : Colors.grey[500],
          ),
        ],
      ],
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
            
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: message.content));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Message copied')),
                );
              },
            ),
            
            if (message.isFromMe && onEdit != null && message.messageType == MessageType.text)
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
              Navigator.pop(context);
              onDelete!();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showImageViewer(BuildContext context) {
    if (message.fileUrl == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(message.fileUrl!),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  void _openFile() async {
    if (message.fileUrl != null) {
      final uri = Uri.parse(message.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      }
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}