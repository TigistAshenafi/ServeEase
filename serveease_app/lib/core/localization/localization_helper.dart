import 'package:flutter/material.dart';
import 'package:serveease_app/l10n/app_localizations.dart';

/// Helper class for localization utilities
class LocalizationHelper {
  /// Get localized text for service categories
  static String getServiceCategoryName(BuildContext context, String category) {
    final l10n = AppLocalizations.of(context)!;

    switch (category.toLowerCase()) {
      case 'home_repair':
        return l10n.homeRepair;
      case 'cleaning':
        return l10n.cleaning;
      case 'gardening':
        return l10n.gardening;
      case 'it_support':
        return l10n.itSupport;
      case 'tutoring':
        return l10n.tutoring;
      case 'delivery':
        return l10n.delivery;
      default:
        return category;
    }
  }

  /// Get localized text for request status
  static String getRequestStatusName(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pending;
      case 'accepted':
        return l10n.accepted;
      case 'assigned':
        return l10n.assigned;
      case 'in_progress':
        return l10n.inProgress;
      case 'completed':
        return l10n.completed;
      case 'cancelled':
        return l10n.cancelled;
      default:
        return status;
    }
  }

  /// Get localized text for provider types
  static String getProviderTypeName(BuildContext context, String type) {
    final l10n = AppLocalizations.of(context)!;

    switch (type.toLowerCase()) {
      case 'individual':
        return l10n.individual;
      case 'organization':
        return l10n.organization;
      default:
        return type;
    }
  }

  /// Get localized text for user roles
  static String getUserRoleName(BuildContext context, String role) {
    final l10n = AppLocalizations.of(context)!;

    switch (role.toLowerCase()) {
      case 'provider':
        return l10n.provider;
      case 'seeker':
        return l10n.seeker;
      default:
        return role;
    }
  }

  /// Get localized text for approval status
  static String getApprovalStatusName(BuildContext context, String status) {
    final l10n = AppLocalizations.of(context)!;

    switch (status.toLowerCase()) {
      case 'pending':
        return l10n.pendingApproval;
      case 'approved':
        return l10n.approved;
      case 'rejected':
        return l10n.rejected;
      default:
        return status;
    }
  }

  /// Format currency with localization
  static String formatCurrency(BuildContext context, double amount) {
    // For now, using simple formatting. Can be enhanced with proper currency formatting
    return '\$${amount.toStringAsFixed(2)}';
  }

  /// Format date with localization
  static String formatDate(BuildContext context, DateTime date) {
    // Simple date formatting. Can be enhanced with proper locale-specific formatting
    return '${date.day}/${date.month}/${date.year}';
  }

  /// Format time with localization
  static String formatTime(BuildContext context, DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  /// Get localized error messages
  static String getErrorMessage(BuildContext context, String errorKey) {
    final l10n = AppLocalizations.of(context)!;

    switch (errorKey.toLowerCase()) {
      case 'no_internet':
        return l10n.noInternetConnection;
      case 'something_wrong':
        return l10n.somethingWentWrong;
      case 'invalid_code':
        return l10n.invalidCode;
      case 'code_expired':
        return l10n.codeExpired;
      default:
        return l10n.somethingWentWrong;
    }
  }

  /// Get localized success messages
  static String getSuccessMessage(BuildContext context, String successKey) {
    final l10n = AppLocalizations.of(context)!;

    switch (successKey.toLowerCase()) {
      case 'email_verified':
        return l10n.emailVerified;
      case 'service_booked':
        return l10n.serviceBooked;
      case 'request_accepted':
        return l10n.requestAccepted;
      case 'request_rejected':
        return l10n.requestRejected;
      case 'employee_assigned':
        return l10n.employeeAssigned;
      case 'service_completed':
        return l10n.serviceCompleted;
      case 'review_submitted':
        return l10n.reviewSubmitted;
      case 'profile_updated':
        return l10n.profileUpdated;
      case 'service_created':
        return l10n.serviceCreated;
      case 'service_updated':
        return l10n.serviceUpdated;
      case 'service_deleted':
        return l10n.serviceDeleted;
      case 'employee_added':
        return l10n.employeeAdded;
      case 'employee_updated':
        return l10n.employeeUpdated;
      case 'employee_deleted':
        return l10n.employeeDeleted;
      default:
        return l10n.success;
    }
  }

  /// Check if current locale is RTL
  static bool isRTL(BuildContext context) {
    return Directionality.of(context) == TextDirection.rtl;
  }

  /// Get appropriate text alignment based on locale
  static TextAlign getTextAlign(BuildContext context) {
    return isRTL(context) ? TextAlign.right : TextAlign.left;
  }

  /// Get appropriate edge insets based on locale
  static EdgeInsetsDirectional getDirectionalPadding({
    double start = 0,
    double top = 0,
    double end = 0,
    double bottom = 0,
  }) {
    return EdgeInsetsDirectional.fromSTEB(start, top, end, bottom);
  }
}
