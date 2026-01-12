import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_am.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('am'),
    Locale('en')
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'ServeEase'**
  String get appTitle;

<<<<<<< HEAD
  /// Welcome message
=======
  /// No description provided for @englishLabel.
  ///
  /// In en, this message translates to:
  /// **'EN'**
  String get englishLabel;

  /// No description provided for @amharicLabel.
  ///
  /// In en, this message translates to:
  /// **'AM'**
  String get amharicLabel;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeTitle;

  /// No description provided for @providerInfoNote.
  ///
  /// In en, this message translates to:
  /// **'As a provider, you will need to set up your profile after verifying your email.'**
  String get providerInfoNote;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameLabel;

  /// No description provided for @nameValidation.
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get nameValidation;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Login to your account to continue'**
  String get loginSubtitle;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  ///
  
  String get passwordLabel;
  /// No description provided for @passwordHint.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;
  /// No description provided for @forgotPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordLabel;

  /// No description provided for @loginButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonLabel;

  /// No description provided for @signupRedirectPrefix.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? '**
  String get signupRedirectPrefix;

  /// No description provided for @signupRedirectAction.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signupRedirectAction;

  /// No description provided for @loginRedirectPrefix.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? '**
  String get loginRedirectPrefix;

  /// No description provided for @loginRedirectAction.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get loginRedirectAction;

  /// No description provided for @loginSuccessMessage.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessMessage;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String loginFailed(Object reason);

  /// No description provided for @errorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String errorWithMessage(Object message);

  /// No description provided for @unknownError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get unknownError;

  /// No description provided for @createAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Create Your Account'**
  String get createAccountTitle;

  /// No description provided for @signupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Join ServeEase to connect with services or offer your expertise.'**
  String get signupSubtitle;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// No description provided for @joinAsLabel.
  ///
  /// In en, this message translates to:
  /// **'Join as:'**
  String get joinAsLabel;

  /// No description provided for @providerDetailsTitle.
  ///
  /// In en, this message translates to:
  /// **'Provider details'**
  String get providerDetailsTitle;

  /// No description provided for @businessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business / brand name'**
  String get businessNameLabel;

  /// No description provided for @serviceDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Service description'**
  String get serviceDescriptionLabel;

  /// No description provided for @providerBusinessValidation.
  ///
  /// In en, this message translates to:
  /// **'Business name is required for providers'**
  String get providerBusinessValidation;

  /// No description provided for @signupSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signupSubmitLabel;

  /// No description provided for @providerSubmitLabel.
  ///
  /// In en, this message translates to:
  /// **'Submit provider request'**
  String get providerSubmitLabel;

  /// No description provided for @serviceSeekerLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Seeker'**
  String get serviceSeekerLabel;

  /// No description provided for @serviceProviderLabel.
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get serviceProviderLabel;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get validationPasswordLength;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordsMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsMismatch;

  /// No description provided for @verifyEmailTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmailTitle;

  /// No description provided for @verifyEmailInfo.
  ///
  /// In en, this message translates to:
  /// **'A verification code was sent to {email}.'**
  String verifyEmailInfo(Object email);

  /// No description provided for @verificationCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Verification code'**
  String get verificationCodeLabel;

  /// No description provided for @verifyButtonLabel.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verifyButtonLabel;

  /// No description provided for @missingEmailError.
  ///
  /// In en, this message translates to:
  /// **'Missing email'**
  String get missingEmailError;

  /// No description provided for @emailVerifiedMessage.
  ///
  /// In en, this message translates to:
  /// **'Email verified. Please log in.'**
  String get emailVerifiedMessage;

  /// No description provided for @homeTitle.
  ///
  /// In en, this message translates to:
  /// **'ServeEase Home'**
  String get homeTitle;

  /// No description provided for @homeWelcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ServeEase!'**
  String get homeWelcome;

  /// No description provided for @homeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Explore services, request bookings, and manage your account.'**
  String get homeSubtitle;

  /// No description provided for @homeExploreButton.
  ///
  /// In en, this message translates to:
  /// **'Explore Services'**
  String get homeExploreButton;

  /// No description provided for @backToLoginLabel.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get backToLoginLabel;

  /// No description provided for @emptyVerificationCode.
  ///
  /// In en, this message translates to:
  /// **'Please enter the verification code'**
  String get emptyVerificationCode;

  /// No description provided for @forgotPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPasswordTitle;

  /// No description provided for @forgotPasswordSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and we\'ll send you instructions to reset your password.'**
  String get forgotPasswordSubtitle;

  /// No description provided for @sendResetLinkButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get sendResetLinkButton;

  /// No description provided for @rememberPasswordPrefix.
  ///
  /// In en, this message translates to:
  /// **'Remembered your password? '**
  String get rememberPasswordPrefix;

  /// No description provided for @rememberPasswordAction.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get rememberPasswordAction;

  /// No description provided for @resetCodeSentMessage.
  ///
  /// In en, this message translates to:
  /// **'The reset code has been sent to your email.'**
  String get resetCodeSentMessage;

  /// No description provided for @didntReceiveCode.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive the code? '**
  String get didntReceiveCode;

  /// No description provided for @resendCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCodeLabel;

  /// No description provided for @tryAnotherEmail.
  ///
  /// In en, this message translates to:
  /// **'Try another email'**
  String get tryAnotherEmail;

  /// No description provided for @providerCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get providerCategoryLabel;

  /// No description provided for @providerDescriptionValidation.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get providerDescriptionValidation;

  /// No description provided for @providerCategoryValidation.
  ///
  /// In en, this message translates to:
  /// **'Category is required'**
  String get providerCategoryValidation;

  /// No description provided for @providerProfileSuccess.
  ///
  /// In en, this message translates to:
  /// **'Provider profile created successfully!'**
  String get providerProfileSuccess;

  /// No description provided for @providerProfileSetup.
  ///
  /// In en, this message translates to:
  /// **'Provider Profile Setup'**
  String get providerProfileSetup;

  /// No description provided for @selectLoginRole.
  ///
  /// In en, this message translates to:
  /// **'Please select login role'**
  String get selectLoginRole;

  /// No description provided for @welcome.
