import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/models/service_request_model.dart';
import 'package:serveease_app/providers/service_request_provider.dart';

void main() {
  group('ServiceRequestProvider Tests', () {
    late ServiceRequestProvider provider;

    setUp(() {
      provider = ServiceRequestProvider();
    });

    group('State Management', () {
      test('should initialize with empty state', () {
        expect(provider.requests, isEmpty);
        expect(provider.selectedRequest, isNull);
        expect(provider.statusHistory, isEmpty);
        expect(provider.availableEmployees, isEmpty);
        expect(provider.analytics, isNull);
        expect(provider.isLoading, isFalse);
        expect(provider.isUpdating, isFalse);
        expect(provider.error, isNull);
      });

      test('should clear selected request and related data', () {
        // Arrange
        provider.selectedRequest = _createTestRequest();
        provider.statusHistory = [_createTestStatusChange()];
        provider.availableEmployees = [_createTestEmployee()];

        // Act
        provider.clearSelectedRequest();

        // Assert
        expect(provider.selectedRequest, isNull);
        expect(provider.statusHistory, isEmpty);
        expect(provider.availableEmployees, isEmpty);
      });

      test('should clear error', () {
        // Arrange
        provider.error = 'Test error';

        // Act
        provider.clearError();

        // Assert
        expect(provider.error, isNull);
      });
    });

    group('Request Filtering and Utilities', () {
      test('should filter requests by status', () {
        // Arrange
        provider.requests = [
          _createTestRequest(id: 'req-1', status: 'pending'),
          _createTestRequest(id: 'req-2', status: 'accepted'),
          _createTestRequest(id: 'req-3', status: 'completed'),
          _createTestRequest(id: 'req-4', status: 'pending'),
          _createTestRequest(id: 'req-5', status: 'in_progress'),
        ];

        // Act & Assert
        expect(provider.getRequestsByStatus('pending').length, equals(2));
        expect(provider.getRequestsByStatus('accepted').length, equals(1));
        expect(provider.getRequestsByStatus('completed').length, equals(1));
        expect(provider.getRequestsByStatus('in_progress').length, equals(1));
        expect(provider.getRequestsByStatus('all').length, equals(5));
      });

      test('should count requests by status correctly', () {
        // Arrange
        provider.requests = [
          _createTestRequest(status: 'pending'),
          _createTestRequest(status: 'pending'),
          _createTestRequest(status: 'pending'),
          _createTestRequest(status: 'in_progress'),
          _createTestRequest(status: 'in_progress'),
          _createTestRequest(status: 'completed'),
          _createTestRequest(status: 'completed'),
          _createTestRequest(status: 'completed'),
          _createTestRequest(status: 'completed'),
        ];

        // Act & Assert
        expect(provider.pendingRequestsCount, equals(3));
        expect(provider.inProgressRequestsCount, equals(2));
        expect(provider.completedRequestsCount, equals(4));
      });

      test('should check if request can be rated correctly', () {
        // Test cases for different scenarios
        final testCases = [
          // (request, isProvider, expectedResult, description)
          (
            _createTestRequest(status: 'completed'),
            false,
            true,
            'completed request without seeker rating'
          ),
          (
            _createTestRequest(status: 'completed'),
            true,
            true,
            'completed request without provider rating'
          ),
          (
            _createTestRequest(status: 'completed', seekerRating: 5),
            false,
            false,
            'completed request with seeker rating'
          ),
          (
            _createTestRequest(status: 'completed', providerRating: 4),
            true,
            false,
            'completed request with provider rating'
          ),
          (
            _createTestRequest(status: 'pending'),
            false,
            false,
            'pending request'
          ),
          (
            _createTestRequest(status: 'in_progress'),
            true,
            false,
            'in-progress request'
          ),
        ];

        for (final (request, isProvider, expectedResult, description)
            in testCases) {
          expect(
            provider.canRateRequest(request, isProvider: isProvider),
            equals(expectedResult),
            reason: 'Failed for: $description',
          );
        }
      });
    });

    group('Request Status Helpers', () {
      test('should identify request status correctly', () {
        final testCases = [
          ('pending', true, false, false),
          ('in_progress', false, true, false),
          ('completed', false, false, true),
          ('accepted', false, false, false),
          ('rejected', false, false, false),
        ];

        for (final (status, isPending, isInProgress, isCompleted)
            in testCases) {
          final request = _createTestRequest(status: status);
          expect(request.isPending, equals(isPending),
              reason: 'isPending failed for $status');
          expect(request.isInProgress, equals(isInProgress),
              reason: 'isInProgress failed for $status');
          expect(request.isCompleted, equals(isCompleted),
              reason: 'isCompleted failed for $status');
        }
      });

      test('should identify if request requires employee assignment', () {
        final testCases = [
          (
            _createTestRequest(status: 'accepted'),
            true,
            'accepted without employee'
          ),
          (
            _createTestRequest(status: 'accepted', assignedEmployeeId: 'emp-1'),
            false,
            'accepted with employee'
          ),
          (_createTestRequest(status: 'pending'), false, 'pending status'),
          (_createTestRequest(status: 'completed'), false, 'completed status'),
        ];

        for (final (request, expected, description) in testCases) {
          expect(
            request.requiresEmployeeAssignment,
            equals(expected),
            reason: 'Failed for: $description',
          );
        }
      });

      test('should identify if request can be rated', () {
        final testCases = [
          (
            _createTestRequest(status: 'completed'),
            true,
            'completed without ratings'
          ),
          (
            _createTestRequest(
                status: 'completed', seekerRating: 5, providerRating: 4),
            false,
            'completed with both ratings'
          ),
          (
            _createTestRequest(status: 'completed', seekerRating: 5),
            true,
            'completed with seeker rating only'
          ),
          (
            _createTestRequest(status: 'completed', providerRating: 4),
            true,
            'completed with provider rating only'
          ),
          (_createTestRequest(status: 'pending'), false, 'pending status'),
        ];

        for (final (request, expected, description) in testCases) {
          expect(
            request.canBeRated,
            equals(expected),
            reason: 'Failed for: $description',
          );
        }
      });
    });

    group('Data Model Validation', () {
      test('should create service request with all required fields', () {
        final request = _createTestRequest();

        expect(request.id, isNotEmpty);
        expect(request.seekerId, isNotEmpty);
        expect(request.providerId, isNotEmpty);
        expect(request.serviceId, isNotEmpty);
        expect(request.status, isNotEmpty);
        expect(request.createdAt, isNotNull);
        expect(request.service, isNotNull);
        expect(request.seeker, isNotNull);
        expect(request.provider, isNotNull);
      });

      test('should handle optional fields correctly', () {
        final request = _createTestRequest(
          scheduledDate: DateTime.now().add(const Duration(days: 1)),
          notes: 'Test notes',
          assignedEmployeeId: 'emp-1',
        );

        expect(request.scheduledDate, isNotNull);
        expect(request.notes, equals('Test notes'));
        expect(request.assignedEmployeeId, equals('emp-1'));
      });

      test('should create status change with required fields', () {
        final statusChange = _createTestStatusChange();

        expect(statusChange.fromStatus, isNotEmpty);
        expect(statusChange.toStatus, isNotEmpty);
        expect(statusChange.timestamp, isNotNull);
      });

      test('should create employee info with required fields', () {
        final employee = _createTestEmployee();

        expect(employee.id, isNotEmpty);
        expect(employee.name, isNotEmpty);
        expect(employee.email, isNotEmpty);
        expect(employee.position, isNotEmpty);
        expect(employee.skills, isNotEmpty);
      });
    });

    group('Business Logic Validation', () {
      test('should validate urgency levels', () {
        final urgencyLevels = ['low', 'medium', 'high', 'urgent'];

        for (final urgency in urgencyLevels) {
          final request = _createTestRequest(urgency: urgency);
          expect(request.urgency, equals(urgency));
        }
      });

      test('should handle notification preferences', () {
        final requestWithNotifications =
            _createTestRequest(notificationsEnabled: true);
        final requestWithoutNotifications =
            _createTestRequest(notificationsEnabled: false);

        expect(requestWithNotifications.notificationsEnabled, isTrue);
        expect(requestWithoutNotifications.notificationsEnabled, isFalse);
      });

      test('should handle rating ranges correctly', () {
        final validRatings = [1, 2, 3, 4, 5];

        for (final rating in validRatings) {
          final request =
              _createTestRequest(seekerRating: rating, providerRating: rating);
          expect(request.seekerRating, equals(rating));
          expect(request.providerRating, equals(rating));
        }
      });
    });
  });
}

