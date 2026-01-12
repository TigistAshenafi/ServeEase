import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

class RatingDialog extends StatefulWidget {
  final ServiceRequest request;
  final bool isProviderReview;

  const RatingDialog({
    super.key,
    required this.request,
    required this.isProviderReview,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _rating = 0;
  final _reviewController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.isProviderReview ? 'Rate Customer' : 'Rate Service Provider',
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service/Customer info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        widget.isProviderReview ? Colors.blue : Colors.orange,
                    child: Icon(
                      widget.isProviderReview ? Icons.person : Icons.business,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isProviderReview
                              ? widget.request.seeker.name
                              : (widget.request.provider.businessName ??
                                  widget.request.provider.name),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          widget.request.service.title,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Rating stars
            const Text(
              'Rating',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return GestureDetector(
                  onTap: () => setState(() => _rating = index + 1),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
            if (_rating > 0) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _getRatingText(_rating),
                  style: TextStyle(
                    color: _getRatingColor(_rating),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),

            // Review text
            const Text(
              'Review (Optional)',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _reviewController,
              decoration: InputDecoration(
                hintText: widget.isProviderReview
                    ? 'Share your experience with this customer...'
                    : 'Share your experience with this service...',
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
              maxLength: 500,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Submit'),
        ),
      ],
    );
  }

  Future<void> _submitRating() async {
    setState(() => _isSubmitting = true);

    final provider = context.read<ServiceRequestProvider>();
    final result = await provider.addRating(
      requestId: widget.request.id,
      rating: _rating,
      review: _reviewController.text.trim().isEmpty
          ? null
          : _reviewController.text.trim(),
      isProviderReview: widget.isProviderReview,
    );

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.success
              ? 'Rating submitted successfully!'
              : result.message),
          backgroundColor: result.success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  String _getRatingText(int rating) {
    switch (rating) {
      case 1:
        return 'Poor';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Very Good';
      case 5:
        return 'Excellent';
      default:
        return '';
    }
  }

  Color _getRatingColor(int rating) {
    switch (rating) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow[700]!;
      case 4:
        return Colors.lightGreen;
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
