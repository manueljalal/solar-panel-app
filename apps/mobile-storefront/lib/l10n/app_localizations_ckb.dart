// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get locationErbilIraq => 'هەولێر، عێراق';

  @override
  String get searchHint => 'گەڕان بۆ پانێڵ، براند، پاکێج';

  @override
  String get bannerLimitedOffer => 'داهاتووی سنووردار';

  @override
  String get bannerZeroDownTitle => 'بێ پێشەکی\nبۆ سیستەمی ماڵەوە';

  @override
  String get bannerGetQuote => 'نرخنامە وەربگرە';

  @override
  String get bannerNewLabel => 'نوێ';

  @override
  String get bannerBatteryTitle => 'پاتری هەڵگری وزە،\nبۆ کاتی بڕانی کارەبا';

  @override
  String get bannerExploreBatteries => 'پاتریەکان ببینە';

  @override
  String get bannerVettedNetwork => 'تۆڕی دڵنیاکراو';

  @override
  String get bannerVendorsTitle =>
      'هەموو فرۆشیارێک،\nشوێنی کارەکەی پشتڕاستکراوەتەوە';

  @override
  String get bannerMeetVendors => 'فرۆشیارەکان بناسە';

  @override
  String get sectionCompanies => 'کۆمپانیاکان';

  @override
  String get sectionFeatured => 'تایبەت';

  @override
  String get sectionBestSellers => 'زۆرترین فرۆشراو';

  @override
  String get seeAll => 'هەمووی ببینە';

  @override
  String get homeLoadError =>
      'نەتوانرا ناوەڕۆک باربکرێت. پەیوەندییەکەت بپشکنە.';

  @override
  String get retry => 'دووبارە هەوڵبدەرەوە';

  @override
  String get bestMatch => 'باشترین گونجاو';

  @override
  String get wattageCalculatorTitle => 'ژمێرەری وات';

  @override
  String get wattageCalculatorSubtitle =>
      'دوو پرسیار، قەبارەی سیستەم دیاری دەکرێت.';

  @override
  String get tryIt => 'تاقی بکەرەوە';

  @override
  String get applyBannerTitle => 'کارگەی وزەی خۆر\nهەیە؟';

  @override
  String get apply => 'داواکاری بنێرە';

  @override
  String get learnTeaserTitle => 'هەڵبژاردنی واتی گونجاو';

  @override
  String get learnTeaserReadTime => '٤ خولەک خوێندنەوە';

  @override
  String productSold(int count) {
    return '$count فرۆشراوە';
  }

  @override
  String get navHome => 'سەرەکی';

  @override
  String get navLearn => 'فێربوون';

  @override
  String get navCart => 'سەبەتە';

  @override
  String get navOrders => 'داواکارییەکان';

  @override
  String get navAccount => 'هەژمار';

  @override
  String get cancel => 'پاشگەزبوونەوە';

  @override
  String get done => 'تەواو';

  @override
  String get required => 'پێویستە';

  @override
  String get inStock => 'بەردەستە';

  @override
  String get outOfStock => 'بەردەست نییە';

  @override
  String get genericConnectionError =>
      'نەتوانرا بنێردرێت — پەیوەندییەکەت بپشکنە و دووبارە هەوڵ بدەوە.';

  @override
  String minRead(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes خولەک خوێندنەوە',
      one: '١ خولەک خوێندنەوە',
    );
    return '$_temp0';
  }

  @override
  String get accountTitle => 'هەژمار';

  @override
  String get accountNotSignedIn => 'چوونەژوورەوەت نەکردووە';

  @override
  String get accountSignOut => 'چوونەدەرەوە';

  @override
  String get accountSignIn => 'چوونەژوورەوە';

  @override
  String get accountLocation => 'هەولێر، عێراق';

  @override
  String get accountChange => 'گۆڕین';

  @override
  String get accountOrderHistory => 'مێژووی داواکارییەکان';

  @override
  String get accountView => 'بینین';

  @override
  String get accountMyProducts => 'بەرهەمەکانم';

  @override
  String get accountManage => 'بەڕێوەبردن';

  @override
  String get accountOwnBusiness => 'کارگەی وزەی خۆرت هەیە؟';

  @override
  String get accountApply => 'داواکاری بنێرە';

  @override
  String get accountAbout => 'دەربارەی سولاری';

  @override
  String get accountLanguage => 'زمان';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get languageNameSorani => 'کوردی سۆرانی';

  @override
  String get chooseLanguage => 'زمان هەڵبژێرە';

  @override
  String get accountAnonymousUnavailable =>
      'چوونەژوورەوەی نەناسراو بەردەست نییە';

  @override
  String get accountSignedIn => 'چووەژوورەوە';

  @override
  String accountBrowsingAnonymously(String uid) {
    return 'بە نەناسراوی دەگەڕێیت · $uid…';
  }

  @override
  String get accountRoleVendor => 'فرۆشیار';

  @override
  String get accountRoleAdmin => 'بەڕێوەبەر';

  @override
  String get accountRoleGuest => 'میوان';

  @override
  String get phoneOtpInvalidFormat =>
      'ژمارەیەکی تەواو لەگەڵ کۆدی وڵات بنووسە، وەک ‎+9647501234567';

  @override
  String get phoneOtpSendFailedRetry =>
      'نەتوانرا کۆد بنێردرێت — دووبارە هەوڵ بدەوە.';

  @override
  String get phoneOtpSendFailedConnection =>
      'نەتوانرا کۆد بنێردرێت — پەیوەندییەکەت بپشکنە.';

  @override
  String get phoneOtpEnterCode => 'کۆدی ٦ ژمارەیی بنووسە.';

  @override
  String get phoneOtpIncorrectCode => 'کۆدەکە هەڵەیە یان کاتی بەسەرچووە.';

  @override
  String get phoneOtpVerifyFailedRetry =>
      'نەتوانرا پشتڕاست بکرێتەوە — دووبارە هەوڵ بدەوە.';

  @override
  String get phoneOtpTitle => 'ژمارە مۆبایلەکەت پشتڕاست بکەرەوە';

  @override
  String get phoneOtpSendBody =>
      'کۆدێکی ٦ ژمارەیی دەنێردرێت بۆ ژمارە مۆبایلەکەت.';

  @override
  String get phoneOtpPhoneLabel => 'ژمارەی مۆبایل';

  @override
  String phoneOtpEnterCodeBody(String phone) {
    return 'ئەو کۆدەی بۆ $phone نێردراوە بنووسە.';
  }

  @override
  String get phoneOtpCodeLabel => 'کۆدی ٦ ژمارەیی';

  @override
  String get phoneOtpUseDifferentNumber => 'ژمارەیەکی جیاواز بەکاربهێنە';

  @override
  String get phoneOtpVerifyCode => 'کۆد پشتڕاستبکەرەوە';

  @override
  String get phoneOtpSendCode => 'کۆد بنێرە';

  @override
  String get phoneOtpNameLabel => 'ناوت';

  @override
  String get phoneOtpNameValidator => 'ناوت بنووسە';

  @override
  String get phoneOtpNewAccountBody => 'یەکەم جارە لێرەیت — ناویشت پێمان بڵێ.';

  @override
  String phoneOtpResendIn(int seconds) {
    return 'دووبارە ناردنی کۆد لە $seconds چ';
  }

  @override
  String get phoneOtpResendCode => 'دووبارە ناردنی کۆد';

  @override
  String get phoneOtpLocationLabel => 'شوێنەکەت';

  @override
  String get phoneOtpLocationRequired => 'شوێنەکەت لەسەر نەخشە دیاری بکە.';

  @override
  String get signUpTitle => 'هەژمار دروست بکە';

  @override
  String get signInTitle => 'چوونەژوورەوە';

  @override
  String get usernameLabel => 'ناوی بەکارهێنەر';

  @override
  String get usernameValidator =>
      '٣-٢٠ پیت: تەنها پیتی بچووک، ژمارە، و ژێرهێڵ.';

  @override
  String get passwordLabel => 'وشەی نهێنی';

  @override
  String get passwordValidator =>
      'لانیکەم ٨ پیت، لەگەڵ پیتێکی گەورە و پیتێکی بچووک و ژمارەیەک و هێمایەک.';

  @override
  String get confirmPasswordLabel => 'دووپاتکردنەوەی وشەی نهێنی';

  @override
  String get confirmPasswordValidator => 'وشە نهێنییەکان وەک یەک نین.';

  @override
  String get signUpSubmit => 'هەژمار دروست بکە';

  @override
  String get signInSubmit => 'چوونەژوورەوە';

  @override
  String get alreadyHaveAccount => 'هەژمارت هەیە پێشتر؟ بچۆ ژوورەوە';

  @override
  String get needAnAccount => 'هەژمارت پێویستە؟ یەکێک دروست بکە';

  @override
  String get signUpUsernameTaken => 'ئەم ناوی بەکارهێنەرە پێشتر بەکارهاتووە.';

  @override
  String get signUpGenericError =>
      'نەتوانرا هەژمارەکەت دروست بکرێت — دووبارە هەوڵ بدەوە.';

  @override
  String get signInIncorrect => 'ناوی بەکارهێنەر یان وشەی نهێنی هەڵەیە.';

  @override
  String get signInGenericError =>
      'نەتوانرا بچیتە ژوورەوە — دووبارە هەوڵ بدەوە.';

  @override
  String get stepUpTitle => 'پشتڕاستبکەرەوە کە تۆیت';

  @override
  String get stepUpBody =>
      'ئامێرێکی نوێ دۆزرایەوە. کۆدێکی ٦ ژمارەیی دەنێردرێت بۆ ژمارە مۆبایلەی تۆمارکراو لە هەژمارەکەت.';

  @override
  String get stepUpSendCode => 'کۆد بنێرە';

  @override
  String get stepUpVerifyCode => 'پشتڕاستکردنەوە';

  @override
  String get cartTitle => 'سەبەتە';

  @override
  String get cartEmptyTitle => 'سەبەتەکەت بەتاڵە';

  @override
  String get cartEmptyBody =>
      'زۆرترین فرۆشراوەکان لە سەرەکی ببینە و شتێک زیاد بکە.';

  @override
  String cartSubtotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'کۆی گشتی ($count بەرهەم)',
      one: 'کۆی گشتی (١ بەرهەم)',
    );
    return '$_temp0';
  }

  @override
  String get checkoutNotBuiltYet => 'پارەدان هێشتا دروست نەکراوە — بەم زووانە.';

  @override
  String get checkout => 'پارەدان';

  @override
  String get perUnit => '/ یەکە';

  @override
  String get description => 'پێناسە';

  @override
  String get noDescriptionYet => 'هێشتا پێناسە نییە.';

  @override
  String addedToCart(String title) {
    return '$title زیادکرا بۆ سەبەتە.';
  }

  @override
  String get specPower => 'توانا';

  @override
  String get specWarranty => 'گەرەنتی';

  @override
  String get specBrand => 'براند';

  @override
  String get requestQuote => 'داواکردنی نرخنامە';

  @override
  String get addToCart => 'زیادکردن بۆ سەبەتە';

  @override
  String quoteRequested(String title) {
    return 'نرخنامە داواکرا بۆ $title.';
  }

  @override
  String get requestAQuote => 'داواکردنی نرخنامە';

  @override
  String get quoteRequestHint =>
      'بۆ نموونە: بڕی پێویست، کاتی دامەزراندن، ناونیشانی شوێن';

  @override
  String get sendRequest => 'داواکاری بنێرە';

  @override
  String searchNoResults(String query) {
    return 'هیچ ئەنجامێک نەدۆزرایەوە بۆ \"$query\"';
  }

  @override
  String get searchPrompt => 'بگەڕێ بۆ پانێڵ، براند یان فرۆشیار.';

  @override
  String get wattageCalculatorScreenTitle => 'ژمێرەری وات';

  @override
  String get wattageCalculatorIntro =>
      'وەڵامی دوو پرسیار بدەوە و ئێمە قەبارەی سیستەم و ژمارەی پانێڵی پێویستی ماڵەکەت دیاری دەکەین.';

  @override
  String get dailyUsageTitle => 'تێکڕای بەکارهێنانی کارەبای ڕۆژانە';

  @override
  String get dailyUsageSubtitle => 'چەند وزە ماڵەکەت ڕۆژانە بەکاردەهێنێت';

  @override
  String get unitKwh => 'کیلۆوات.کاژێر';

  @override
  String get peakSunlightTitle => 'کاتژمێری لووتکەی تیشکی خۆر';

  @override
  String get peakSunlightSubtitle =>
      'تێکڕای کاتژمێرەکانی ڕووناکی بەهێزی خۆر لەسەر باڵەخانەکەت';

  @override
  String get unitHours => 'کاژێر';

  @override
  String get recommendedSystem => 'سیستەمی پێشنیارکراو';

  @override
  String panelEstimate(int count, int wattage) {
    return '$count پانێڵ · $wattage وات بۆ هەریەکە';
  }

  @override
  String get seeMatchingPanels => 'پانێڵە گونجاوەکان ببینە';

  @override
  String get wattageDisclaimer =>
      'تەنها خەمڵاندنێکە — فرۆشیار قەبارەی وردی دیاری دەکات دوای سەردانی شوێنەکە.';

  @override
  String get ordersTitle => 'داواکارییەکان';

  @override
  String get ordersEmptyTitle => 'هێشتا هیچ داواکارییەک نییە';

  @override
  String get ordersEmptyBody =>
      'داواکارییەکان لێرە دەردەکەون کاتێک پارەدان دروست بکرێت.';

  @override
  String get learnTitle => 'فێربوون';

  @override
  String get learnArticleWattageTitle => 'هەڵبژاردنی واتی گونجاو';

  @override
  String get learnArticleWattageBody =>
      'ماڵێکی ئاسایی ڕۆژانە ١٠-١٥ کیلۆوات کاژێر بەکاردەهێنێت. بەکارهێنانی ڕۆژانەت دابەش بکە بەسەر کاتژمێرەکانی لووتکەی تیشکی خۆر لەسەر باڵەخانەکەت (زۆرجار ٤-٦ کاتژمێر لە عێراق) بۆ خەمڵاندنی قەبارەی سیستەم بە کیلۆوات. ژمێرەری وات لە سەرەکی بەکاربهێنە بۆ خەمڵاندنێکی خێرا — فرۆشیار قەبارەی وردی دیاری دەکات دوای سەردانی شوێنەکە، چونکە گۆشەی باڵەخانە و سێبەر و کارایی پانێڵ هەموو کاریگەرن.';

  @override
  String get learnArticleInstallationTitle => 'چۆن دامەزراندن ئەنجام دەدرێت';

  @override
  String get learnArticleInstallationBody =>
      'دوای ناردنی داواکاریت، فرۆشیار کاتی سەردانی شوێنەکە دیاری دەکات بۆ دڵنیابوون لە شوێنی دامەزراندن و ڕێگای وایەرەکان. دامەزراندن بە ئاسایی ١-٢ ڕۆژ دەخایەنێت بۆ سیستەمی ماڵەوە. تیمەکە مۆڵەتەکان (ئەگەر پێویست بوو) و پەیوەستکردنی عاکس ئەنجام دەدات، و پێش تەواوکردن ئەپی چاودێریت پیشان دەدات.';

  @override
  String get learnArticleFinancingTitle => 'پارەدان و گەرەنتییەکان';

  @override
  String get learnArticleFinancingBody =>
      'زۆربەی پانێڵەکان گەرەنتی ٢٥ ساڵەیان هەیە بۆ بەرهەمهێنانی وزە و گەرەنتییەکی کورتتریش (١٠-١٢ ساڵ) بۆ عەیبەکان. پاتری و عاکسەکان بە ئاسایی گەرەنتی ٥-١٠ ساڵیان هەیە. هەندێک فرۆشیار لە سولاری پارەدانی بێ پێشەکی پێشکەش دەکەن بۆ سیستەمی ماڵەوە — بەدوای لافیتەی \"داهاتووی سنووردار\" بگەڕێ لە سەرەکی.';

  @override
  String get learnArticleMaintenanceTitle => 'چاودێریکردنی سیستەمەکەت';

  @override
  String get learnArticleMaintenanceBody =>
      'پانێڵەکان کەمترین چاودێرییان پێویستە — شوشتنێکی کاتی بۆ لابردنی تۆز بەرهەمهێنان بەردەوام دەکات. دیمەنی دۆخی عاکس یان ئەپی چاودێری بەردەوام بپشکنە؛ ڕووناکی سوور یان زەرد زۆرجار مانای ئەوەیە پەیوەندی بە دامەزرێنەرەکەتەوە بکەیت. زۆربەی فرۆشیارەکان پشکنینێکی ساڵانە پێشکەش دەکەن وەک بەشێک لە پاکێجی دامەزراندن.';

  @override
  String get learnArticleNetMeteringTitle => 'ڕوونکردنەوەی کۆنتەری نێت';

  @override
  String get learnArticleNetMeteringBody =>
      'کۆنتەری نێت ڕێگەت پێدەدات زیادەی وزەی خۆر بنێریتەوە بۆ تۆڕەکە و دواتر بێ هیچ تێچووێکی زیادە وەریبگریتەوە، بەم شێوەیە تۆڕەکە وەک پاتری کاردەکات. بەردەستبوون و مەرجەکان بەپێی دابینکەر جیاوازن — پرسیار لە دامەزرێنەرەکەت بکە ئایا لە ناوچەکەت بەردەستە پێش دیاریکردنی قەبارەی پاتری لە سیستەمەکەتدا.';

  @override
  String get vendorApplyGenericError =>
      'نەتوانرا بنێردرێت — پەیوەندییەکەت بپشکنە و دووبارە هەوڵ بدەوە.';

  @override
  String get vendorApplyTitle => 'کارگەی وزەی خۆرت هەیە؟';

  @override
  String get vendorApplyIntro =>
      'بەرهەمەکانت پیشان بدە و بگەرەوە بۆ کڕیاران لە سەرانسەری عێراق. دەربارەی کارگەکەت پێمان بڵێ — بۆ پشتڕاستکردنەوە و ئامادەکردنت پەیوەندیت پێوە دەکەین.';

  @override
  String get businessNameLabel => 'ناوی کارگە';

  @override
  String get businessNameValidator => 'ناوی کارگەکەت بنووسە';

  @override
  String get cityLabel => 'شار';

  @override
  String get cityValidator => 'شارەکەت بنووسە';

  @override
  String get phoneNumberLabel => 'ژمارەی مۆبایل';

  @override
  String get phoneNumberValidator => 'ژمارەیەکی مۆبایل بنووسە';

  @override
  String get emailLabel => 'ئیمەیل';

  @override
  String get emailValidator => 'ئیمەیلەکەت بنووسە';

  @override
  String get emailInvalidError => 'ئیمەیلێکی دروست بنووسە';

  @override
  String get whatDoYouSellLabel => 'چی دەفرۆشیت؟ (ئارەزوومەندانە)';

  @override
  String get submitApplication => 'ناردنی داواکاری';

  @override
  String get applicationSubmittedTitle => 'داواکاری نێردرا';

  @override
  String get applicationSubmittedBody =>
      'پێداچوونەوەی بۆ دەکەین و بڕیارەکەت بە ئیمەیڵ بۆ دەنێرین. دوای پەسەندکردن، بە ناوی بەکارهێنەر و وشەی نهێنی بچۆ ژوورەوە بۆ پۆرتاڵی فرۆشیار.';

  @override
  String get vendorApplySignInIntro =>
      'بۆ ئەوەی وەک فرۆشیار داواکاری بکەیت پێویستت بە هەژمارێکی سولاری هەیە لەگەڵ ژمارەی مۆبایلی پشتڕاستکراو.';

  @override
  String get vendorApplySignInButton => 'بچۆ ژوورەوە یان هەژمار دروست بکە';

  @override
  String get vendorApplyVerifiedPhoneLabel => 'ژمارەی مۆبایلی پشتڕاستکراو';

  @override
  String get vendorApplyPendingTitle => 'داواکارییەکە لە ژێر پێداچوونەوەدایە';

  @override
  String vendorApplyPendingBody(String business) {
    return 'پێداچوونەوە بۆ $business دەکەین. دوای پەسەندکردن، بە ناوی بەکارهێنەر و وشەی نهێنی بچۆ ژوورەوە بۆ پۆرتاڵی فرۆشیار.';
  }

  @override
  String get vendorApplyApprovedTitle => 'پەسەند کرایت';

  @override
  String get vendorApplyApprovedBody =>
      'هەژماری فرۆشیارەکەت ئامادەیە. تابی هەژمار بکەرەوە بۆ بەڕێوەبردنی بەرهەمەکانت.';

  @override
  String get vendorApplyRejectedNotice =>
      'داواکارییە پێشووەکەت پەسەند نەکرا. دەتوانیت دووبارە داوا بکەیتەوە.';

  @override
  String get addressLabel => 'ناونیشانی وردی شەقام';

  @override
  String get addressValidator => 'ناونیشانی وردی شەقامت بنووسە';

  @override
  String get mapLocationLabel => 'شوێن لەسەر نەخشە';

  @override
  String get setLocationOnMap => 'شوێن لەسەر نەخشە دیاری بکە';

  @override
  String get changeLocation => 'گۆڕین';

  @override
  String get locationNotSet => 'دیارینەکراوە';

  @override
  String get locationRequiredError => 'شوێنی کارگەکەت لەسەر نەخشە دیاری بکە.';

  @override
  String get pickLocationTitle => 'شوێنەکەت دیاری بکە';

  @override
  String get pickLocationHint =>
      'نەخشەکە بجوڵێنە بۆ دیاریکردنی شوێنی نیشانە، یان شوێنی ئێستات بەکاربهێنە.';

  @override
  String get confirmLocation => 'شوێن پشتڕاستبکەرەوە';

  @override
  String get locationPermissionDenied =>
      'مۆڵەتی شوێن ڕەتکرایەوە — لەجیاتی ئەوە نیشانەکە بە دەست بجوڵێنە.';

  @override
  String get locationServiceDisabled =>
      'خزمەتگوزاری شوێن کوژاوەتەوە — لەجیاتی ئەوە نیشانەکە بە دەست بجوڵێنە.';

  @override
  String get locationFetchFailed =>
      'نەتوانرا شوێنەکەت بدۆزرێتەوە — لەجیاتی ئەوە نیشانەکە بە دەست بجوڵێنە.';

  @override
  String get myProductsTitle => 'بەرهەمەکانم';

  @override
  String get addProduct => 'زیادکردنی بەرهەم';

  @override
  String get couldntLoadProducts => 'نەتوانرا بەرهەمەکانت بار بکرێن.';

  @override
  String get noProductsYetTitle => 'هێشتا هیچ بەرهەمێک نییە';

  @override
  String get noProductsYetBody =>
      'کرتە لەسەر \"زیادکردنی بەرهەم\" بکە بۆ زیادکردنی یەکەم بەرهەمت.';

  @override
  String get removeProductTitle => 'ئەم بەرهەمە لابردرێت؟';

  @override
  String get remove => 'لابردن';

  @override
  String get couldntRemoveProduct =>
      'نەتوانرا ئەو بەرهەمە لابردرێت — دووبارە هەوڵ بدەوە.';

  @override
  String couldntSaveWithReason(String reason) {
    return 'نەتوانرا پاشەکەوت بکرێت — $reason';
  }

  @override
  String get errorPermissionDenied => 'تۆ مۆڵەتی ئەنجامدانی ئەمەت نییە.';

  @override
  String get errorCheckValues => 'بەهاکان بپشکنە و دووبارە هەوڵ بدەوە.';

  @override
  String get errorCheckConnection =>
      'پەیوەندییەکەت بپشکنە و دووبارە هەوڵ بدەوە.';

  @override
  String get editProductTitle => 'دەستکاریکردنی بەرهەم';

  @override
  String get addProductTitle => 'زیادکردنی بەرهەم';

  @override
  String get categoryLabel => 'پۆل';

  @override
  String get brandLabel => 'براند';

  @override
  String get productNameLabel => 'ناوی بەرهەم';

  @override
  String get specLabel => 'تایبەتمەندی (بۆ نموونە، ٤٥٠ وات، ٥ کیلۆوات کاژێر)';

  @override
  String get priceLabel => 'نرخ (بە دۆلار)';

  @override
  String get priceValidator => 'نرخێکی دروست بنووسە';

  @override
  String get imageUrlLabel => 'لینکی وێنە';

  @override
  String get warrantyOptionalLabel => 'گەرەنتی (ئارەزوومەندانە)';

  @override
  String get descriptionOptionalLabel => 'پێناسە (ئارەزوومەندانە)';

  @override
  String get saveChanges => 'پاشەکەوتکردنی گۆڕانکارییەکان';

  @override
  String get publishProduct => 'بڵاوکردنەوەی بەرهەم';

  @override
  String get categoryResidential => 'ماڵەوە';

  @override
  String get categoryCommercial => 'بازرگانی';

  @override
  String get categoryBattery => 'پاتری';

  @override
  String get categoryInverter => 'عاکس';
}
