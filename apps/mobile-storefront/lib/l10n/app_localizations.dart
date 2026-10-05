import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_ckb.dart';
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
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ckb'),
    Locale('en'),
  ];

  /// No description provided for @locationErbilIraq.
  ///
  /// In en, this message translates to:
  /// **'Erbil, Iraq'**
  String get locationErbilIraq;

  /// No description provided for @searchHint.
  ///
  /// In en, this message translates to:
  /// **'Search panels, brands, packages'**
  String get searchHint;

  /// No description provided for @bannerLimitedOffer.
  ///
  /// In en, this message translates to:
  /// **'LIMITED OFFER'**
  String get bannerLimitedOffer;

  /// No description provided for @bannerZeroDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Zero down payment\non residential kits'**
  String get bannerZeroDownTitle;

  /// No description provided for @bannerGetQuote.
  ///
  /// In en, this message translates to:
  /// **'Get a quote'**
  String get bannerGetQuote;

  /// No description provided for @bannerNewLabel.
  ///
  /// In en, this message translates to:
  /// **'NEW'**
  String get bannerNewLabel;

  /// No description provided for @bannerBatteryTitle.
  ///
  /// In en, this message translates to:
  /// **'Battery storage,\nbuilt for outages'**
  String get bannerBatteryTitle;

  /// No description provided for @bannerExploreBatteries.
  ///
  /// In en, this message translates to:
  /// **'Explore batteries'**
  String get bannerExploreBatteries;

  /// No description provided for @bannerVettedNetwork.
  ///
  /// In en, this message translates to:
  /// **'VETTED NETWORK'**
  String get bannerVettedNetwork;

  /// No description provided for @bannerVendorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Every vendor,\nsite-verified'**
  String get bannerVendorsTitle;

  /// No description provided for @bannerMeetVendors.
  ///
  /// In en, this message translates to:
  /// **'Meet the vendors'**
  String get bannerMeetVendors;

  /// No description provided for @sectionCompanies.
  ///
  /// In en, this message translates to:
  /// **'Companies'**
  String get sectionCompanies;

  /// No description provided for @sectionFeatured.
  ///
  /// In en, this message translates to:
  /// **'Featured'**
  String get sectionFeatured;

  /// No description provided for @sectionBestSellers.
  ///
  /// In en, this message translates to:
  /// **'Best sellers'**
  String get sectionBestSellers;

  /// No description provided for @seeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get seeAll;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load content. Check your connection.'**
  String get homeLoadError;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @bestMatch.
  ///
  /// In en, this message translates to:
  /// **'Best match'**
  String get bestMatch;

  /// No description provided for @wattageCalculatorTitle.
  ///
  /// In en, this message translates to:
  /// **'Wattage calculator'**
  String get wattageCalculatorTitle;

  /// No description provided for @wattageCalculatorSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Two questions, sized system.'**
  String get wattageCalculatorSubtitle;

  /// No description provided for @tryIt.
  ///
  /// In en, this message translates to:
  /// **'Try it'**
  String get tryIt;

  /// No description provided for @applyBannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Own a solar\nbusiness?'**
  String get applyBannerTitle;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @learnTeaserTitle.
  ///
  /// In en, this message translates to:
  /// **'Choosing the right wattage'**
  String get learnTeaserTitle;

  /// No description provided for @learnTeaserReadTime.
  ///
  /// In en, this message translates to:
  /// **'4 min read'**
  String get learnTeaserReadTime;

  /// Sold count on a product row, e.g. '312 sold'.
  ///
  /// In en, this message translates to:
  /// **'{count} sold'**
  String productSold(int count);

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navLearn.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get navLearn;

  /// No description provided for @navCart.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get navCart;

  /// No description provided for @navOrders.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get navOrders;

  /// No description provided for @navAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get navAccount;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @required.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get required;

  /// No description provided for @inStock.
  ///
  /// In en, this message translates to:
  /// **'In stock'**
  String get inStock;

  /// No description provided for @outOfStock.
  ///
  /// In en, this message translates to:
  /// **'Out of stock'**
  String get outOfStock;

  /// No description provided for @genericConnectionError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send that — check your connection and try again.'**
  String get genericConnectionError;

  /// No description provided for @minRead.
  ///
  /// In en, this message translates to:
  /// **'{minutes, plural, one {1 min read} other {{minutes} min read}}'**
  String minRead(int minutes);

  /// No description provided for @accountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get accountTitle;

  /// No description provided for @accountNotSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Not signed in'**
  String get accountNotSignedIn;

  /// No description provided for @accountSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get accountSignOut;

  /// No description provided for @accountSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get accountSignIn;

  /// No description provided for @accountLocation.
  ///
  /// In en, this message translates to:
  /// **'Erbil, Iraq'**
  String get accountLocation;

  /// No description provided for @accountChange.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get accountChange;

  /// No description provided for @accountOrderHistory.
  ///
  /// In en, this message translates to:
  /// **'Order history'**
  String get accountOrderHistory;

  /// No description provided for @accountView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get accountView;

  /// No description provided for @accountMyProducts.
  ///
  /// In en, this message translates to:
  /// **'My products'**
  String get accountMyProducts;

  /// No description provided for @accountManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get accountManage;

  /// No description provided for @accountOwnBusiness.
  ///
  /// In en, this message translates to:
  /// **'Own a solar business?'**
  String get accountOwnBusiness;

  /// No description provided for @accountApply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get accountApply;

  /// No description provided for @accountAbout.
  ///
  /// In en, this message translates to:
  /// **'About Solary'**
  String get accountAbout;

  /// No description provided for @accountLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get accountLanguage;

  /// No description provided for @languageNameEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEnglish;

  /// No description provided for @languageNameArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageNameArabic;

  /// No description provided for @languageNameSorani.
  ///
  /// In en, this message translates to:
  /// **'کوردی سۆرانی'**
  String get languageNameSorani;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @accountAnonymousUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Anonymous sign-in unavailable'**
  String get accountAnonymousUnavailable;

  /// No description provided for @accountSignedIn.
  ///
  /// In en, this message translates to:
  /// **'Signed in'**
  String get accountSignedIn;

  /// No description provided for @accountBrowsingAnonymously.
  ///
  /// In en, this message translates to:
  /// **'Browsing anonymously · {uid}…'**
  String accountBrowsingAnonymously(String uid);

  /// No description provided for @accountRoleVendor.
  ///
  /// In en, this message translates to:
  /// **'Vendor'**
  String get accountRoleVendor;

  /// No description provided for @accountRoleAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get accountRoleAdmin;

  /// No description provided for @accountRoleGuest.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get accountRoleGuest;

  /// No description provided for @phoneOtpInvalidFormat.
  ///
  /// In en, this message translates to:
  /// **'Enter a full number with country code, e.g. +9647501234567'**
  String get phoneOtpInvalidFormat;

  /// No description provided for @phoneOtpSendFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a code — try again.'**
  String get phoneOtpSendFailedRetry;

  /// No description provided for @phoneOtpSendFailedConnection.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a code — check your connection.'**
  String get phoneOtpSendFailedConnection;

  /// No description provided for @phoneOtpEnterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter the 6-digit code.'**
  String get phoneOtpEnterCode;

  /// No description provided for @phoneOtpIncorrectCode.
  ///
  /// In en, this message translates to:
  /// **'Incorrect or expired code.'**
  String get phoneOtpIncorrectCode;

  /// No description provided for @phoneOtpVerifyFailedRetry.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t verify — try again.'**
  String get phoneOtpVerifyFailedRetry;

  /// No description provided for @phoneOtpTitle.
  ///
  /// In en, this message translates to:
  /// **'Verify your phone'**
  String get phoneOtpTitle;

  /// No description provided for @phoneOtpSendBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll send a 6-digit code to your phone number.'**
  String get phoneOtpSendBody;

  /// No description provided for @phoneOtpPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneOtpPhoneLabel;

  /// No description provided for @phoneOtpEnterCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the code sent to {phone}.'**
  String phoneOtpEnterCodeBody(String phone);

  /// No description provided for @phoneOtpCodeLabel.
  ///
  /// In en, this message translates to:
  /// **'6-digit code'**
  String get phoneOtpCodeLabel;

  /// No description provided for @phoneOtpUseDifferentNumber.
  ///
  /// In en, this message translates to:
  /// **'Use a different number'**
  String get phoneOtpUseDifferentNumber;

  /// No description provided for @phoneOtpVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Verify code'**
  String get phoneOtpVerifyCode;

  /// No description provided for @phoneOtpSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get phoneOtpSendCode;

  /// No description provided for @phoneOtpNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get phoneOtpNameLabel;

  /// No description provided for @phoneOtpNameValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your name'**
  String get phoneOtpNameValidator;

  /// No description provided for @phoneOtpNewAccountBody.
  ///
  /// In en, this message translates to:
  /// **'First time here — tell us your name too.'**
  String get phoneOtpNewAccountBody;

  /// No description provided for @phoneOtpResendIn.
  ///
  /// In en, this message translates to:
  /// **'Resend code in {seconds}s'**
  String phoneOtpResendIn(int seconds);

  /// No description provided for @phoneOtpResendCode.
  ///
  /// In en, this message translates to:
  /// **'Resend code'**
  String get phoneOtpResendCode;

  /// No description provided for @phoneOtpLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Your location'**
  String get phoneOtpLocationLabel;

  /// No description provided for @phoneOtpLocationRequired.
  ///
  /// In en, this message translates to:
  /// **'Set your location on the map.'**
  String get phoneOtpLocationRequired;

  /// No description provided for @signUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// No description provided for @signInTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// No description provided for @usernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get usernameLabel;

  /// No description provided for @usernameValidator.
  ///
  /// In en, this message translates to:
  /// **'3-20 characters: lowercase letters, numbers, underscores.'**
  String get usernameValidator;

  /// No description provided for @passwordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// No description provided for @passwordValidator.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters, with an uppercase letter, a lowercase letter, a number, and a symbol.'**
  String get passwordValidator;

  /// No description provided for @confirmPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// No description provided for @confirmPasswordValidator.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match.'**
  String get confirmPasswordValidator;

  /// No description provided for @signUpSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpSubmit;

  /// No description provided for @signInSubmit.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInSubmit;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @needAnAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Create one'**
  String get needAnAccount;

  /// No description provided for @signUpUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken.'**
  String get signUpUsernameTaken;

  /// No description provided for @signUpGenericError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create your account — try again.'**
  String get signUpGenericError;

  /// No description provided for @signInIncorrect.
  ///
  /// In en, this message translates to:
  /// **'Incorrect username or password.'**
  String get signInIncorrect;

  /// No description provided for @signInGenericError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sign in — try again.'**
  String get signInGenericError;

  /// No description provided for @stepUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm it\'s you'**
  String get stepUpTitle;

  /// No description provided for @stepUpBody.
  ///
  /// In en, this message translates to:
  /// **'New device detected. We\'ll send a 6-digit code to the phone number on your account.'**
  String get stepUpBody;

  /// No description provided for @stepUpSendCode.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get stepUpSendCode;

  /// No description provided for @stepUpVerifyCode.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get stepUpVerifyCode;

  /// No description provided for @cartTitle.
  ///
  /// In en, this message translates to:
  /// **'Cart'**
  String get cartTitle;

  /// No description provided for @cartEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your cart is empty'**
  String get cartEmptyTitle;

  /// No description provided for @cartEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Browse Best sellers on Home and add something.'**
  String get cartEmptyBody;

  /// No description provided for @cartSubtotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one {Subtotal (1 item)} other {Subtotal ({count} items)}}'**
  String cartSubtotal(int count);

  /// No description provided for @checkoutNotBuiltYet.
  ///
  /// In en, this message translates to:
  /// **'Checkout isn\'t built yet — coming next.'**
  String get checkoutNotBuiltYet;

  /// No description provided for @checkout.
  ///
  /// In en, this message translates to:
  /// **'Checkout'**
  String get checkout;

  /// No description provided for @perUnit.
  ///
  /// In en, this message translates to:
  /// **'/ unit'**
  String get perUnit;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @noDescriptionYet.
  ///
  /// In en, this message translates to:
  /// **'No description provided yet.'**
  String get noDescriptionYet;

  /// No description provided for @addedToCart.
  ///
  /// In en, this message translates to:
  /// **'Added {title} to cart.'**
  String addedToCart(String title);

  /// No description provided for @specPower.
  ///
  /// In en, this message translates to:
  /// **'Power'**
  String get specPower;

  /// No description provided for @specWarranty.
  ///
  /// In en, this message translates to:
  /// **'Warranty'**
  String get specWarranty;

  /// No description provided for @specBrand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get specBrand;

  /// No description provided for @requestQuote.
  ///
  /// In en, this message translates to:
  /// **'Request quote'**
  String get requestQuote;

  /// No description provided for @addToCart.
  ///
  /// In en, this message translates to:
  /// **'Add to cart'**
  String get addToCart;

  /// No description provided for @quoteRequested.
  ///
  /// In en, this message translates to:
  /// **'Quote requested for {title}.'**
  String quoteRequested(String title);

  /// No description provided for @requestAQuote.
  ///
  /// In en, this message translates to:
  /// **'Request a quote'**
  String get requestAQuote;

  /// No description provided for @quoteRequestHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. quantity needed, install timeline, site address'**
  String get quoteRequestHint;

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @searchNoResults.
  ///
  /// In en, this message translates to:
  /// **'No results for \"{query}\"'**
  String searchNoResults(String query);

  /// No description provided for @searchPrompt.
  ///
  /// In en, this message translates to:
  /// **'Search for panels, brands, or vendors.'**
  String get searchPrompt;

  /// No description provided for @wattageCalculatorScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Wattage calculator'**
  String get wattageCalculatorScreenTitle;

  /// No description provided for @wattageCalculatorIntro.
  ///
  /// In en, this message translates to:
  /// **'Answer two questions and we\'ll estimate the system size and panel count your home needs.'**
  String get wattageCalculatorIntro;

  /// No description provided for @dailyUsageTitle.
  ///
  /// In en, this message translates to:
  /// **'Average daily electricity use'**
  String get dailyUsageTitle;

  /// No description provided for @dailyUsageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'How much power your home uses per day'**
  String get dailyUsageSubtitle;

  /// No description provided for @unitKwh.
  ///
  /// In en, this message translates to:
  /// **'kWh'**
  String get unitKwh;

  /// No description provided for @peakSunlightTitle.
  ///
  /// In en, this message translates to:
  /// **'Peak sunlight hours'**
  String get peakSunlightTitle;

  /// No description provided for @peakSunlightSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Average hours of strong daylight on your roof'**
  String get peakSunlightSubtitle;

  /// No description provided for @unitHours.
  ///
  /// In en, this message translates to:
  /// **'h'**
  String get unitHours;

  /// No description provided for @recommendedSystem.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED SYSTEM'**
  String get recommendedSystem;

  /// No description provided for @panelEstimate.
  ///
  /// In en, this message translates to:
  /// **'{count} panels · {wattage}W each'**
  String panelEstimate(int count, int wattage);

  /// No description provided for @seeMatchingPanels.
  ///
  /// In en, this message translates to:
  /// **'See matching panels'**
  String get seeMatchingPanels;

  /// No description provided for @wattageDisclaimer.
  ///
  /// In en, this message translates to:
  /// **'Estimate only — a vendor will confirm exact sizing after a site visit.'**
  String get wattageDisclaimer;

  /// No description provided for @ordersTitle.
  ///
  /// In en, this message translates to:
  /// **'Orders'**
  String get ordersTitle;

  /// No description provided for @ordersEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No orders yet'**
  String get ordersEmptyTitle;

  /// No description provided for @ordersEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Orders will show up here once checkout is built.'**
  String get ordersEmptyBody;

  /// No description provided for @learnTitle.
  ///
  /// In en, this message translates to:
  /// **'Learn'**
  String get learnTitle;

  /// No description provided for @learnArticleWattageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choosing the right wattage'**
  String get learnArticleWattageTitle;

  /// No description provided for @learnArticleWattageBody.
  ///
  /// In en, this message translates to:
  /// **'A typical home uses 10–15 kWh per day. Divide your daily usage by your roof\'s peak sunlight hours (usually 4–6 in Iraq) to estimate the system size in kW. Use the Wattage calculator on Home for a quick estimate — a vendor will confirm exact sizing after a site visit, since roof angle, shading, and panel efficiency all matter.'**
  String get learnArticleWattageBody;

  /// No description provided for @learnArticleInstallationTitle.
  ///
  /// In en, this message translates to:
  /// **'How installation works'**
  String get learnArticleInstallationTitle;

  /// No description provided for @learnArticleInstallationBody.
  ///
  /// In en, this message translates to:
  /// **'After you place an order, the vendor schedules a site visit to confirm mounting points and wiring routes. Installation itself typically takes 1–2 days for a residential system. The crew handles permits where required, connects the inverter, and walks you through the monitoring app before handoff.'**
  String get learnArticleInstallationBody;

  /// No description provided for @learnArticleFinancingTitle.
  ///
  /// In en, this message translates to:
  /// **'Financing & warranties'**
  String get learnArticleFinancingTitle;

  /// No description provided for @learnArticleFinancingBody.
  ///
  /// In en, this message translates to:
  /// **'Most panels carry a 25-year power-output warranty and a shorter (10–12 year) product warranty covering defects. Batteries and inverters usually carry 5–10 year warranties. Some vendors on Solary offer zero-down-payment financing on residential kits — look for the \"Limited offer\" banner on Home.'**
  String get learnArticleFinancingBody;

  /// No description provided for @learnArticleMaintenanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Maintaining your system'**
  String get learnArticleMaintenanceTitle;

  /// No description provided for @learnArticleMaintenanceBody.
  ///
  /// In en, this message translates to:
  /// **'Panels need little upkeep — an occasional rinse to clear dust keeps output steady. Check the inverter\'s status light or monitoring app periodically; a red or amber light usually means it\'s worth a call to your installer. Most vendors offer an annual inspection as part of the installation package.'**
  String get learnArticleMaintenanceBody;

  /// No description provided for @learnArticleNetMeteringTitle.
  ///
  /// In en, this message translates to:
  /// **'Net metering explained'**
  String get learnArticleNetMeteringTitle;

  /// No description provided for @learnArticleNetMeteringBody.
  ///
  /// In en, this message translates to:
  /// **'Net metering lets you send excess solar power back to the grid and draw it back later at no extra cost, effectively using the grid as a battery. Availability and terms vary by provider — ask your installer whether it applies in your area before sizing a battery into your system.'**
  String get learnArticleNetMeteringBody;

  /// No description provided for @vendorApplyGenericError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t submit — check your connection and try again.'**
  String get vendorApplyGenericError;

  /// No description provided for @vendorApplyTitle.
  ///
  /// In en, this message translates to:
  /// **'Own a solar business?'**
  String get vendorApplyTitle;

  /// No description provided for @vendorApplyIntro.
  ///
  /// In en, this message translates to:
  /// **'List your products and reach clients across Iraq. Tell us about your business — we\'ll follow up to verify and onboard you.'**
  String get vendorApplyIntro;

  /// No description provided for @businessNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Business name'**
  String get businessNameLabel;

  /// No description provided for @businessNameValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your business name'**
  String get businessNameValidator;

  /// No description provided for @cityLabel.
  ///
  /// In en, this message translates to:
  /// **'City'**
  String get cityLabel;

  /// No description provided for @cityValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your city'**
  String get cityValidator;

  /// No description provided for @phoneNumberLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone number'**
  String get phoneNumberLabel;

  /// No description provided for @phoneNumberValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a phone number'**
  String get phoneNumberValidator;

  /// No description provided for @emailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @emailValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get emailValidator;

  /// No description provided for @emailInvalidError.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get emailInvalidError;

  /// No description provided for @whatDoYouSellLabel.
  ///
  /// In en, this message translates to:
  /// **'What do you sell? (optional)'**
  String get whatDoYouSellLabel;

  /// No description provided for @submitApplication.
  ///
  /// In en, this message translates to:
  /// **'Submit application'**
  String get submitApplication;

  /// No description provided for @applicationSubmittedTitle.
  ///
  /// In en, this message translates to:
  /// **'Application submitted'**
  String get applicationSubmittedTitle;

  /// No description provided for @applicationSubmittedBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ll review it and email you the decision. Once approved, sign in to the vendor portal with your username and password.'**
  String get applicationSubmittedBody;

  /// No description provided for @vendorApplySignInIntro.
  ///
  /// In en, this message translates to:
  /// **'To apply as a vendor you need a Solary account with a verified phone number.'**
  String get vendorApplySignInIntro;

  /// No description provided for @vendorApplySignInButton.
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account'**
  String get vendorApplySignInButton;

  /// No description provided for @vendorApplyVerifiedPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Verified phone number'**
  String get vendorApplyVerifiedPhoneLabel;

  /// No description provided for @vendorApplyPendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Application under review'**
  String get vendorApplyPendingTitle;

  /// No description provided for @vendorApplyPendingBody.
  ///
  /// In en, this message translates to:
  /// **'We\'re reviewing {business}. Once approved, sign in to the vendor portal with your username and password.'**
  String vendorApplyPendingBody(String business);

  /// No description provided for @vendorApplyApprovedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re approved'**
  String get vendorApplyApprovedTitle;

  /// No description provided for @vendorApplyApprovedBody.
  ///
  /// In en, this message translates to:
  /// **'Your vendor account is ready. Open the Account tab to manage your products.'**
  String get vendorApplyApprovedBody;

  /// No description provided for @vendorApplyRejectedNotice.
  ///
  /// In en, this message translates to:
  /// **'Your previous application wasn\'t approved. You\'re welcome to apply again.'**
  String get vendorApplyRejectedNotice;

  /// No description provided for @addressLabel.
  ///
  /// In en, this message translates to:
  /// **'Street address'**
  String get addressLabel;

  /// No description provided for @addressValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter your street address'**
  String get addressValidator;

  /// No description provided for @mapLocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Map location'**
  String get mapLocationLabel;

  /// No description provided for @setLocationOnMap.
  ///
  /// In en, this message translates to:
  /// **'Set location on map'**
  String get setLocationOnMap;

  /// No description provided for @changeLocation.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get changeLocation;

  /// No description provided for @locationNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get locationNotSet;

  /// No description provided for @locationRequiredError.
  ///
  /// In en, this message translates to:
  /// **'Pin your business location on the map.'**
  String get locationRequiredError;

  /// No description provided for @pickLocationTitle.
  ///
  /// In en, this message translates to:
  /// **'Pin your location'**
  String get pickLocationTitle;

  /// No description provided for @pickLocationHint.
  ///
  /// In en, this message translates to:
  /// **'Drag the map to position the pin, or use your current location.'**
  String get pickLocationHint;

  /// No description provided for @confirmLocation.
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// No description provided for @locationPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permission denied — drag the pin manually instead.'**
  String get locationPermissionDenied;

  /// No description provided for @locationServiceDisabled.
  ///
  /// In en, this message translates to:
  /// **'Location services are off — drag the pin manually instead.'**
  String get locationServiceDisabled;

  /// No description provided for @locationFetchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get your location — drag the pin manually instead.'**
  String get locationFetchFailed;

  /// No description provided for @myProductsTitle.
  ///
  /// In en, this message translates to:
  /// **'My products'**
  String get myProductsTitle;

  /// No description provided for @addProduct.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProduct;

  /// No description provided for @couldntLoadProducts.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your products.'**
  String get couldntLoadProducts;

  /// No description provided for @noProductsYetTitle.
  ///
  /// In en, this message translates to:
  /// **'No products yet'**
  String get noProductsYetTitle;

  /// No description provided for @noProductsYetBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Add product\" to list your first item.'**
  String get noProductsYetBody;

  /// No description provided for @removeProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove this product?'**
  String get removeProductTitle;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @couldntRemoveProduct.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t remove that product — try again.'**
  String get couldntRemoveProduct;

  /// No description provided for @couldntSaveWithReason.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save — {reason}'**
  String couldntSaveWithReason(String reason);

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'you don\'t have permission to do that.'**
  String get errorPermissionDenied;

  /// No description provided for @errorCheckValues.
  ///
  /// In en, this message translates to:
  /// **'check the values and try again.'**
  String get errorCheckValues;

  /// No description provided for @errorCheckConnection.
  ///
  /// In en, this message translates to:
  /// **'check your connection and try again.'**
  String get errorCheckConnection;

  /// No description provided for @editProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit product'**
  String get editProductTitle;

  /// No description provided for @addProductTitle.
  ///
  /// In en, this message translates to:
  /// **'Add product'**
  String get addProductTitle;

  /// No description provided for @categoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryLabel;

  /// No description provided for @brandLabel.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get brandLabel;

  /// No description provided for @productNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Product name'**
  String get productNameLabel;

  /// No description provided for @specLabel.
  ///
  /// In en, this message translates to:
  /// **'Spec (e.g. 450W, 5kWh)'**
  String get specLabel;

  /// No description provided for @priceLabel.
  ///
  /// In en, this message translates to:
  /// **'Price (USD)'**
  String get priceLabel;

  /// No description provided for @priceValidator.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid price'**
  String get priceValidator;

  /// No description provided for @imageUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Image URL'**
  String get imageUrlLabel;

  /// No description provided for @warrantyOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Warranty (optional)'**
  String get warrantyOptionalLabel;

  /// No description provided for @descriptionOptionalLabel.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// No description provided for @saveChanges.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// No description provided for @publishProduct.
  ///
  /// In en, this message translates to:
  /// **'Publish product'**
  String get publishProduct;

  /// No description provided for @categoryResidential.
  ///
  /// In en, this message translates to:
  /// **'Residential'**
  String get categoryResidential;

  /// No description provided for @categoryCommercial.
  ///
  /// In en, this message translates to:
  /// **'Commercial'**
  String get categoryCommercial;

  /// No description provided for @categoryBattery.
  ///
  /// In en, this message translates to:
  /// **'Battery'**
  String get categoryBattery;

  /// No description provided for @categoryInverter.
  ///
  /// In en, this message translates to:
  /// **'Inverter'**
  String get categoryInverter;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'ckb', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'ckb':
      return AppLocalizationsCkb();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
