// lib/widgets/certificate_card.dart
import 'package:flutter/material.dart';

class CertificateCard extends StatelessWidget {
  final String fileName;
  final VoidCallback onRemove;

  const CertificateCard({
    super.key,
    required this.fileName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.picture_as_pdf,
                    color: Colors.blue.shade600,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _truncateFileName(fileName),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getFileSize(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close,
                  color: Colors.red.shade600,
                  size: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _truncateFileName(String name) {
    if (name.length > 20) {
      return '${name.substring(0, 15)}...${name.substring(name.lastIndexOf('.'))}';
    }
    return name;
  }

  String _getFileSize() {
    return '2.4 MB'; // This would be calculated from actual file
  }
}