// Helper functions to create test data
ServiceRequest _createTestRequest({
  String? id,
  String? status,
  String? assignedEmployeeId,
  int? seekerRating,
  int? providerRating,
  DateTime? scheduledDate,
  String? notes,
  String? urgency,
  bool? notificationsEnabled,
}) {
  return ServiceRequest(
    id: id ?? 'test-request-${DateTime.now().millisecondsSinceEpoch}',
    seekerId: 'seeker-1',
    providerId: 'provider-1',
    serviceId: 'service-1',
    status: status ?? 'pending',
    createdAt: DateTime.now(),
    scheduledDate: scheduledDate,
    notes: notes,
    assignedEmployeeId: assignedEmployeeId,
    seekerRating: seekerRating,
    providerRating: providerRating,
    urgency: urgency ?? 'medium',
    notificationsEnabled: notificationsEnabled ?? true,
    service: ServiceSummary(
      title: 'Test Service',
      price: 100.0,
      durationHours: 2,
    ),
    seeker: PartyInfo(
      name: 'Test Seeker',
      email: 'seeker@test.com',
    ),
    provider: PartyInfo(
      name: 'Test Provider',
      email: 'provider@test.com',
      businessName: 'Test Business',
      location: 'Test Location',
    ),
  );
}

StatusChange _createTestStatusChange() {
  return StatusChange(
    fromStatus: 'pending',
    toStatus: 'accepted',
    timestamp: DateTime.now(),
    notes: 'Test status change',
    changedBy: 'test@example.com',
  );
}

EmployeeInfo _createTestEmployee() {
  return EmployeeInfo(
    id: 'emp-1',
    name: 'Test Employee',
    email: 'employee@test.com',
    position: 'Technician',
    skills: ['plumbing', 'electrical'],
  );
}