>>>>>>> bc880ce957d53bbe4cca033a664fa74a78d4ce24
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Sign up prompt text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign in prompt text
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// Sign up button text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Sign in button text
  ///
  /// In en, this message translates to:
  /// **'Sign In'**
  String get signIn;

  /// Logout button text
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Profile page title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting label
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Amharic language option
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharic;

  /// Services page title
  ///
  /// In en, this message translates to:
  /// **'Services'**
  String get services;

  /// Find services page title
  ///
  /// In en, this message translates to:
  /// **'Find Services'**
  String get findServices;

  /// My services page title
  ///
  /// In en, this message translates to:
  /// **'My Services'**
  String get myServices;

  /// Add service button text
  ///
  /// In en, this message translates to:
  /// **'Add Service'**
  String get addService;

  /// Edit service button text
  ///
  /// In en, this message translates to:
  /// **'Edit Service'**
  String get editService;

  /// Delete service button text
  ///
  /// In en, this message translates to:
  /// **'Delete Service'**
  String get deleteService;

  /// Service title field label
  ///
  /// In en, this message translates to:
  /// **'Service Title'**
  String get serviceTitle;

  /// Service description field label
  ///
  /// In en, this message translates to:
  /// **'Service Description'**
  String get serviceDescription;

  /// Service price field label
  ///
  /// In en, this message translates to:
  /// **'Price'**
  String get servicePrice;

  /// Service duration field label
  ///
  /// In en, this message translates to:
  /// **'Duration (hours)'**
  String get serviceDuration;

  /// Service category field label
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get serviceCategory;

  /// Home repair service category
  ///
  /// In en, this message translates to:
  /// **'Home Repair'**
  String get homeRepair;

  /// Cleaning service category
  ///
  /// In en, this message translates to:
  /// **'Cleaning'**
  String get cleaning;

  /// Gardening service category
  ///
  /// In en, this message translates to:
  /// **'Gardening'**
  String get gardening;

  /// IT support service category
  ///
  /// In en, this message translates to:
  /// **'IT Support'**
  String get itSupport;

  /// Tutoring service category
  ///
  /// In en, this message translates to:
  /// **'Tutoring'**
  String get tutoring;

  /// Delivery service category
  ///
  /// In en, this message translates to:
  /// **'Delivery'**
  String get delivery;

  /// Requests page title
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requests;

  /// My requests page title
  ///
  /// In en, this message translates to:
  /// **'My Requests'**
  String get myRequests;

  /// Request service button text
  ///
  /// In en, this message translates to:
  /// **'Request Service'**
  String get requestService;

  /// Request status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get requestStatus;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Accepted status
  ///
  /// In en, this message translates to:
  /// **'Accepted'**
  String get accepted;

  /// Assigned status
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get assigned;

  /// In progress status
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get inProgress;

  /// Completed status
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get completed;

  /// Cancelled status
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelled;

  /// Chat page title
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chat;

  /// Messages page title
  ///
  /// In en, this message translates to:
  /// **'Messages'**
  String get messages;

  /// Message input placeholder
  ///
  /// In en, this message translates to:
  /// **'Type a message...'**
  String get typeMessage;

  /// Send button text
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get send;

  /// Attach file button text
  ///
  /// In en, this message translates to:
  /// **'Attach File'**
  String get attachFile;

  /// Take photo button text
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get takePhoto;

  /// Choose from gallery button text
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get chooseFromGallery;

  /// Rating label
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// Rate service button text
  ///
  /// In en, this message translates to:
  /// **'Rate Service'**
  String get rateService;

  /// Review input placeholder
  ///
  /// In en, this message translates to:
  /// **'Write a review...'**
  String get writeReview;

  /// Submit review button text
  ///
  /// In en, this message translates to:
  /// **'Submit Review'**
  String get submitReview;

  /// Provider label
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// Seeker label
  ///
  /// In en, this message translates to:
  /// **'Seeker'**
  String get seeker;

  /// Individual provider type
  ///
  /// In en, this message translates to:
  /// **'Individual'**
  String get individual;

  /// Organization provider type
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get organization;

  /// Business name field label
  ///
  /// In en, this message translates to:
  /// **'Business Name'**
  String get businessName;

  /// Location field label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Certificates label
  ///
  /// In en, this message translates to:
  /// **'Certificates'**
  String get certificates;

  /// Upload certificates button text
  ///
  /// In en, this message translates to:
  /// **'Upload Certificates'**
  String get uploadCertificates;

  /// Employees page title
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get employees;

  /// Add employee button text
  ///
  /// In en, this message translates to:
  /// **'Add Employee'**
  String get addEmployee;

  /// Employee name field label
  ///
  /// In en, this message translates to:
  /// **'Employee Name'**
  String get employeeName;

  /// Employee role field label
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get employeeRole;

  /// Skills field label
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Delete button text
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Edit button text
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// Search button text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search services placeholder
  ///
  /// In en, this message translates to:
  /// **'Search services...'**
  String get searchServices;

  /// Filter button text
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// Sort button text
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get sort;

  /// Price range filter label
  ///
  /// In en, this message translates to:
  /// **'Price Range'**
  String get priceRange;

  /// Distance filter label
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get distance;

  /// Notifications page title
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No notifications message
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get noNotifications;

  /// Mark as read button text
  ///
  /// In en, this message translates to:
  /// **'Mark as Read'**
  String get markAsRead;

  /// Error message title
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Success message title
  ///
  /// In en, this message translates to:
  /// **'Success'**
  String get success;

  /// Warning message title
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get warning;

  /// Info message title
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get info;

  /// Loading message
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No internet connection message
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get noInternetConnection;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get somethingWentWrong;

  /// Email verification page title
  ///
  /// In en, this message translates to:
  /// **'Email Verification'**
  String get emailVerification;

  /// Verification code field label
  ///
  /// In en, this message translates to:
  /// **'Verification Code'**
  String get verificationCode;

  /// Verify button text
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Resend code button text
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Code expired message
  ///
  /// In en, this message translates to:
  /// **'Code expired'**
  String get codeExpired;

  /// Invalid code message
  ///
  /// In en, this message translates to:
  /// **'Invalid code'**
  String get invalidCode;

  /// Email verified success message
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully'**
  String get emailVerified;

  /// Select role prompt
  ///
  /// In en, this message translates to:
  /// **'Select Role'**
  String get selectRole;

  /// Provider type field label
  ///
  /// In en, this message translates to:
  /// **'Provider Type'**
  String get providerType;

  /// Pending approval status
  ///
  /// In en, this message translates to:
  /// **'Pending Approval'**
  String get pendingApproval;

  /// Approved status
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get approved;

  /// Rejected status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Application status label
  ///
  /// In en, this message translates to:
  /// **'Application Status'**
  String get applicationStatus;

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Contact provider button text
  ///
  /// In en, this message translates to:
  /// **'Contact Provider'**
  String get contactProvider;

  /// Book service button text
  ///
  /// In en, this message translates to:
  /// **'Book Service'**
  String get bookService;

  /// Service booked success message
  ///
  /// In en, this message translates to:
  /// **'Service booked successfully'**
  String get serviceBooked;

  /// Notes field label
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// Additional notes field label
  ///
  /// In en, this message translates to:
  /// **'Additional Notes'**
  String get additionalNotes;

  /// Accept request button text
  ///
  /// In en, this message translates to:
  /// **'Accept Request'**
  String get acceptRequest;

  /// Reject request button text
  ///
  /// In en, this message translates to:
  /// **'Reject Request'**
  String get rejectRequest;

  /// Assign employee button text
  ///
  /// In en, this message translates to:
  /// **'Assign Employee'**
  String get assignEmployee;

  /// Mark in progress button text
  ///
  /// In en, this message translates to:
  /// **'Mark In Progress'**
  String get markInProgress;

  /// Mark completed button text
  ///
  /// In en, this message translates to:
  /// **'Mark Completed'**
  String get markCompleted;

  /// Request accepted message
  ///
  /// In en, this message translates to:
  /// **'Request accepted'**
  String get requestAccepted;

  /// Request rejected message
  ///
  /// In en, this message translates to:
  /// **'Request rejected'**
  String get requestRejected;

  /// Employee assigned message
  ///
  /// In en, this message translates to:
  /// **'Employee assigned'**
  String get employeeAssigned;

  /// Service completed message
  ///
  /// In en, this message translates to:
  /// **'Service completed'**
  String get serviceCompleted;

  /// Review submitted success message
  ///
  /// In en, this message translates to:
  /// **'Review submitted successfully'**
  String get reviewSubmitted;

  /// Profile updated success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdated;

  /// Service created success message
  ///
  /// In en, this message translates to:
  /// **'Service created successfully'**
  String get serviceCreated;

  /// Service updated success message
  ///
  /// In en, this message translates to:
  /// **'Service updated successfully'**
  String get serviceUpdated;

  /// Service deleted success message
  ///
  /// In en, this message translates to:
  /// **'Service deleted successfully'**
  String get serviceDeleted;

  /// Employee added success message
  ///
  /// In en, this message translates to:
  /// **'Employee added successfully'**
  String get employeeAdded;

  /// Employee updated success message
  ///
  /// In en, this message translates to:
  /// **'Employee updated successfully'**
  String get employeeUpdated;

  /// Employee deleted success message
  ///
  /// In en, this message translates to:
  /// **'Employee deleted successfully'**
  String get employeeDeleted;

  /// Confirm delete dialog message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this item?'**
  String get confirmDelete;

  /// Yes button text
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get yes;

  /// No button text
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get no;

  /// OK button text
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// Back button text
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Previous button text
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// Finish button text
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Continue button text
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueButton;

  /// English language label
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get englishLabel;

  /// Amharic language label
  ///
  /// In en, this message translates to:
  /// **'አማርኛ'**
  String get amharicLabel;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Refresh button text
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// Update button text
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Create button text
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// Submit button text
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// Apply button text
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Reset button text
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// Home page title
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Dashboard page title
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// About page title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Help page title
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// Support page title
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Contact us page title
  ///
  /// In en, this message translates to:
  /// **'Contact Us'**
  String get contactUs;

  /// Terms of service page title
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Privacy policy page title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Version label
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Email required validation message
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get validationEmailRequired;

  /// Invalid email validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get validationEmailInvalid;

  /// Password required validation message
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get validationPasswordRequired;

  /// Password length validation message
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters long'**
  String get validationPasswordLength;

  /// Confirm password required validation message
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get validationConfirmPassword;

  /// Password mismatch validation message
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get validationPasswordsMismatch;

  /// Generic required field validation message
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get validationRequired;

  /// Phone number required validation message
  ///
  /// In en, this message translates to:
  /// **'Phone number is required'**
  String get validationPhoneRequired;

  /// Invalid phone number validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number'**
  String get validationPhoneInvalid;

  /// Price required validation message
  ///
  /// In en, this message translates to:
  /// **'Price is required'**
  String get validationPriceRequired;

  /// Invalid price validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid price'**
  String get validationPriceInvalid;

  /// Duration required validation message
  ///
  /// In en, this message translates to:
  /// **'Duration is required'**
  String get validationDurationRequired;

  /// Invalid duration validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid duration in hours'**
  String get validationDurationInvalid;

  /// Error message when no role is selected during login
  ///
  /// In en, this message translates to:
  /// **'Please select your role'**
  String get selectRoleError;

  /// Welcome title on login screen
  ///
  /// In en, this message translates to:
  /// **'Welcome Back'**
  String get loginWelcomeTitle;

  /// Subtitle on login screen
  ///
  /// In en, this message translates to:
  /// **'Login to continue'**
  String get loginSubtitle;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Email field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailHint;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Password field hint text
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get passwordHint;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginButtonLabel;

  /// Forgot password link text
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPasswordLabel;

  /// Text before signup link
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get signupRedirectPrefix;

  /// Signup link text
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signupRedirectAction;

  /// Role selection header text
  ///
  /// In en, this message translates to:
  /// **'Login As'**
  String get loginAsRole;

  /// Service seeker role label
  ///
  /// In en, this message translates to:
  /// **'Service Seeker'**
  String get serviceSeekerLabel;

  /// Service provider role label
  ///
  /// In en, this message translates to:
  /// **'Service Provider'**
  String get serviceProviderLabel;

  /// Create account page title
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccountTitle;

  /// Signup page subtitle
  ///
  /// In en, this message translates to:
  /// **'Join ServeEase today'**
  String get signupSubtitle;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get nameLabel;

  /// Name validation message
  ///
  /// In en, this message translates to:
  /// **'Please enter your full name'**
  String get nameValidation;

  /// Name length validation message
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 3 characters long'**
  String get validationNameLength;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPasswordLabel;

  /// Role selection header
  ///
  /// In en, this message translates to:
  /// **'Join as'**
  String get joinAsLabel;

  /// Information note for providers
  ///
  /// In en, this message translates to:
  /// **'As a provider, you\'ll need admin approval before offering services'**
  String get providerInfoNote;

  /// Signup submit button text
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get signupSubmitLabel;

  /// Text before login link
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get loginRedirectPrefix;

  /// Login link text
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginRedirectAction;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['am', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'am': return AppLocalizationsAm();
    case 'en': return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
