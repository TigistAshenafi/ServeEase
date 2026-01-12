import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/models/employee_performance_model.dart';
import 'package:serveease_app/core/services/employee_assignment_service.dart';

void main() {
  group('Employee Management Unit Tests', () {
    group('Employee Data Privacy and Security', () {
      test('should not expose sensitive employee data in JSON serialization',
          () {
        // Test employee data privacy - Requirements 5.7
        final employee = Employee(
          id: 'emp_123',
          organizationId: 'org_456',
          userId: 'user_789',
          employeeName: 'John Doe',
          email: 'john.doe@company.com',
          phone: '+1234567890',
          role: 'Senior Technician',
          skills: ['plumbing', 'electrical'],
          isActive: true,
          hireDate: DateTime(2023, 1, 15),
          documents: {
            'id_card': 'sensitive_document_path.pdf',
            'contract': 'employment_contract.pdf'
          },
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final json = employee.toJson();

        // Should not include sensitive fields in JSON output
        expect(json.containsKey('id'), isFalse);
        expect(json.containsKey('organizationId'), isFalse);
        expect(json.containsKey('userId'), isFalse);
        expect(json.containsKey('documents'), isFalse);
        expect(json.containsKey('createdAt'), isFalse);
        expect(json.containsKey('updatedAt'), isFalse);

        // Should only include necessary fields for API communication
        expect(json.containsKey('employeeName'), isTrue);
        expect(json.containsKey('email'), isTrue);
        expect(json.containsKey('role'), isTrue);
        expect(json.containsKey('skills'), isTrue);
      });

      test('should handle employee data with missing optional fields', () {
        // Test data integrity with minimal required fields
        final employee = Employee(
          id: 'emp_123',
          organizationId: 'org_456',
          userId: 'user_789',
          employeeName: 'Jane Smith',
          email: 'jane.smith@company.com',
          role: 'Technician',
          skills: ['cleaning'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(employee.phone, isNull);
        expect(employee.hireDate, isNull);
        expect(employee.documents, isNull);
        expect(employee.employeeName, equals('Jane Smith'));
        expect(employee.isActive, isTrue);
      });

      test('should validate employee email format', () {
        // Test email validation for security
        final validEmails = [
          'test@company.com',
          'user.name@domain.co.uk',
          'employee123@organization.org'
        ];

        final invalidEmails = [
          'invalid-email',
          '@company.com',
          'test@',
          'test.company.com'
        ];

        for (final email in validEmails) {
          expect(RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email), isTrue,
              reason: 'Valid email $email should pass validation');
        }

        for (final email in invalidEmails) {
          expect(RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(email), isFalse,
              reason: 'Invalid email $email should fail validation');
        }
      });
    });

    group('Employee Performance Calculations', () {
      test('should calculate performance score correctly', () {
        // Test performance score calculation - Requirements 5.5, 5.6
        final highPerformance = EmployeePerformance(
          employeeId: 'emp_1',
          totalAssignments: 100,
          completedAssignments: 95,
          averageRating: 4.8,
          completionRate: 0.95,
          averageCompletionTimeHours: 2.5,
          calculatedAt: DateTime.now(),
        );

        final lowPerformance = EmployeePerformance(
          employeeId: 'emp_2',
          totalAssignments: 50,
          completedAssignments: 30,
          averageRating: 2.5,
          completionRate: 0.60,
          averageCompletionTimeHours: 5.0,
          calculatedAt: DateTime.now(),
        );

        final highScore =
            EmployeeAssignmentService.getPerformanceScore(highPerformance);
        final lowScore =
            EmployeeAssignmentService.getPerformanceScore(lowPerformance);

        expect(highScore, greaterThan(lowScore));
        expect(highScore, greaterThan(0.8));
        expect(lowScore, lessThan(0.6));
      });

      test('should handle null performance gracefully', () {
        // Test default performance handling
        final defaultScore =
            EmployeeAssignmentService.getPerformanceScore(null);
        expect(defaultScore, equals(0.5)); // Default neutral score
      });

      test('should calculate completion rate correctly', () {
        // Test completion rate calculation
        final performance = EmployeePerformance(
          employeeId: 'emp_test',
          totalAssignments: 20,
          completedAssignments: 18,
          averageRating: 4.0,
          completionRate: 0.9, // 18/20 = 0.9
          averageCompletionTimeHours: 3.0,
          calculatedAt: DateTime.now(),
        );

        expect(performance.completionRate, equals(0.9));
        expect(performance.completedAssignments / performance.totalAssignments,
            equals(performance.completionRate));
      });
    });

    group('Employee Availability Management', () {
      test('should validate availability schedule format', () {
        // Test availability schedule validation - Requirements 5.4
        final timeSlot = TimeSlot(
          startTime: '09:00',
          endTime: '17:00',
        );

        expect(timeSlot.startTime, matches(RegExp(r'^\d{2}:\d{2}$')));
        expect(timeSlot.endTime, matches(RegExp(r'^\d{2}:\d{2}$')));
      });

      test('should handle availability date ranges correctly', () {
        // Test date range validation
        final dateRange = DateRange(
          startDate: DateTime(2024, 1, 1),
          endDate: DateTime(2024, 1, 7),
          reason: 'Vacation',
        );

        expect(dateRange.startDate.isBefore(dateRange.endDate), isTrue);
        expect(dateRange.reason, equals('Vacation'));
      });

      test('should validate weekly schedule structure', () {
        // Test weekly schedule validation
        final weeklySchedule = {
          'monday': [
            TimeSlot(startTime: '09:00', endTime: '12:00'),
            TimeSlot(startTime: '13:00', endTime: '17:00'),
          ],
          'tuesday': [
            TimeSlot(startTime: '09:00', endTime: '17:00'),
          ],
        };

        expect(weeklySchedule.containsKey('monday'), isTrue);
        expect(weeklySchedule['monday']!.length, equals(2));
        expect(weeklySchedule['tuesday']!.length, equals(1));
      });

      test('should check employee availability for time slots', () {
        // Test availability checking logic
        final availability = AvailabilitySchedule(
          employeeId: 'emp_test',
          weeklySchedule: {
            'monday': [
              TimeSlot(startTime: '09:00', endTime: '17:00'),
            ],
          },
          unavailableDates: [],
          isCurrentlyAvailable: true,
          updatedAt: DateTime.now(),
        );

        final mondayMorning = DateTime(2024, 1, 1, 10, 0); // Monday 10:00 AM
        final mondayAfternoon = DateTime(2024, 1, 1, 15, 0); // Monday 3:00 PM

        final isAvailable = EmployeeAssignmentService.isEmployeeAvailable(
          availability,
          mondayMorning,
          mondayAfternoon,
        );

        expect(isAvailable, isTrue);
      });

      test('should respect unavailable dates', () {
        // Test unavailable date handling
        final availability = AvailabilitySchedule(
          employeeId: 'emp_test',
          weeklySchedule: {
            'monday': [
              TimeSlot(startTime: '09:00', endTime: '17:00'),
            ],
          },
          unavailableDates: [
            DateRange(
              startDate: DateTime(2024, 1, 1),
              endDate: DateTime(2024, 1, 7),
              reason: 'Vacation',
            ),
          ],
          isCurrentlyAvailable: true,
          updatedAt: DateTime.now(),
        );

        final vacationDay = DateTime(2024, 1, 3, 10, 0);
        final vacationDayEnd = DateTime(2024, 1, 3, 15, 0);

        final isAvailable = EmployeeAssignmentService.isEmployeeAvailable(
          availability,
          vacationDay,
          vacationDayEnd,
        );

        expect(isAvailable, isFalse);
      });
    });

    group('Employee Skills Management', () {
      test('should handle skill normalization correctly', () {
        // Test skill matching with different cases and whitespace
        final employeeSkills = ['  Plumbing  ', 'ELECTRICAL', 'carpentry'];
        final requiredSkills = ['plumbing', 'electrical'];

        final matchScore = EmployeeAssignmentService.calculateSkillMatchScore(
          employeeSkills,
          requiredSkills,
        );

        expect(matchScore,
            equals(1.0)); // Should match despite case/whitespace differences
      });

      test('should validate skill list integrity', () {
        // Test skill list validation
        final employee = Employee(
          id: 'emp_test',
          organizationId: 'org_test',
          userId: 'user_test',
          employeeName: 'Test Employee',
          email: 'test@company.com',
          role: 'Technician',
          skills: ['plumbing', 'electrical', 'repair'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(employee.skills, isA<List<String>>());
        expect(employee.skills.length, equals(3));
        expect(employee.skills.contains('plumbing'), isTrue);
      });

      test('should handle empty skills list', () {
        // Test empty skills handling
        final employee = Employee(
          id: 'emp_test',
          organizationId: 'org_test',
          userId: 'user_test',
          employeeName: 'Test Employee',
          email: 'test@company.com',
          role: 'Trainee',
          skills: [],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(employee.skills, isEmpty);

        final matchScore = EmployeeAssignmentService.calculateSkillMatchScore(
          employee.skills,
          ['plumbing'],
        );

        expect(matchScore, equals(0.0));
      });
    });

    group('Employee Model Validation', () {
      test('should create employee with all required fields', () {
        // Test employee model creation
        final employee = Employee(
          id: 'emp_123',
          organizationId: 'org_456',
          userId: 'user_789',
          employeeName: 'John Doe',
          email: 'john.doe@company.com',
          role: 'Senior Technician',
          skills: ['plumbing', 'electrical'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(employee.id, equals('emp_123'));
        expect(employee.organizationId, equals('org_456'));
        expect(employee.employeeName, equals('John Doe'));
        expect(employee.email, equals('john.doe@company.com'));
        expect(employee.role, equals('Senior Technician'));
        expect(employee.skills, contains('plumbing'));
        expect(employee.isActive, isTrue);
      });

      test('should support employee copyWith functionality', () {
        // Test employee model immutability and copying
        final originalEmployee = Employee(
          id: 'emp_123',
          organizationId: 'org_456',
          userId: 'user_789',
          employeeName: 'John Doe',
          email: 'john.doe@company.com',
          role: 'Technician',
          skills: ['plumbing'],
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final updatedEmployee = originalEmployee.copyWith(
          role: 'Senior Technician',
          skills: ['plumbing', 'electrical'],
        );

        expect(originalEmployee.role, equals('Technician'));
        expect(updatedEmployee.role, equals('Senior Technician'));
        expect(updatedEmployee.skills, contains('electrical'));
        expect(updatedEmployee.id,
            equals(originalEmployee.id)); // Should preserve other fields
      });

      test('should handle JSON serialization and deserialization', () {
        // Test JSON handling for API communication
        final originalEmployee = Employee(
          id: 'emp_123',
          organizationId: 'org_456',
          userId: 'user_789',
          employeeName: 'John Doe',
          email: 'john.doe@company.com',
          role: 'Technician',
          skills: ['plumbing', 'electrical'],
          isActive: true,
          hireDate: DateTime(2023, 1, 15),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Test JSON serialization (for API requests)
        final json = originalEmployee.toJson();
        expect(json['employeeName'], equals('John Doe'));
        expect(json['skills'], contains('plumbing'));

        // Test JSON deserialization (from API responses)
        final jsonData = {
          'id': 'emp_456',
          'organizationId': 'org_789',
          'userId': 'user_123',
          'employeeName': 'Jane Smith',
          'email': 'jane.smith@company.com',
          'role': 'Senior Technician',
          'skills': ['electrical', 'hvac'],
          'isActive': true,
          'createdAt': DateTime.now().toIso8601String(),
          'updatedAt': DateTime.now().toIso8601String(),
        };

        final deserializedEmployee = Employee.fromJson(jsonData);
        expect(deserializedEmployee.employeeName, equals('Jane Smith'));
        expect(deserializedEmployee.skills, contains('hvac'));
      });
    });
  });
}
