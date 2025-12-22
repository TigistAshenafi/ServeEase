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

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ServeEase'**
  String get appTitle;

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
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @loginAsRole.
  ///
  /// In en, this message translates to:
  /// **'Login as'**
  String get loginAsRole;

  /// No description provided for @selectRoleError.
  ///
  /// In en, this message translates to:
  /// **'Please select your role'**
  String get selectRoleError;
  /// No description provided for @provider.
  ///
  /// In en, this message translates to:
  /// **'Provider'**
  String get provider;

  /// No description provided for @seeker.
  ///
  /// In en, this message translates to:
  /// **'Seeker'**
  String get seeker;

// String get validationNameRequired;
String get validationNameLength;


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
