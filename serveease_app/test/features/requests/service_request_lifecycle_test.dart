import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/models/service_request_model.dart';

void main() {
  group('Service Request Lifecycle Tests', () {
    late ServiceRequest testRequest;

    setUp(() {
      testRequest = ServiceRequest(
        id: 'test-request-1',
        seekerId: 'seeker-1',
        providerId: 'provider-1',
        serviceId: 'service-1',
        status: 'pending',
        createdAt: DateTime.now(),
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
    });

    group('Status Transition Validation', () {
      test('should allow valid transitions from pending status', () {
        expect(testRequest.canTransitionTo('accepted'), isTrue);
        expect(testRequest.canTransitionTo('rejected'), isTrue);
        expect(testRequest.canTransitionTo('cancelled'), isTrue);
        expect(testRequest.canTransitionTo('in_progress'), isFalse);
        expect(testRequest.canTransitionTo('completed'), isFalse);
      });

      test('should allow valid transitions from accepted status', () {
        final acceptedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'accepted',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(acceptedRequest.canTransitionTo('assigned'), isTrue);
        expect(acceptedRequest.canTransitionTo('in_progress'), isTrue);
        expect(acceptedRequest.canTransitionTo('cancelled'), isTrue);
        expect(acceptedRequest.canTransitionTo('pending'), isFalse);
        expect(acceptedRequest.canTransitionTo('completed'), isFalse);
      });

      test('should allow valid transitions from assigned status', () {
        final assignedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'assigned',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(assignedRequest.canTransitionTo('in_progress'), isTrue);
        expect(assignedRequest.canTransitionTo('cancelled'), isTrue);
        expect(assignedRequest.canTransitionTo('accepted'), isFalse);
        expect(assignedRequest.canTransitionTo('completed'), isFalse);
      });

      test('should allow valid transitions from in_progress status', () {
        final inProgressRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'in_progress',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(inProgressRequest.canTransitionTo('completed'), isTrue);
        expect(inProgressRequest.canTransitionTo('cancelled'), isTrue);
        expect(inProgressRequest.canTransitionTo('accepted'), isFalse);
        expect(inProgressRequest.canTransitionTo('assigned'), isFalse);
      });

      test('should not allow transitions from terminal states', () {
        final completedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'completed',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(completedRequest.canTransitionTo('pending'), isFalse);
        expect(completedRequest.canTransitionTo('accepted'), isFalse);
        expect(completedRequest.canTransitionTo('in_progress'), isFalse);
        expect(completedRequest.canTransitionTo('cancelled'), isFalse);
      });
    });

    group('Request Status Properties', () {
      test('should correctly identify request status', () {
        expect(testRequest.isPending, isTrue);
        expect(testRequest.isInProgress, isFalse);
        expect(testRequest.isCompleted, isFalse);
      });

      test('should correctly identify completed request', () {
        final completedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'completed',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(completedRequest.isPending, isFalse);
        expect(completedRequest.isInProgress, isFalse);
        expect(completedRequest.isCompleted, isTrue);
        expect(completedRequest.canBeRated, isTrue);
      });

      test('should correctly identify if request can be rated', () {
        final completedWithRatingRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'completed',
          createdAt: testRequest.createdAt,
          seekerRating: 5,
          providerRating: 4,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(completedWithRatingRequest.canBeRated, isFalse);
      });

      test('should correctly identify if employee assignment is required', () {
        final acceptedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'accepted',
          createdAt: testRequest.createdAt,
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(acceptedRequest.requiresEmployeeAssignment, isTrue);

        final assignedRequest = ServiceRequest(
          id: testRequest.id,
          seekerId: testRequest.seekerId,
          providerId: testRequest.providerId,
          serviceId: testRequest.serviceId,
          status: 'accepted',
          createdAt: testRequest.createdAt,
          assignedEmployeeId: 'employee-1',
          service: testRequest.service,
          seeker: testRequest.seeker,
          provider: testRequest.provider,
        );

        expect(assignedRequest.requiresEmployeeAssignment, isFalse);
      });
    });

    group('Status Change Model', () {
      test('should create status change from JSON', () {
        final json = {
          'fromStatus': 'pending',
          'toStatus': 'accepted',
          'timestamp': '2024-01-01T10:00:00Z',
          'notes': 'Request accepted by provider',
          'changedBy': 'provider@test.com',
          'reason': null,
        };

        final statusChange = StatusChange.fromJson(json);

        expect(statusChange.fromStatus, equals('pending'));
        expect(statusChange.toStatus, equals('accepted'));
        expect(statusChange.notes, equals('Request accepted by provider'));
        expect(statusChange.changedBy, equals('provider@test.com'));
        expect(statusChange.reason, isNull);
      });

      test('should convert status change to JSON', () {
        final statusChange = StatusChange(
          fromStatus: 'pending',
          toStatus: 'accepted',
          timestamp: DateTime.parse('2024-01-01T10:00:00Z'),
          notes: 'Request accepted by provider',
          changedBy: 'provider@test.com',
        );

        final json = statusChange.toJson();

        expect(json['fromStatus'], equals('pending'));
        expect(json['toStatus'], equals('accepted'));
        expect(json['timestamp'], equals('2024-01-01T10:00:00.000Z'));
        expect(json['notes'], equals('Request accepted by provider'));
        expect(json['changedBy'], equals('provider@test.com'));
      });
    });

    group('Employee Info Model', () {
      test('should create employee info from JSON', () {
        final json = {
          'id': 'emp-1',
          'name': 'John Doe',
          'email': 'john@test.com',
          'position': 'Senior Technician',
          'skills': ['plumbing', 'electrical', 'repair'],
        };

        final employee = EmployeeInfo.fromJson(json);

        expect(employee.id, equals('emp-1'));
        expect(employee.name, equals('John Doe'));
        expect(employee.email, equals('john@test.com'));
        expect(employee.position, equals('Senior Technician'));
        expect(employee.skills, equals(['plumbing', 'electrical', 'repair']));
      });
    });

    group('Service Request Data Model', () {
      test('should create service request data and convert to JSON', () {
        final requestData = ServiceRequestData(
          serviceId: 'service-1',
          providerId: 'provider-1',
          notes: 'Urgent repair needed',
          scheduledDate: DateTime.parse('2024-01-15T14:00:00Z'),
          urgency: 'high',
        );

        final json = requestData.toJson();

        expect(json['serviceId'], equals('service-1'));
        expect(json['providerId'], equals('provider-1'));
        expect(json['notes'], equals('Urgent repair needed'));
        expect(json['scheduledDate'], equals('2024-01-15T14:00:00.000Z'));
        expect(json['urgency'], equals('high'));
      });
    });
  });
}
