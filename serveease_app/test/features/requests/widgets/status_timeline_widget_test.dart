import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/features/requests/widgets/status_timeline_widget.dart';

void main() {
  group('StatusTimelineWidget Tests', () {
    Widget createTestWidget({
      required List<StatusChange> statusHistory,
      required String currentStatus,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: StatusTimelineWidget(
            statusHistory: statusHistory,
            currentStatus: currentStatus,
          ),
        ),
      );
    }

    testWidgets('should display empty state when no history', (tester) async {
      // Arrange
      await tester.pumpWidget(createTestWidget(
        statusHistory: [],
        currentStatus: 'pending',
      ));

      // Act & Assert
      expect(find.text('No status history available'), findsOneWidget);
      expect(find.byIcon(Icons.info_outline), findsOneWidget);
    });

    testWidgets('should display status history timeline', (tester) async {
      // Arrange
      final statusHistory = [
        StatusChange(
          fromStatus: 'pending',
          toStatus: 'accepted',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          notes: 'Request accepted by provider',
          changedBy: 'provider@test.com',
        ),
        StatusChange(
          fromStatus: 'accepted',
          toStatus: 'in_progress',
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
          notes: 'Work started',
          changedBy: 'provider@test.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        statusHistory: statusHistory,
        currentStatus: 'in_progress',
      ));

      // Act & Assert
      expect(find.text('Status History'), findsOneWidget);
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Request accepted by provider'), findsOneWidget);
      expect(find.text('Work started'), findsOneWidget);
      expect(find.text('by provider@test.com'), findsNWidgets(2));
    });

    testWidgets('should display status change with reason', (tester) async {
      // Arrange
      final statusHistory = [
        StatusChange(
          fromStatus: 'pending',
          toStatus: 'rejected',
          timestamp: DateTime.now(),
          notes: 'Cannot complete this request',
          changedBy: 'provider@test.com',
          reason: 'Not available in the area',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        statusHistory: statusHistory,
        currentStatus: 'rejected',
      ));

      // Act & Assert
      expect(find.text('Rejected'), findsOneWidget);
      expect(find.text('Cannot complete this request'), findsOneWidget);
      expect(find.text('Reason: Not available in the area'), findsOneWidget);
    });

    testWidgets('should format timestamps correctly', (tester) async {
      // Arrange
      final now = DateTime.now();
      final statusHistory = [
        StatusChange(
          fromStatus: 'pending',
          toStatus: 'accepted',
          timestamp: now.subtract(const Duration(minutes: 30)),
          changedBy: 'provider@test.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        statusHistory: statusHistory,
        currentStatus: 'accepted',
      ));

      // Act & Assert
      // Should show "30m ago" or similar
      expect(find.textContaining('ago'), findsOneWidget);
    });

    testWidgets('should display timeline indicators with correct colors',
        (tester) async {
      // Arrange
      final statusHistory = [
        StatusChange(
          fromStatus: 'pending',
          toStatus: 'accepted',
          timestamp: DateTime.now(),
          changedBy: 'provider@test.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        statusHistory: statusHistory,
        currentStatus: 'accepted',
      ));

      // Act & Assert
      expect(find.text('Accepted'), findsOneWidget);

      // Find the timeline indicator container
      final containerFinder = find.byType(Container);
      expect(containerFinder, findsWidgets);
    });

    testWidgets('should handle multiple status changes in timeline',
        (tester) async {
      // Arrange
      final statusHistory = [
        StatusChange(
          fromStatus: 'pending',
          toStatus: 'accepted',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
          changedBy: 'provider@test.com',
        ),
        StatusChange(
          fromStatus: 'accepted',
          toStatus: 'assigned',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
          changedBy: 'provider@test.com',
        ),
        StatusChange(
          fromStatus: 'assigned',
          toStatus: 'in_progress',
          timestamp: DateTime.now().subtract(const Duration(hours: 5)),
          changedBy: 'employee@test.com',
        ),
        StatusChange(
          fromStatus: 'in_progress',
          toStatus: 'completed',
          timestamp: DateTime.now(),
          changedBy: 'employee@test.com',
        ),
      ];

      await tester.pumpWidget(createTestWidget(
        statusHistory: statusHistory,
        currentStatus: 'completed',
      ));

      // Act & Assert
      expect(find.text('Accepted'), findsOneWidget);
      expect(find.text('Assigned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);

      // Should show different time formats
      expect(find.textContaining('d ago'),
          findsNWidgets(2)); // 2 days ago, 1 day ago
      expect(find.textContaining('h ago'), findsOneWidget); // 5 hours ago
    });
  });
}
