// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ServeEase';

  @override
  String get languageLabel => 'Language';

  @override
  String get englishLabel => 'English';

  @override
  String get amharicLabel => 'Amharic';

  @override
  String get loginWelcomeTitle => 'Welcome Back';

  @override
  String get loginSubtitle => 'Log in to continue using ServeEase';

  @override
  String get emailLabel => 'Email Address';

  @override
  String get emailHint => 'you@example.com';

  @override
  String get passwordLabel => 'Password';

  @override
  String get forgotPasswordLabel => 'Forgot Password?';

  @override
  String get loginButtonLabel => 'Log In';

  @override
  String get signupRedirectPrefix => 'Don\'t have an account? ';

  @override
  String get signupRedirectAction => 'Sign Up';

  @override
  String get loginRedirectPrefix => 'Already have an account? ';

  @override
  String get loginRedirectAction => 'Log In';

  @override
  String get loginSuccessMessage => 'Login successful!';

  @override
  String loginFailed(Object reason) {
    return 'Login failed: $reason';
  }

  @override
  String errorWithMessage(Object message) {
    return 'Error: $message';
  }

  @override
  String get unknownError => 'Something went wrong. Please try again.';

  @override
  String get createAccountTitle => 'Create Your Account';

  @override
  String get signupSubtitle => 'Join ServeEase to connect with services or offer your expertise.';

  @override
  String get nameOptionalLabel => 'Full Name (optional)';

  @override
  String get confirmPasswordLabel => 'Confirm Password';

  @override
  String get joinAsLabel => 'Join as:';

  @override
  String get providerDetailsTitle => 'Provider details';

  @override
  String get businessNameLabel => 'Business / brand name';

  @override
  String get serviceDescriptionLabel => 'Service description';

  @override
  String get providerBusinessValidation => 'Business name is required for providers';

  @override
  String get providerDescriptionValidation => 'Tell seekers about your services';

  @override
  String get signupSubmitLabel => 'Sign Up';

  @override
  String get providerSubmitLabel => 'Submit provider request';

  @override
  String get serviceSeekerLabel => 'Service Seeker';

  @override
  String get serviceProviderLabel => 'Service Provider';

  @override
  String get validationEmailRequired => 'Email is required';

  @override
  String get validationEmailInvalid => 'Invalid email';

  @override
  String get validationPasswordRequired => 'Password is required';

  @override
  String get validationPasswordLength => 'Password must be at least 6 characters';

  @override
  String get validationConfirmPassword => 'Confirm password';

  @override
  String get validationPasswordsMismatch => 'Passwords do not match';

  @override
  String get verifyEmailTitle => 'Verify Email';

  @override
  String verifyEmailInfo(Object email) {
    return 'A verification code was sent to $email.';
  }

  @override
  String get verificationCodeLabel => 'Verification code';

  @override
  String get verifyButtonLabel => 'Verify';

  @override
  String get missingEmailError => 'Missing email';

  @override
  String get emailVerifiedMessage => 'Email verified. Please log in.';

  @override
  String get homeTitle => 'ServeEase Home';

  @override
  String get homeWelcome => 'Welcome to ServeEase!';

  @override
  String get homeSubtitle => 'Explore services, request bookings, and manage your account.';

  @override
  String get homeExploreButton => 'Explore Services';

  @override
  String get backToLoginLabel => 'Back to Login';

  @override
  String get emptyVerificationCode => 'Please enter the verification code';

  @override
  String get forgotPasswordTitle => 'Forgot Password?';

  @override
  String get forgotPasswordSubtitle => 'Enter your email and we\'ll send you instructions to reset your password.';

  @override
  String get sendResetLinkButton => 'Send Reset Link';

  @override
  String get rememberPasswordPrefix => 'Remembered your password? ';

  @override
  String get rememberPasswordAction => 'Log In';

  @override
  String get resetCodeSentMessage => 'The reset code has been sent to your email.';
}
