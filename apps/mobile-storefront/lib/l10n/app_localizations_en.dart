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
  String get companyNoProducts =>
      'This company hasn\'t listed any products yet.';

  @override
  String get categoryAll => 'All';

  @override
  String get sectionCategories => 'Categories';

  @override
  String get categoryNoProducts => 'No products in this category yet.';

  @override
  String get learnEmpty => 'No lessons yet. Check back soon.';

  @override
  String get learnVideoError => 'Couldn\'t play this video.';

  @override
  String get learnTeaserSubtitle => 'Watch short video guides';

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
  String get applyBannerSubtitle =>
      'List your products and reach clients across Iraq.';

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
  String get seeMatchingPanels => 'See matching panels';

  @override
  String get wattageDisclaimer =>
      'Estimate only — a vendor will confirm exact sizing after a site visit.';

  @override
  String get ordersTitle => 'Orders';

  @override
  String get ordersEmptyTitle => 'No orders yet';

  @override
  String get ordersEmptyBody => 'When you place an order it will show up here.';

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
  String get companyImageLabel => 'Image of your company (logo or storefront)';

  @override
  String get companyImageAdd => 'Choose an image';

  @override
  String get companyImageChange => 'Change image';

  @override
  String get companyImageRequiredError => 'Add an image of your company.';

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

  @override
  String get homeBulkTitle => 'B2B\nmarketplace';

  @override
  String get homeBulkSubtitle =>
      'Trade directly with other companies — wholesale prices and bulk requests.';

  @override
  String get homeBulkCta => 'Open';

  @override
  String get bulkMarketTitle => 'B2B marketplace';

  @override
  String get bulkTabWholesale => 'Wholesale';

  @override
  String get bulkTabRequests => 'Requests';

  @override
  String get bulkTabMine => 'My posts';

  @override
  String get bulkPostFab => 'Post';

  @override
  String get bulkPostListing => 'Post a wholesale offer';

  @override
  String get bulkPostListingHint => 'Sell in bulk with quantity price tiers';

  @override
  String get bulkPostRequest => 'Post a bulk request';

  @override
  String get bulkPostRequestHint => 'Tell suppliers what you need to buy';

  @override
  String get bulkEmptyListings => 'No wholesale offers yet.';

  @override
  String get bulkEmptyRequests => 'No bulk requests yet.';

  @override
  String get bulkEmptyMine => 'You haven\'t posted anything yet.';

  @override
  String get bulkLoadError => 'Couldn\'t load the marketplace.';

  @override
  String get bulkCountryAll => 'All';

  @override
  String get bulkCountryIraq => 'Iraq';

  @override
  String get bulkCountryChina => 'China';

  @override
  String bulkFromPrice(String price, String unit) {
    return 'From $price / $unit';
  }

  @override
  String bulkMinOrder(String amount) {
    return 'Min. order $amount';
  }

  @override
  String bulkQuantityNeeded(String amount) {
    return '$amount needed';
  }

  @override
  String bulkTargetPrice(String amount) {
    return 'Target $amount';
  }

  @override
  String bulkTierRow(String qty, String unit) {
    return '$qty+ $unit';
  }

  @override
  String get bulkPriceTiers => 'Price tiers';

  @override
  String bulkDeliverTo(String city) {
    return 'Deliver to $city';
  }

  @override
  String get bulkContactSupplier => 'Contact';

  @override
  String get bulkCall => 'Call';

  @override
  String get bulkWhatsApp => 'WhatsApp';

  @override
  String get bulkClosePost => 'Close post';

  @override
  String get bulkClosed => 'Closed';

  @override
  String get bulkYours => 'Yours';

  @override
  String get bulkFormTitleLabel => 'Title';

  @override
  String get bulkFormTitleHint => 'e.g. 450W mono panels';

  @override
  String get bulkFormDescriptionLabel => 'Details';

  @override
  String get bulkFormUnitLabel => 'Unit';

  @override
  String get bulkFormUnitHint => 'pcs, panels, kg…';

  @override
  String get bulkTierQtyLabel => 'From quantity';

  @override
  String get bulkTierPriceLabel => 'Unit price (USD)';

  @override
  String get bulkAddTier => 'Add price tier';

  @override
  String get bulkRemoveTier => 'Remove';

  @override
  String get bulkQuantityLabel => 'Quantity needed';

  @override
  String get bulkTargetPriceLabel => 'Target price per unit, USD (optional)';

  @override
  String get bulkDeliveryCityLabel => 'Delivery city (optional)';

  @override
  String get bulkSubmitPost => 'Post';

  @override
  String get bulkFieldRequired => 'Required';

  @override
  String get bulkInvalidNumber => 'Enter a valid number';

  @override
  String get bulkPosted => 'Posted';

  @override
  String get bulkPostFailed => 'Couldn\'t post. Try again.';

  @override
  String get bulkDuplicateTier => 'Each price tier needs a different quantity.';

  @override
  String get applyCountryLabel => 'Company country';

  @override
  String get signInIdentifierLabel => 'Username or email';

  @override
  String get bulkOpenMarket => 'Open B2B marketplace';

  @override
  String get bulkSortNewest => 'Newest';

  @override
  String get bulkSortPriceLow => 'Price: low to high';

  @override
  String get bulkSortQtyHigh => 'Quantity: high to low';

  @override
  String get bulkNoResults => 'Nothing matches these filters.';

  @override
  String get bulkFormCategoryLabel => 'Category (optional)';

  @override
  String get bulkFormCategoryNone => 'No category';

  @override
  String get bulkLanguagesHint =>
      'Write in any language you like — buyers see it in theirs when available.';

  @override
  String get bulkFormPhotoLabel => 'Photo (optional)';

  @override
  String get bulkFormPhotoAdd => 'Add a photo';

  @override
  String get bulkFormPhotoChange => 'Change photo';

  @override
  String get bulkTitleNeeded => 'Add a title in at least one language.';

  @override
  String get signUpPhoneTaken =>
      'An account with this phone number already exists. Sign in instead, or use a different number.';

  @override
  String get checkoutTitle => 'Checkout';

  @override
  String get checkoutDeliverTo => 'Delivery location';

  @override
  String get checkoutChooseLocation => 'Choose on map';

  @override
  String get checkoutAddressLabel => 'Address details';

  @override
  String get checkoutAddressHint => 'Street, building, nearest landmark';

  @override
  String get checkoutNoteLabel => 'Note for the seller (optional)';

  @override
  String get checkoutPayment => 'Payment';

  @override
  String get checkoutCod => 'Cash on delivery';

  @override
  String get checkoutCodHint =>
      'Pay the seller in cash when your order arrives.';

  @override
  String get checkoutSummary => 'Order summary';

  @override
  String get checkoutTotal => 'Total';

  @override
  String get checkoutPlaceOrder => 'Place order';

  @override
  String get checkoutSellersNote =>
      'Items from several sellers become separate orders — each seller confirms and delivers its own.';

  @override
  String get checkoutSignInTitle => 'Sign in to place an order';

  @override
  String get checkoutSignInBody =>
      'Orders need an account with a verified phone so the seller can call you to confirm.';

  @override
  String get checkoutLocationRequired =>
      'Choose your delivery location on the map.';

  @override
  String get checkoutAddressRequired => 'Enter your address details.';

  @override
  String get checkoutFailed => 'Couldn\'t place your order. Try again.';

  @override
  String get orderPlacedTitle => 'Order placed';

  @override
  String get orderPlacedBody =>
      'The seller will call you to confirm. Pay in cash when it arrives.';

  @override
  String get orderViewOrders => 'View my orders';

  @override
  String get orderStatusPlaced => 'Waiting for seller';

  @override
  String get orderStatusConfirmed => 'Confirmed';

  @override
  String get orderStatusOutForDelivery => 'On the way';

  @override
  String get orderStatusDelivered => 'Delivered';

  @override
  String get orderStatusCancelled => 'Cancelled';

  @override
  String get ordersSignInTitle => 'Sign in to see your orders';

  @override
  String orderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String get orderCancel => 'Cancel order';

  @override
  String get orderCancelConfirmTitle => 'Cancel this order?';

  @override
  String get orderCancelConfirmBody =>
      'The seller hasn\'t confirmed it yet, so you can still cancel.';

  @override
  String get orderKeep => 'Keep order';

  @override
  String get orderCancelledToast => 'Order cancelled.';

  @override
  String get orderActionFailed => 'Something went wrong. Try again.';

  @override
  String get orderDeliverTo => 'Deliver to';

  @override
  String orderFrom(String seller) {
    return 'From $seller';
  }

  @override
  String orderCancelReason(String reason) {
    return 'Reason: $reason';
  }

  @override
  String get quoteSignInBody =>
      'Sign in so the seller can call you back with a price.';

  @override
  String get cityAll => 'All cities';

  @override
  String get cityPickerTitle => 'Choose a city';

  @override
  String companiesNoneInCity(String city) {
    return 'No companies in $city yet.';
  }

  @override
  String get cityChoose => 'Choose your city';

  @override
  String get navServices => 'Services';

  @override
  String get servicesTitle => 'Services';

  @override
  String get servicesIntro => 'Book a solar expert to your home.';

  @override
  String get serviceInstallation => 'Installation';

  @override
  String get serviceInstallationHint =>
      'Site visit, mounting, wiring and setup';

  @override
  String get serviceCleaning => 'Panel cleaning';

  @override
  String get serviceCleaningHint =>
      'Dust and dirt cut your power — get them cleaned';

  @override
  String get serviceCallCenter => 'Call center';

  @override
  String get serviceCallCenterHint => 'Questions, problems or help choosing';

  @override
  String get serviceCall => 'Call';

  @override
  String get serviceWhatsApp => 'WhatsApp';

  @override
  String get serviceSupportNotSet =>
      'Our call center number will be available soon.';

  @override
  String get serviceMyRequests => 'My requests';

  @override
  String get serviceNoRequests => 'You haven\'t booked a service yet.';

  @override
  String get serviceRequestTitleInstallation => 'Book an installation';

  @override
  String get serviceRequestTitleCleaning => 'Book a panel cleaning';

  @override
  String get serviceLocation => 'Location';

  @override
  String get servicePreferredDate => 'Preferred date (optional)';

  @override
  String get serviceAnyDate => 'Any day';

  @override
  String get servicePanelCount => 'Number of panels (optional)';

  @override
  String get serviceSystemSize => 'System size in kW (optional)';

  @override
  String get serviceNote => 'Anything we should know? (optional)';

  @override
  String get serviceSubmit => 'Send request';

  @override
  String get serviceSent => 'Request sent — we\'ll call you to confirm a time.';

  @override
  String get serviceFailed => 'Couldn\'t send your request. Try again.';

  @override
  String get serviceSignInBody =>
      'Sign in so our team can call you to arrange the visit.';

  @override
  String get serviceStatusNew => 'Waiting for confirmation';

  @override
  String get serviceStatusScheduled => 'Scheduled';

  @override
  String get serviceStatusCompleted => 'Completed';

  @override
  String get serviceStatusCancelled => 'Cancelled';

  @override
  String serviceScheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String get serviceCancel => 'Cancel request';

  @override
  String get accountHelp => 'Help & support';

  @override
  String get accountB2B => 'B2B marketplace';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get accountDeleteTitle => 'Delete your account?';

  @override
  String get accountDeleteBody =>
      'This permanently removes your account and profile. Past orders stay with the sellers as records. This can\'t be undone.';

  @override
  String get accountDeleteConfirm => 'Delete';

  @override
  String get accountDeleted => 'Your account was deleted.';

  @override
  String get accountDeleteFailed => 'Couldn\'t delete your account. Try again.';

  @override
  String get aboutBody =>
      'Solary connects you with trusted solar companies across Iraq — panels, batteries, inverters, installation and cleaning.';

  @override
  String aboutVersion(String version) {
    return 'Version $version';
  }

  @override
  String get accountGuestTitle => 'Sign in to Solary';

  @override
  String get accountGuestBody =>
      'Track your orders, book installations and keep your details in one place.';

  @override
  String get accountCreateAccount => 'Create account';

  @override
  String get accountEditProfile => 'Edit profile';

  @override
  String get accountYourName => 'Your name';

  @override
  String get accountSave => 'Save';

  @override
  String get accountSaved => 'Saved.';

  @override
  String get accountMyOrders => 'My orders';

  @override
  String get accountMyServices => 'My service requests';

  @override
  String get accountSectionActivity => 'Activity';

  @override
  String get accountSectionBusiness => 'Business';

  @override
  String get accountSectionPreferences => 'Preferences';

  @override
  String get accountSectionSupport => 'Help';

  @override
  String get accountCity => 'City';

  @override
  String get accountNotSet => 'Not set';

  @override
  String get learnCourses => 'Courses';

  @override
  String get learnQuickVideos => 'Quick videos';

  @override
  String learnEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count episodes',
      one: '1 episode',
    );
    return '$_temp0';
  }

  @override
  String learnMinutes(int count) {
    return '$count min';
  }

  @override
  String get learnFree => 'Free';

  @override
  String get learnPremium => 'Premium';

  @override
  String get learnFreePreview => 'Free preview';

  @override
  String learnEpisodeN(int number) {
    return 'Episode $number';
  }

  @override
  String get learnLockedTitle => 'Premium course';

  @override
  String get learnLockedBody =>
      'Paid courses are coming soon. You can watch the first episode for free now.';

  @override
  String get learnStartCourse => 'Start course';

  @override
  String get profileTitle => 'Edit profile';

  @override
  String get profileDetails => 'Your details';

  @override
  String get profileEmailOptional => 'Email (optional)';

  @override
  String get profileEmailHint => 'Used for receipts and to sign in';

  @override
  String get profilePhoneVerified => 'Verified phone';

  @override
  String get profilePhoneNote =>
      'Your phone is your verified sign-in number and can\'t be changed here.';

  @override
  String get profileSecurity => 'Security';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get profileSaved => 'Profile saved.';

  @override
  String get profileSaveFailed => 'Couldn\'t save your profile. Try again.';

  @override
  String get passwordCurrent => 'Current password';

  @override
  String get passwordNew => 'New password';

  @override
  String get passwordConfirm => 'Confirm new password';

  @override
  String get passwordMismatch => 'Passwords don\'t match.';

  @override
  String get passwordRequired => 'Enter your current password.';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get passwordChangeFailed =>
      'Couldn\'t change your password. Try again.';

  @override
  String get profilePersonalInfo => 'Personal info';

  @override
  String get profileLoginSecurity => 'Login & security';

  @override
  String get profileAdd => 'Add';

  @override
  String get profileNameHelp =>
      'This is how sellers and our team will address you.';

  @override
  String get profileUsernameHelp =>
      'You can sign in with your username. 3–20 lowercase letters, numbers or underscores.';

  @override
  String get profileEmailHelp =>
      'Optional. Used for receipts, and you can sign in with it.';

  @override
  String get profileRemoveEmail => 'Remove email';

  @override
  String get addressTitle => 'Delivery address';

  @override
  String get addressNone => 'Not set';

  @override
  String get addressHelp =>
      'Used automatically at checkout and when booking a service. You can still change it each time.';

  @override
  String get addressSaved => 'Address saved.';

  @override
  String get ratingNew => 'New';

  @override
  String get accountFavorites => 'Favourites';

  @override
  String get favoritesEmpty => 'Tap ♡ on a product to save it here.';

  @override
  String get legalPrivacy => 'Privacy policy';

  @override
  String get legalTerms => 'Terms of use';

  @override
  String get legalAgree => 'By creating an account you agree to the';

  @override
  String get legalAnd => 'and';

  @override
  String get calcOnGrid => 'On-grid';

  @override
  String get calcHybrid => 'Hybrid';

  @override
  String get calcOffGrid => 'Off-grid';

  @override
  String get calcOnGridTitle => 'On-grid solar calculator';

  @override
  String get calcOnGridSubtitle =>
      'Size a solar system that works alongside the grid';

  @override
  String get calcHybridTitle => 'Hybrid system calculator';

  @override
  String get calcHybridSubtitle =>
      'Size a system that combines the grid with battery storage';

  @override
  String get calcOffGridTitle => 'Off-grid system calculator';

  @override
  String get calcOffGridSubtitle =>
      'Size a standalone system that runs on panels and batteries only';

  @override
  String get calcBatteryOption => 'Battery option';

  @override
  String get calcIncludeBattery => 'Include battery';

  @override
  String get calcPhase => 'Phase';

  @override
  String get calcSinglePhase => 'Single phase';

  @override
  String get calcThreePhase => 'Three phase';

  @override
  String get calcAmps => 'Amps (A)';

  @override
  String get calcLoad => 'Load';

  @override
  String get calcDayLoad => 'Day load';

  @override
  String get calcNightLoad => 'Night load';

  @override
  String get calcNightHours => 'Night hours';

  @override
  String get calcResults => 'Your system';

  @override
  String get calcPanels => 'Solar panels';

  @override
  String get calcInverter => 'Inverter';

  @override
  String get calcBatteries => 'Batteries';

  @override
  String get calcDailyProduction => 'Daily production';

  @override
  String get calcOnGridHint => 'Solar + grid';

  @override
  String get calcHybridHint => 'Grid + battery';

  @override
  String get calcOffGridHint => 'Battery only';

  @override
  String get calcConnection => 'Your connection';

  @override
  String get calcUnit => 'Unit';

  @override
  String get calcDayLoadHint => 'What runs while the sun is up';

  @override
  String get calcNightLoadHint => 'What runs after sunset';

  @override
  String get calcOnGridLoadHint => 'Your average running load';

  @override
  String calcPanelsCount(int count, int wattage) {
    return '$count panels × $wattage W';
  }
}
