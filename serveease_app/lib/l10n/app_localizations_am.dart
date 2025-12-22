// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Amharic (`am`).
class AppLocalizationsAm extends AppLocalizations {
  AppLocalizationsAm([String locale = 'am']) : super(locale);

  @override
  String get appTitle => 'ServeEase';

  @override
  String get englishLabel => 'EN';

  @override
  String get amharicLabel => 'አማ';

  @override
  String get loginWelcomeTitle => 'እንኳን ደህና መጡ';

  @override
  String get providerInfoNote => 'እንደ አቅራቢ ኢሜልዎን ማረጋገጥ በኋላ መግለጫዎን ማቋቋም ይኖርቦታል።';

  @override
  String get nameLabel => 'ሙሉ ስም';

  @override
  String get nameValidation => 'እባክዎ ስምዎን ያስገቡ';

 @override
  String get validationNameLength => 'ስም ቢያንስ 3 ፊደላት መሆን አለበት';

  @override
  String get loginSubtitle => 'ለመቀጠል ወደ መለያዎ ይግቡ';

  @override
  String get emailLabel => 'ኢሜይል';

  @override
  String get emailHint => 'ኢሜይልዎን ያስገቡ';

  @override
  String get passwordLabel => 'የይለፍ ቃል';
  @override
  String get passwordHint => 'የይለፍ ቃልዎን ያስገቡ';

  @override
  String get selectRoleError => 'እባክዎ የእርስዎን ምድብ ይምረጡ';

  @override
  String get forgotPasswordLabel => 'የይለፍ ቃል ረሳዎት?';

  @override
  String get loginButtonLabel => 'ግባ';

  @override
  String get signupRedirectPrefix => 'አካውንት የለዎትም? ';

  @override
  String get signupRedirectAction => 'ይመዝገቡ';

  @override
  String get loginRedirectPrefix => 'መለያ አለዎት? ';

  @override
  String get loginRedirectAction => 'ግባ';

  @override
  String get loginSuccessMessage => 'በትክክል ገብተዋል!';

  @override
  String loginFailed(Object reason) {
    return 'መግቢያ አልተሳካም';
  }

  @override
  String errorWithMessage(Object message) {
    return 'ስህተት፡ $message';
  }

  @override
  String get unknownError => 'አልተጠበቀ ችግኝ ተፈጥሯል። እባክዎ ደግመው ይሞክሩ።';

  @override
  String get createAccountTitle => 'መለያዎን ይፍጠሩ';

  @override
  String get signupSubtitle => 'ServeEase ጋር ተቀላቅለው አገልግሎቶችን ይፈልጉ ወይም ችሎታዎን ያቅርቡ።';

  @override
  String get confirmPasswordLabel => 'የይለፍ ቃል ያረጋግጡ';

  @override
  String get joinAsLabel => 'ይቀላቀሉ እንደ:';

  @override
  String get providerDetailsTitle => 'የአቅራቢ መረጃ';

  @override
  String get businessNameLabel => 'የንግድ / ብራንድ ስም';

  @override
  String get serviceDescriptionLabel => 'የአገልግሎት መግለጫ';

  @override
  String get providerBusinessValidation => 'ለአቅራቢዎች የንግድ ስም አስፈላጊ ነው';

  @override
  String get signupSubmitLabel => 'ይመዝገቡ';

  @override
  String get providerSubmitLabel => 'የአቅራቢ ጥያቄ ያስገቡ';

  @override
  String get serviceSeekerLabel => 'የአገልግሎት ፈላጊ';

  @override
  String get serviceProviderLabel => 'የአገልግሎት አቅራቢ';

  @override
  String get validationEmailRequired => 'ኢሜል ያስፈልጋል';

  @override
  String get validationEmailInvalid => 'የተሳሳተ ኢሜል';

  @override
  String get validationPasswordRequired => 'የይለፍ ቃል ያስፈልጋል';

  @override
  String get validationPasswordLength => 'የይለፍ ቃል ቢያንስ 6 ቁምፊ መሆን አለበት';

  @override
  String get validationConfirmPassword => 'የይለፍ ቃልን ያረጋግጡ';

  @override
  String get validationPasswordsMismatch => 'የይለፍ ቃሎቹ አይመሳሰሉም';

  @override
  String get verifyEmailTitle => 'ኢሜልዎን ያረጋግጡ';

  @override
  String verifyEmailInfo(Object email) {
    return 'የማረጋገጫ ኮድ ወደ $email ተልኳል።';
  }

  @override
  String get verificationCodeLabel => 'የማረጋገጫ ኮድ';

  @override
  String get verifyButtonLabel => 'ያረጋግጡ';

  @override
  String get missingEmailError => 'ኢሜል አልተገኘም';

  @override
  String get emailVerifiedMessage => 'ኢሜሉ ተረጋገጠ። እባክዎ ይግቡ።';

  @override
  String get homeTitle => 'ServeEase መነሻ';

  @override
  String get homeWelcome => 'እንኳን ወደ ServeEase በደህና መጡ!';

  @override
  String get homeSubtitle => 'አገልግሎቶችን ይመልከቱ፣ ጥያቄዎችን ያቀርቡ እና መለያዎን ያቆጣጠሩ።';

  @override
  String get homeExploreButton => 'አገልግሎቶችን ይመልከቱ';

  @override
  String get backToLoginLabel => 'ወደ መግቢያ ተመለስ';

  @override
  String get emptyVerificationCode => 'የማረጋገጫ ኮድ ያስገቡ';

  @override
  String get forgotPasswordTitle => 'የምስጢር ቃል ይረሳዎታል?';

  @override
  String get forgotPasswordSubtitle => 'ኢሜሎን እና አዲስ የምስጢር ቃል መቀየር መመሪያ እንዲልክልዎ ያስገቡ።';

  @override
  String get sendResetLinkButton => 'የማስመለሻ አገናኝ ላክ';

  @override
  String get rememberPasswordPrefix => 'የይለፍ ቃልዎን ያስታውሱ? ';

  @override
  String get rememberPasswordAction => 'ግባ';

  @override
  String get resetCodeSentMessage => 'የማስመለሻ ኮድ ወደ ኢሜሎዎ ተልኳል።';

  @override
  String get providerCategoryLabel => 'ምድብ';

  @override
  String get providerDescriptionValidation => 'ለፈላጊዎች የምታቀርቡትን አገልግሎት ይግለጹ';

  @override
  String get providerCategoryValidation => 'ምድብ አስፈላጊ ነው';

  @override
  String get providerProfileSuccess => 'የአቅራቢ መግለጫ በተሳካ ሁኔታ ተፈጥሯል!';

  @override
  String get providerProfileSetup => 'የአቅራቢ መግለጫ ቅጽ';

  @override
  String get selectLoginRole => 'እባክዎ የመግቢያ ሚና ይምረጡ';

  @override
  String get welcome => 'እንኳን ደህና መጡ';

  @override
  String get loginAsRole => 'እንደ ማን ይግቡ';

  @override
  String get provider => 'አቅራቢ';

  @override
  String get seeker => 'ፍለጋ የሚያደርግ';
}
