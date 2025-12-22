import 'package:flutter/material.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';
// import 'package:serveease_app/core/models/api_response.dart';
// import 'package:serveease_app/core/models/service_model.dart';

class ServiceCard extends StatefulWidget {
  final String title;
  final String description;
  final String providerName;
  final double price;
  final double rating;
  final int reviewCount;
  final String? imageUrl;
  final String category;
  final bool isAvailable;
  final VoidCallback? onTap;
  final VoidCallback? onFavorite;
  final bool isFavorite;
  final String duration;

  const ServiceCard({
    Key? key,
    required this.title,
    required this.description,
    required this.providerName,
    required this.price,
    required this.rating,
    required this.reviewCount,
    this.imageUrl,
    required this.category,
    this.isAvailable = true,
    this.onTap,
    this.onFavorite,
    this.isFavorite = false,
    required this.duration,
  }) : super(key: key);

  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Card(
              elevation: _elevationAnimation.value,
              shadowColor: colorScheme.shadow.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.surface,
                      colorScheme.surface.withOpacity(0.8),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildImageSection(context, colorScheme),
                    _buildContentSection(context, theme, colorScheme),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildImageSection(BuildContext context, ColorScheme colorScheme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
          child: Container(
            height: 160,
            width: double.infinity,
            child: widget.imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: widget.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => _buildImagePlaceholder(),
                    errorWidget: (context, url, error) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
          ),
        ),
        
        // Category badge
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.category,
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),

        // Favorite button
        if (widget.onFavorite != null)
          Positioned(
            top: 12,
            right: 12,
            child: GestureDetector(
              onTap: widget.onFavorite,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: widget.isFavorite ? Colors.red : Colors.grey[600],
                  size: 20,
                ),
              ),
            ),
          ),

        // Availability indicator
        if (!widget.isAvailable)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: const Center(
                child: Text(
                  'Currently Unavailable',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Icon(
        Icons.image_outlined,
        size: 48,
        color: Colors.grey[400],
      ),
    );
  }

  Widget _buildContentSection(BuildContext context, ThemeData theme, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            widget.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Provider name
          Text(
            'by ${widget.providerName}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Description
          Text(
            widget.description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 12),
          
          // Rating and reviews
          Row(
            children: [
              RatingBarIndicator(
                rating: widget.rating,
                itemBuilder: (context, index) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                itemCount: 5,
                itemSize: 16.0,
              ),
              const SizedBox(width: 4),
              Text(
                '${widget.rating}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '(${widget.reviewCount})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Price and duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Starting at',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '\$${widget.price.toStringAsFixed(0)}',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.duration,
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Shimmer loading card
class ServiceCardShimmer extends StatelessWidget {
  const ServiceCardShimmer({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    height: 20,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 120,
                    height: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 200,
                    height: 14,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        width: 80,
                        height: 24,
                        color: Colors.white,
                      ),
                      Container(
                        width: 60,
                        height: 20,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}