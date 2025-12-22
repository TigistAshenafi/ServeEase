import 'package:flutter/material.dart';

class CategoryChip extends StatelessWidget {
  final Map<String, dynamic> category;
  final bool isSelected;
  final VoidCallback onSelected;

  const CategoryChip({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? (category['color'] as Color).withOpacity(0.1)
              : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? category['color'] as Color
                : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (category['color'] as Color).withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              category['icon'] as IconData,
              color: isSelected
                  ? category['color'] as Color
                  : Colors.grey.shade600,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              category['name'] as String,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? category['color'] as Color
                    : Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}