import 'package:flutter_test/flutter_test.dart';
import 'package:serveease_app/core/models/employee_model.dart';
import 'package:serveease_app/core/services/employee_assignment_service.dart';
import 'dart:math';

void main() {
  group('Employee Skill Matching Property Tests', () {
    test(
        'Property 9: Employee Skill Matching - For any accepted service request in an organization, the assignment system should show available employees with matching skills',
        () {
      // **Feature: serveease-platform, Property 9: Employee Skill Matching**
      // **Validates: Requirements 5.2**

      final random = Random();
      const int iterations = 100;

      for (int i = 0; i < iterations; i++) {
        // Generate random required skills for a service request
        final requiredSkills = _generateRandomSkills(random, maxSkills: 5);

        // Generate random employees with various skill sets
        final employees = _generateRandomEmployees(random, count: 10);

        // Test skill matching for each employee
        for (final employee in employees) {
          final skillMatchScore =
              EmployeeAssignmentService.calculateSkillMatchScore(
            employee.skills,
            requiredSkills,
          );

          // Property: Skill match score should be between 0 and 1
          expect(skillMatchScore, greaterThanOrEqualTo(0.0));
          expect(skillMatchScore, lessThanOrEqualTo(1.0));

          // Property: If employee has all required skills, score should be 1.0
          if (requiredSkills.every((skill) => employee.skills
              .map((s) => s.toLowerCase())
              .contains(skill.toLowerCase()))) {
            expect(skillMatchScore, equals(1.0));
          }

          // Property: If employee has no matching skills, score should be 0.0
          if (requiredSkills.isNotEmpty &&
              !requiredSkills.any((skill) => employee.skills
                  .map((s) => s.toLowerCase())
                  .contains(skill.toLowerCase()))) {
            expect(skillMatchScore, equals(0.0));
          }

          // Property: If no skills are required, score should be 1.0 (perfect match)
          if (requiredSkills.isEmpty) {
            expect(skillMatchScore, equals(1.0));
          }
        }

        // Property: Employees with more matching skills should have higher scores
        final employeesWithScores = employees.map((employee) {
          final score = EmployeeAssignmentService.calculateSkillMatchScore(
            employee.skills,
            requiredSkills,
          );
          return MapEntry(employee, score);
        }).toList();

        // Sort by number of matching skills
        employeesWithScores.sort((a, b) {
          final aMatches = _countMatchingSkills(a.key.skills, requiredSkills);
          final bMatches = _countMatchingSkills(b.key.skills, requiredSkills);
          return bMatches.compareTo(aMatches);
        });

        // Verify that employees with more matches have equal or higher scores
        for (int j = 0; j < employeesWithScores.length - 1; j++) {
          final currentMatches = _countMatchingSkills(
            employeesWithScores[j].key.skills,
            requiredSkills,
          );
          final nextMatches = _countMatchingSkills(
            employeesWithScores[j + 1].key.skills,
            requiredSkills,
          );

          if (currentMatches > nextMatches) {
            expect(
              employeesWithScores[j].value,
              greaterThanOrEqualTo(employeesWithScores[j + 1].value),
              reason:
                  'Employee with more matching skills should have higher or equal score',
            );
          }
        }
      }
    });

    test('Property Test: Assignment Score Calculation', () {
      // Test the overall assignment score calculation
      final random = Random();
      const int iterations = 100;

      for (int i = 0; i < iterations; i++) {
        final skillScore = random.nextDouble();
        final performanceScore = random.nextDouble();
        final availabilityScore = random.nextDouble();

        final overallScore = EmployeeAssignmentService.calculateAssignmentScore(
          skillMatchScore: skillScore,
          performanceScore: performanceScore,
          availabilityScore: availabilityScore,
        );

        // Property: Overall score should be between 0 and 1
        expect(overallScore, greaterThanOrEqualTo(0.0));
        expect(overallScore, lessThanOrEqualTo(1.0));

        // Property: If all component scores are 1.0, overall score should be 1.0
        if (skillScore == 1.0 &&
            performanceScore == 1.0 &&
            availabilityScore == 1.0) {
          expect(overallScore, equals(1.0));
        }

        // Property: If all component scores are 0.0, overall score should be 0.0
        if (skillScore == 0.0 &&
            performanceScore == 0.0 &&
            availabilityScore == 0.0) {
          expect(overallScore, equals(0.0));
        }
      }
    });

    test('Property Test: Skill Matching Edge Cases', () {
      // Test edge cases for skill matching

      // Empty skills lists
      expect(
        EmployeeAssignmentService.calculateSkillMatchScore([], []),
        equals(1.0),
        reason: 'Empty skills should result in perfect match',
      );

      expect(
        EmployeeAssignmentService.calculateSkillMatchScore(['skill1'], []),
        equals(1.0),
        reason: 'No required skills should result in perfect match',
      );

      expect(
        EmployeeAssignmentService.calculateSkillMatchScore([], ['skill1']),
        equals(0.0),
        reason:
            'No employee skills with required skills should result in no match',
      );

      // Case insensitive matching
      expect(
        EmployeeAssignmentService.calculateSkillMatchScore(
          ['PLUMBING', 'electrical'],
          ['plumbing', 'ELECTRICAL'],
        ),
        equals(1.0),
        reason: 'Skill matching should be case insensitive',
      );

      // Whitespace handling
      expect(
        EmployeeAssignmentService.calculateSkillMatchScore(
          [' plumbing ', 'electrical '],
          ['plumbing', ' electrical'],
        ),
        equals(1.0),
        reason: 'Skill matching should handle whitespace',
      );

      // Partial matches
      expect(
        EmployeeAssignmentService.calculateSkillMatchScore(
          ['plumbing', 'electrical'],
          ['plumbing', 'carpentry', 'painting'],
        ),
        equals(1.0 / 3.0),
        reason: 'Partial skill matches should be calculated correctly',
      );
    });
  });
}

List<String> _generateRandomSkills(Random random, {int maxSkills = 5}) {
  final availableSkills = [
    'plumbing',
    'electrical',
    'carpentry',
    'painting',
    'cleaning',
    'repair',
    'installation',
    'maintenance',
    'welding',
    'roofing',
    'flooring',
    'tiling',
    'landscaping',
    'hvac',
    'appliance repair'
  ];

  final skillCount = random.nextInt(maxSkills + 1);
  final selectedSkills = <String>[];

  for (int i = 0; i < skillCount; i++) {
    final skill = availableSkills[random.nextInt(availableSkills.length)];
    if (!selectedSkills.contains(skill)) {
      selectedSkills.add(skill);
    }
  }

  return selectedSkills;
}

List<Employee> _generateRandomEmployees(Random random, {int count = 10}) {
  final employees = <Employee>[];

  for (int i = 0; i < count; i++) {
    final skills = _generateRandomSkills(random, maxSkills: 8);

    employees.add(Employee(
      id: 'emp_$i',
      organizationId: 'org_1',
      userId: 'user_$i',
      employeeName: 'Employee $i',
      email: 'employee$i@test.com',
      role: 'Technician',
      skills: skills,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  }

  return employees;
}

int _countMatchingSkills(
    List<String> employeeSkills, List<String> requiredSkills) {
  final normalizedEmployeeSkills =
      employeeSkills.map((skill) => skill.toLowerCase().trim()).toSet();
  final normalizedRequiredSkills =
      requiredSkills.map((skill) => skill.toLowerCase().trim()).toSet();

  return normalizedEmployeeSkills.intersection(normalizedRequiredSkills).length;
}
