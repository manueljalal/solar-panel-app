// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get locationErbilIraq => 'Erbil, Iraq';

  @override
  String get searchHint => 'Search panels, brands, packages';

  @override
  String get bannerLimitedOffer => 'LIMITED OFFER';

  @override
  String get bannerZeroDownTitle => 'Zero down payment\non residential kits';

  @override
  String get bannerGetQuote => 'Get a quote';

  @override
  String get bannerNewLabel => 'NEW';

  @override
  String get bannerBatteryTitle => 'Battery storage,\nbuilt for outages';

  @override
  String get bannerExploreBatteries => 'Explore batteries';

  @override
  String get bannerVettedNetwork => 'VETTED NETWORK';

  @override
  String get bannerVendorsTitle => 'Every vendor,\nsite-verified';

  @override
  String get bannerMeetVendors => 'Meet the vendors';

  @override
  String get sectionCompanies => 'Companies';

  @override
  String get sectionFeatured => 'Featured';

  @override
  String get sectionBestSellers => 'Best sellers';

  @override
  String get seeAll => 'See all';

  @override
  String get homeLoadError => 'Couldn\'t load content. Check your connection.';

  @override
  String get retry => 'Retry';

  @override
  String get bestMatch => 'Best match';

  @override
  String get wattageCalculatorTitle => 'Wattage calculator';

  @override
  String get wattageCalculatorSubtitle => 'Two questions, sized system.';

  @override
  String get tryIt => 'Try it';

  @override
  String get applyBannerTitle => 'Own a solar\nbusiness?';

  @override
  String get apply => 'Apply';

  @override
  String get learnTeaserTitle => 'Choosing the right wattage';

  @override
  String get learnTeaserReadTime => '4 min read';

  @override
  String productSold(int count) {
    return '$count sold';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navLearn => 'Learn';

  @override
  String get navCart => 'Cart';

  @override
  String get navOrders => 'Orders';

  @override
  String get navAccount => 'Account';

  @override
  String get cancel => 'Cancel';

  @override
  String get done => 'Done';

  @override
  String get required => 'Required';

  @override
  String get inStock => 'In stock';

  @override
  String get outOfStock => 'Out of stock';

  @override
  String get genericConnectionError =>
      'Couldn\'t send that — check your connection and try again.';

  @override
  String minRead(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min read',
      one: '1 min read',
    );
    return '$_temp0';
  }

  @override
  String get accountTitle => 'Account';

  @override
  String get accountNotSignedIn => 'Not signed in';

  @override
  String get accountSignOut => 'Sign out';

  @override
  String get accountSignIn => 'Sign in';

  @override
  String get accountLocation => 'Erbil, Iraq';

  @override
  String get accountChange => 'Change';

  @override
  String get accountOrderHistory => 'Order history';

  @override
  String get accountView => 'View';

  @override
  String get accountMyProducts => 'My products';

  @override
  String get accountManage => 'Manage';

  @override
  String get accountOwnBusiness => 'Own a solar business?';

  @override
  String get accountApply => 'Apply';

  @override
  String get accountAbout => 'About Solary';

  @override
  String get accountLanguage => 'Language';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get languageNameSorani => 'کوردی سۆرانی';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get accountAnonymousUnavailable => 'Anonymous sign-in unavailable';

  @override
  String get accountSignedIn => 'Signed in';

  @override
  String accountBrowsingAnonymously(String uid) {
    return 'Browsing anonymously · $uid…';
  }

  @override
  String get accountRoleVendor => 'Vendor';

  @override
  String get accountRoleAdmin => 'Admin';

  @override
  String get accountRoleGuest => 'Guest';

  @override
  String get phoneOtpInvalidFormat =>
      'Enter a full number with country code, e.g. +9647501234567';

  @override
  String get phoneOtpSendFailedRetry => 'Couldn\'t send a code — try again.';

  @override
  String get phoneOtpSendFailedConnection =>
      'Couldn\'t send a code — check your connection.';

  @override
  String get phoneOtpEnterCode => 'Enter the 6-digit code.';

  @override
  String get phoneOtpIncorrectCode => 'Incorrect or expired code.';

  @override
  String get phoneOtpVerifyFailedRetry => 'Couldn\'t verify — try again.';

  @override
  String get phoneOtpTitle => 'Verify your phone';

  @override
  String get phoneOtpSendBody =>
      'We\'ll send a 6-digit code to your phone number.';

  @override
  String get phoneOtpPhoneLabel => 'Phone number';

  @override
  String phoneOtpEnterCodeBody(String phone) {
    return 'Enter the code sent to $phone.';
  }

  @override
  String get phoneOtpCodeLabel => '6-digit code';

  @override
  String get phoneOtpUseDifferentNumber => 'Use a different number';

  @override
  String get phoneOtpVerifyCode => 'Verify code';

  @override
  String get phoneOtpSendCode => 'Send code';

  @override
  String get phoneOtpNameLabel => 'Your name';

  @override
  String get phoneOtpNameValidator => 'Enter your name';

  @override
  String get phoneOtpNewAccountBody =>
      'First time here — tell us your name too.';

  @override
  String phoneOtpResendIn(int seconds) {
    return 'Resend code in ${seconds}s';
  }

  @override
  String get phoneOtpResendCode => 'Resend code';

  @override
  String get phoneOtpLocationLabel => 'Your location';

  @override
  String get phoneOtpLocationRequired => 'Set your location on the map.';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get usernameLabel => 'Username';

  @override
  String get usernameValidator =>
      '3-20 characters: lowercase letters, numbers, underscores.';

  @override
  String get passwordLabel => 'Password';

  @override
  String get passwordValidator =>
      'At least 8 characters, with an uppercase letter, a lowercase letter, a number, and a symbol.';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get confirmPasswordValidator => 'Passwords don\'t match.';

  @override
  String get signUpSubmit => 'Create account';

  @override
  String get signInSubmit => 'Sign in';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get needAnAccount => 'Need an account? Create one';

  @override
  String get signUpUsernameTaken => 'That username is taken.';

  @override
  String get signUpGenericError => 'Couldn\'t create your account — try again.';

  @override
  String get signInIncorrect => 'Incorrect username or password.';

  @override
  String get signInGenericError => 'Couldn\'t sign in — try again.';

  @override
  String get stepUpTitle => 'Confirm it\'s you';

  @override
  String get stepUpBody =>
      'New device detected. We\'ll send a 6-digit code to the phone number on your account.';

  @override
  String get stepUpSendCode => 'Send code';

  @override
  String get stepUpVerifyCode => 'Confirm';

  @override
  String get cartTitle => 'Cart';

  @override
  String get cartEmptyTitle => 'Your cart is empty';

  @override
  String get cartEmptyBody => 'Browse Best sellers on Home and add something.';

  @override
  String cartSubtotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Subtotal ($count items)',
      one: 'Subtotal (1 item)',
    );
    return '$_temp0';
  }

  @override
  String get checkoutNotBuiltYet => 'Checkout isn\'t built yet — coming next.';

  @override
  String get checkout => 'Checkout';

  @override
  String get perUnit => '/ unit';

  @override
  String get description => 'Description';

  @override
  String get noDescriptionYet => 'No description provided yet.';

  @override
  String addedToCart(String title) {
    return 'Added $title to cart.';
  }

  @override
  String get specPower => 'Power';

  @override
  String get specWarranty => 'Warranty';

  @override
  String get specBrand => 'Brand';

  @override
  String get requestQuote => 'Request quote';

  @override
  String get addToCart => 'Add to cart';

  @override
  String quoteRequested(String title) {
    return 'Quote requested for $title.';
  }

  @override
  String get requestAQuote => 'Request a quote';

  @override
  String get quoteRequestHint =>
      'e.g. quantity needed, install timeline, site address';

  @override
  String get sendRequest => 'Send request';

  @override
  String searchNoResults(String query) {
    return 'No results for \"$query\"';
  }

  @override
  String get searchPrompt => 'Search for panels, brands, or vendors.';

  @override
  String get wattageCalculatorScreenTitle => 'Wattage calculator';

  @override
  String get wattageCalculatorIntro =>
      'Answer two questions and we\'ll estimate the system size and panel count your home needs.';

  @override
  String get dailyUsageTitle => 'Average daily electricity use';

  @override
  String get dailyUsageSubtitle => 'How much power your home uses per day';

  @override
  String get unitKwh => 'kWh';

  @override
  String get peakSunlightTitle => 'Peak sunlight hours';

  @override
  String get peakSunlightSubtitle =>
      'Average hours of strong daylight on your roof';

  @override
  String get unitHours => 'h';

  @override
  String get recommendedSystem => 'RECOMMENDED SYSTEM';

  @override
  String panelEstimate(int count, int wattage) {
    return '$count panels · ${wattage}W each';
  }

  @override
  String get seeMatchingPanels => 'See matching panels';

  @override
  String get wattageDisclaimer =>
      'Estimate only — a vendor will confirm exact sizing after a site visit.';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody =>
      'Orders will show up here once checkout is built.';

  @override
  String get learnTitle => 'Learn';

  @override
  String get learnArticleWattageTitle => 'Choosing the right wattage';

  @override
  String get learnArticleWattageBody =>
      'A typical home uses 10–15 kWh per day. Divide your daily usage by your roof\'s peak sunlight hours (usually 4–6 in Iraq) to estimate the system size in kW. Use the Wattage calculator on Home for a quick estimate — a vendor will confirm exact sizing after a site visit, since roof angle, shading, and panel efficiency all matter.';

  @override
  String get learnArticleInstallationTitle => 'How installation works';

  @override
  String get learnArticleInstallationBody =>
      'After you place an order, the vendor schedules a site visit to confirm mounting points and wiring routes. Installation itself typically takes 1–2 days for a residential system. The crew handles permits where required, connects the inverter, and walks you through the monitoring app before handoff.';

  @override
  String get learnArticleFinancingTitle => 'Financing & warranties';

  @override
  String get learnArticleFinancingBody =>
      'Most panels carry a 25-year power-output warranty and a shorter (10–12 year) product warranty covering defects. Batteries and inverters usually carry 5–10 year warranties. Some vendors on Solary offer zero-down-payment financing on residential kits — look for the \"Limited offer\" banner on Home.';

  @override
  String get learnArticleMaintenanceTitle => 'Maintaining your system';

  @override
  String get learnArticleMaintenanceBody =>
      'Panels need little upkeep — an occasional rinse to clear dust keeps output steady. Check the inverter\'s status light or monitoring app periodically; a red or amber light usually means it\'s worth a call to your installer. Most vendors offer an annual inspection as part of the installation package.';

  @override
  String get learnArticleNetMeteringTitle => 'Net metering explained';

  @override
  String get learnArticleNetMeteringBody =>
      'Net metering lets you send excess solar power back to the grid and draw it back later at no extra cost, effectively using the grid as a battery. Availability and terms vary by provider — ask your installer whether it applies in your area before sizing a battery into your system.';

  @override
  String get vendorApplyGenericError =>
      'Couldn\'t submit — check your connection and try again.';

  @override
  String get vendorApplyTitle => 'Own a solar business?';

  @override
  String get vendorApplyIntro =>
      'List your products and reach clients across Iraq. Tell us about your business — we\'ll follow up to verify and onboard you.';

  @override
  String get businessNameLabel => 'Business name';

  @override
  String get businessNameValidator => 'Enter your business name';

  @override
  String get cityLabel => 'City';

  @override
  String get cityValidator => 'Enter your city';

  @override
  String get phoneNumberLabel => 'Phone number';

  @override
  String get phoneNumberValidator => 'Enter a phone number';

  @override
  String get emailLabel => 'Email';

  @override
  String get emailValidator => 'Enter your email';

  @override
  String get emailInvalidError => 'Enter a valid email address';

  @override
  String get whatDoYouSellLabel => 'What do you sell? (optional)';

  @override
  String get submitApplication => 'Submit application';

  @override
  String get applicationSubmittedTitle => 'Application submitted';

  @override
  String get applicationSubmittedBody =>
      'We\'ll review it and email you the decision. Once approved, sign in to the vendor portal with your username and password.';

  @override
  String get vendorApplySignInIntro =>
      'To apply as a vendor you need a Solary account with a verified phone number.';

  @override
  String get vendorApplySignInButton => 'Sign in or create an account';

  @override
  String get vendorApplyVerifiedPhoneLabel => 'Verified phone number';

  @override
  String get vendorApplyPendingTitle => 'Application under review';

  @override
  String vendorApplyPendingBody(String business) {
    return 'We\'re reviewing $business. Once approved, sign in to the vendor portal with your username and password.';
  }

  @override
  String get vendorApplyApprovedTitle => 'You\'re approved';

  @override
  String get vendorApplyApprovedBody =>
      'Your vendor account is ready. Open the Account tab to manage your products.';

  @override
  String get vendorApplyRejectedNotice =>
      'Your previous application wasn\'t approved. You\'re welcome to apply again.';

  @override
  String get addressLabel => 'Street address';

  @override
  String get addressValidator => 'Enter your street address';

  @override
  String get mapLocationLabel => 'Map location';

  @override
  String get setLocationOnMap => 'Set location on map';

  @override
  String get changeLocation => 'Change';

  @override
  String get locationNotSet => 'Not set';

  @override
  String get locationRequiredError => 'Pin your business location on the map.';

  @override
  String get pickLocationTitle => 'Pin your location';

  @override
  String get pickLocationHint =>
      'Drag the map to position the pin, or use your current location.';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get locationPermissionDenied =>
      'Location permission denied — drag the pin manually instead.';

  @override
  String get locationServiceDisabled =>
      'Location services are off — drag the pin manually instead.';

  @override
  String get locationFetchFailed =>
      'Couldn\'t get your location — drag the pin manually instead.';

  @override
  String get myProductsTitle => 'My products';

  @override
  String get addProduct => 'Add product';

  @override
  String get couldntLoadProducts => 'Couldn\'t load your products.';

  @override
  String get noProductsYetTitle => 'No products yet';

  @override
  String get noProductsYetBody =>
      'Tap \"Add product\" to list your first item.';

  @override
  String get removeProductTitle => 'Remove this product?';

  @override
  String get remove => 'Remove';

  @override
  String get couldntRemoveProduct =>
      'Couldn\'t remove that product — try again.';

  @override
  String couldntSaveWithReason(String reason) {
    return 'Couldn\'t save — $reason';
  }

  @override
  String get errorPermissionDenied => 'you don\'t have permission to do that.';

  @override
  String get errorCheckValues => 'check the values and try again.';

  @override
  String get errorCheckConnection => 'check your connection and try again.';

  @override
  String get editProductTitle => 'Edit product';

  @override
  String get addProductTitle => 'Add product';

  @override
  String get categoryLabel => 'Category';

  @override
  String get brandLabel => 'Brand';

  @override
  String get productNameLabel => 'Product name';

  @override
  String get specLabel => 'Spec (e.g. 450W, 5kWh)';

  @override
  String get priceLabel => 'Price (USD)';

  @override
  String get priceValidator => 'Enter a valid price';

  @override
  String get imageUrlLabel => 'Image URL';

  @override
  String get warrantyOptionalLabel => 'Warranty (optional)';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get publishProduct => 'Publish product';

  @override
  String get categoryResidential => 'Residential';

  @override
  String get categoryCommercial => 'Commercial';

  @override
  String get categoryBattery => 'Battery';

  @override
  String get categoryInverter => 'Inverter';
}
