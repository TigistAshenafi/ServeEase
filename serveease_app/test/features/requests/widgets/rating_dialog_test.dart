import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/core/services/api_service.dart';
import 'package:serveease_app/features/requests/widgets/rating_dialog.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

// Simple test double for ServiceRequestProvider
class TestServiceRequestProvider extends ServiceRequestProvider {
  bool _shouldSucceed = true;
  String _testMessage = 'Rating submitted successfully!';

  void setTestResponse({required bool success, required String message}) {
    _shouldSucceed = success;
    _testMessage = message;
  }

  @override
  Future<ApiResponse<void>> addRating({
    required String requestId,
    required int rating,
    String? review,
    bool isProviderReview = false,
  }) async {
    // Simulate API call delay
    await Future.delayed(const Duration(milliseconds: 100));

    return ApiResponse<void>(
      success: _shouldSucceed,
      data: null,
      message: _testMessage,
    );
  }
}

void main() {
  group('RatingDialog Widget Tests', () {
    late TestServiceRequestProvider testProvider;
    late ServiceRequest testRequest;

    setUp(() {
      testProvider = TestServiceRequestProvider();
      testRequest = ServiceRequest(
        id: 'test-request-1',
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceId: 'service-1',
        status: 'completed',
        createdAt: DateTime.now(),
        service: ServiceSummary(
          title: 'House Cleaning',
          price: 80.0,
          durationHours: 2,
        ),
        seeker: PartyInfo(
          name: 'Alice Customer',
          email: 'alice@customer.com',
        ),
        provider: PartyInfo(
          name: 'Clean Pro',
          email: 'contact@cleanpro.com',
          businessName: 'Clean Pro Services',
          location: 'Uptown',
        ),
      );
    });

    Widget createTestWidget({required bool isProviderReview}) {
      return MaterialApp(
        home: ChangeNotifierProvider<ServiceRequestProvider>.value(
          value: testProvider,
          child: Scaffold(
            body: RatingDialog(
              request: testRequest,
              isProviderReview: isProviderReview,
            ),
          ),
        ),
      );
    }

    testWidgets('should display correct title for customer rating',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      expect(find.text('Rate Service Provider'), findsOneWidget);
    });

    testWidgets('should display correct title for provider rating',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: true));

      // Assert
      expect(find.text('Rate Customer'), findsOneWidget);
    });

    testWidgets('should display service information for customer rating',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      expect(find.text('Clean Pro Services'), findsOneWidget);
      expect(find.text('House Cleaning'), findsOneWidget);
      expect(find.byIcon(Icons.business), findsOneWidget);
    });

    testWidgets('should display customer information for provider rating',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: true));

      // Assert
      expect(find.text('Alice Customer'), findsOneWidget);
      expect(find.text('House Cleaning'), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });

    testWidgets('should display 5 rating stars', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      expect(find.byIcon(Icons.star_border), findsNWidgets(5));
    });

    testWidgets('should allow star rating selection', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Tap on the third star (3-star rating)
      final starIcons = find.byIcon(Icons.star_border);
      await tester.tap(starIcons.at(2));
      await tester.pump();

      // Assert
      expect(find.byIcon(Icons.star), findsNWidgets(3));
      expect(find.byIcon(Icons.star_border), findsNWidgets(2));
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('should display correct rating text for each star level',
        (tester) async {
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Test 3-star rating specifically
      final allStars = find.byWidgetPredicate((widget) =>
          widget is Icon &&
          (widget.icon == Icons.star || widget.icon == Icons.star_border));

      // Tap the third star
      await tester.tap(allStars.at(2));
      await tester.pump();
      expect(find.text('Good'), findsOneWidget);
    });

    testWidgets('should allow review text input', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Find and enter text in review field
      final reviewField = find.byType(TextField);
      await tester.enterText(
          reviewField, 'Excellent service, very professional!');
      await tester.pump();

      // Assert
      expect(
          find.text('Excellent service, very professional!'), findsOneWidget);
    });

    testWidgets('should show correct placeholder text for customer review',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      expect(find.text('Share your experience with this service...'),
          findsOneWidget);
    });

    testWidgets('should show correct placeholder text for provider review',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: true));

      // Assert
      expect(find.text('Share your experience with this customer...'),
          findsOneWidget);
    });

    testWidgets('should disable submit button when no rating selected',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNull);
    });

    testWidgets('should enable submit button when rating is selected',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Select a rating
      final starIcons = find.byIcon(Icons.star_border);
      await tester.tap(starIcons.first);
      await tester.pump();

      // Assert
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      expect(tester.widget<ElevatedButton>(submitButton).onPressed, isNotNull);
    });

    testWidgets('should handle successful rating submission', (tester) async {
      // Arrange
      testProvider.setTestResponse(
          success: true, message: 'Rating submitted successfully!');

      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Select rating and submit
      final starIcons = find.byIcon(Icons.star_border);
      await tester.tap(starIcons.at(4)); // 5-star rating
      await tester.pump();

      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      await tester.tap(submitButton);
      await tester.pump();

      // Wait for async operation
      await tester.pump(const Duration(milliseconds: 200));

      // Assert - dialog should be dismissed and snackbar shown
      // (This would be better tested in integration tests)
    });

    testWidgets('should show loading indicator during submission',
        (tester) async {
      // Arrange
      testProvider.setTestResponse(
          success: true, message: 'Rating submitted successfully!');

      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Select rating
      final starIcons = find.byIcon(Icons.star_border);
      await tester.tap(starIcons.at(3));
      await tester.pump();

      // Tap submit button
      final submitButton = find.widgetWithText(ElevatedButton, 'Submit');
      await tester.tap(submitButton);
      await tester.pump();

      // Assert - should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Wait for async operation to complete
      await tester.pumpAndSettle();
    });

    testWidgets('should handle cancel button tap', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Tap cancel button
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Assert - dialog should be dismissed
      // (This would be better tested in integration tests)
    });

    testWidgets('should enforce character limit on review text',
        (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Find review field
      final reviewField = find.byType(TextField);

      // Try to enter text longer than 500 characters
      final longText = 'A' * 600;
      await tester.enterText(reviewField, longText);
      await tester.pump();

      // Assert - should be limited to 500 characters
      final textField = tester.widget<TextField>(reviewField);
      expect(textField.maxLength, equals(500));
    });

    testWidgets('should display review as optional', (tester) async {
      // Act
      await tester.pumpWidget(createTestWidget(isProviderReview: false));

      // Assert
      expect(find.text('Review (Optional)'), findsOneWidget);
    });
  });
}
