// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get locationErbilIraq => 'أربيل، العراق';

  @override
  String get searchHint => 'ابحث عن الألواح والعلامات التجارية والباقات';

  @override
  String get bannerLimitedOffer => 'عرض محدود';

  @override
  String get bannerZeroDownTitle => 'بدون دفعة أولى\nعلى أنظمة المنازل';

  @override
  String get bannerGetQuote => 'احصل على عرض سعر';

  @override
  String get bannerNewLabel => 'جديد';

  @override
  String get bannerBatteryTitle => 'بطاريات تخزين،\nلمواجهة انقطاع الكهرباء';

  @override
  String get bannerExploreBatteries => 'استكشف البطاريات';

  @override
  String get bannerVettedNetwork => 'شبكة موثوقة';

  @override
  String get bannerVendorsTitle => 'كل بائع،\nتم التحقق من موقعه';

  @override
  String get bannerMeetVendors => 'تعرّف على البائعين';

  @override
  String get sectionCompanies => 'الشركات';

  @override
  String get sectionFeatured => 'مميز';

  @override
  String get sectionBestSellers => 'الأكثر مبيعًا';

  @override
  String get seeAll => 'عرض الكل';

  @override
  String get companyNoProducts => 'لم تضف هذه الشركة أي منتجات بعد.';

  @override
  String get categoryAll => 'الكل';

  @override
  String get sectionCategories => 'الفئات';

  @override
  String get categoryNoProducts => 'لا توجد منتجات في هذه الفئة بعد.';

  @override
  String get learnEmpty => 'لا توجد دروس بعد. عد قريباً.';

  @override
  String get learnVideoError => 'تعذّر تشغيل هذا الفيديو.';

  @override
  String get learnTeaserSubtitle => 'شاهد أدلة فيديو قصيرة';

  @override
  String get homeLoadError => 'تعذّر تحميل المحتوى. تحقق من اتصالك.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get bestMatch => 'الأنسب';

  @override
  String get wattageCalculatorTitle => 'حاسبة الطاقة';

  @override
  String get wattageCalculatorSubtitle => 'سؤالان، ونحدد حجم النظام.';

  @override
  String get tryIt => 'جرّبها';

  @override
  String get applyBannerTitle => 'هل تملك شركة\nطاقة شمسية؟';

  @override
  String get applyBannerSubtitle =>
      'اعرض منتجاتك ووصل إلى عملاء في جميع أنحاء العراق.';

  @override
  String get apply => 'قدّم الآن';

  @override
  String get learnTeaserTitle => 'اختيار القدرة الكهربائية المناسبة';

  @override
  String get learnTeaserReadTime => '٤ دقائق قراءة';

  @override
  String productSold(int count) {
    return 'تم بيع $count';
  }

  @override
  String get navHome => 'الرئيسية';

  @override
  String get navLearn => 'تعلّم';

  @override
  String get navCart => 'السلة';

  @override
  String get navOrders => 'الطلبات';

  @override
  String get navAccount => 'الحساب';

  @override
  String get cancel => 'إلغاء';

  @override
  String get done => 'تم';

  @override
  String get required => 'مطلوب';

  @override
  String get inStock => 'متوفر';

  @override
  String get outOfStock => 'غير متوفر';

  @override
  String get genericConnectionError =>
      'تعذّر الإرسال — تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String minRead(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقيقة قراءة',
      many: '$minutes دقيقة قراءة',
      few: '$minutes دقائق قراءة',
      two: 'دقيقتان قراءة',
      one: 'دقيقة واحدة قراءة',
    );
    return '$_temp0';
  }

  @override
  String get accountTitle => 'الحساب';

  @override
  String get accountNotSignedIn => 'لم يتم تسجيل الدخول';

  @override
  String get accountSignOut => 'تسجيل الخروج';

  @override
  String get accountSignIn => 'تسجيل الدخول';

  @override
  String get accountLocation => 'أربيل، العراق';

  @override
  String get accountChange => 'تغيير';

  @override
  String get accountOrderHistory => 'سجل الطلبات';

  @override
  String get accountView => 'عرض';

  @override
  String get accountMyProducts => 'منتجاتي';

  @override
  String get accountManage => 'إدارة';

  @override
  String get accountOwnBusiness => 'هل تملك شركة طاقة شمسية؟';

  @override
  String get accountApply => 'قدّم الآن';

  @override
  String get accountAbout => 'عن سولاري';

  @override
  String get accountLanguage => 'اللغة';

  @override
  String get languageNameEnglish => 'English';

  @override
  String get languageNameArabic => 'العربية';

  @override
  String get languageNameSorani => 'کوردی سۆرانی';

  @override
  String get chooseLanguage => 'اختر اللغة';

  @override
  String get accountAnonymousUnavailable => 'تسجيل الدخول المجهول غير متاح';

  @override
  String get accountSignedIn => 'تم تسجيل الدخول';

  @override
  String accountBrowsingAnonymously(String uid) {
    return 'تصفح مجهول · $uid…';
  }

  @override
  String get accountRoleVendor => 'بائع';

  @override
  String get accountRoleAdmin => 'مسؤول';

  @override
  String get accountRoleGuest => 'زائر';

  @override
  String get phoneOtpInvalidFormat =>
      'أدخل رقمًا كاملاً مع رمز الدولة، مثل ‎+9647501234567';

  @override
  String get phoneOtpSendFailedRetry => 'تعذّر إرسال الرمز — حاول مرة أخرى.';

  @override
  String get phoneOtpSendFailedConnection =>
      'تعذّر إرسال الرمز — تحقق من اتصالك.';

  @override
  String get phoneOtpEnterCode => 'أدخل الرمز المكوّن من 6 أرقام.';

  @override
  String get phoneOtpIncorrectCode => 'الرمز غير صحيح أو منتهي الصلاحية.';

  @override
  String get phoneOtpVerifyFailedRetry => 'تعذّر التحقق — حاول مرة أخرى.';

  @override
  String get phoneOtpTitle => 'تحقق من رقم هاتفك';

  @override
  String get phoneOtpSendBody =>
      'سنرسل رمزًا مكوّنًا من 6 أرقام إلى رقم هاتفك.';

  @override
  String get phoneOtpPhoneLabel => 'رقم الهاتف';

  @override
  String phoneOtpEnterCodeBody(String phone) {
    return 'أدخل الرمز المُرسل إلى $phone.';
  }

  @override
  String get phoneOtpCodeLabel => 'الرمز المكوّن من 6 أرقام';

  @override
  String get phoneOtpUseDifferentNumber => 'استخدم رقمًا مختلفًا';

  @override
  String get phoneOtpVerifyCode => 'تحقق من الرمز';

  @override
  String get phoneOtpSendCode => 'إرسال الرمز';

  @override
  String get phoneOtpNameLabel => 'اسمك';

  @override
  String get phoneOtpNameValidator => 'أدخل اسمك';

  @override
  String get phoneOtpNewAccountBody => 'أول مرة هنا — أخبرنا باسمك أيضًا.';

  @override
  String phoneOtpResendIn(int seconds) {
    return 'إعادة إرسال الرمز خلال $seconds ث';
  }

  @override
  String get phoneOtpResendCode => 'إعادة إرسال الرمز';

  @override
  String get phoneOtpLocationLabel => 'موقعك';

  @override
  String get phoneOtpLocationRequired => 'حدّد موقعك على الخريطة.';

  @override
  String get signUpTitle => 'إنشاء حساب';

  @override
  String get signInTitle => 'تسجيل الدخول';

  @override
  String get usernameLabel => 'اسم المستخدم';

  @override
  String get usernameValidator =>
      '٣-٢٠ حرفًا: أحرف إنجليزية صغيرة، أرقام، وشرطات سفلية فقط.';

  @override
  String get passwordLabel => 'كلمة المرور';

  @override
  String get passwordValidator =>
      '٨ أحرف على الأقل، وتشمل حرفًا كبيرًا وحرفًا صغيرًا ورقمًا ورمزًا.';

  @override
  String get confirmPasswordLabel => 'تأكيد كلمة المرور';

  @override
  String get confirmPasswordValidator => 'كلمتا المرور غير متطابقتين.';

  @override
  String get signUpSubmit => 'إنشاء حساب';

  @override
  String get signInSubmit => 'تسجيل الدخول';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get needAnAccount => 'تحتاج حسابًا؟ أنشئ واحدًا';

  @override
  String get signUpUsernameTaken => 'اسم المستخدم هذا مستخدم بالفعل.';

  @override
  String get signUpGenericError => 'تعذّر إنشاء حسابك — حاول مرة أخرى.';

  @override
  String get signInIncorrect => 'اسم المستخدم أو كلمة المرور غير صحيحة.';

  @override
  String get signInGenericError => 'تعذّر تسجيل الدخول — حاول مرة أخرى.';

  @override
  String get stepUpTitle => 'تأكيد أنك أنت';

  @override
  String get stepUpBody =>
      'تم اكتشاف جهاز جديد. سنرسل رمزًا مكوّنًا من 6 أرقام إلى رقم الهاتف المسجّل في حسابك.';

  @override
  String get stepUpSendCode => 'إرسال الرمز';

  @override
  String get stepUpVerifyCode => 'تأكيد';

  @override
  String get cartTitle => 'السلة';

  @override
  String get cartEmptyTitle => 'سلتك فارغة';

  @override
  String get cartEmptyBody => 'تصفّح الأكثر مبيعًا في الرئيسية وأضف شيئًا.';

  @override
  String cartSubtotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'المجموع الفرعي ($count عنصر)',
      many: 'المجموع الفرعي ($count عنصرًا)',
      few: 'المجموع الفرعي ($count عناصر)',
      two: 'المجموع الفرعي (عنصران)',
      one: 'المجموع الفرعي (عنصر واحد)',
    );
    return '$_temp0';
  }

  @override
  String get checkout => 'الدفع';

  @override
  String get perUnit => '/ للوحدة';

  @override
  String get description => 'الوصف';

  @override
  String get noDescriptionYet => 'لا يوجد وصف بعد.';

  @override
  String addedToCart(String title) {
    return 'تمت إضافة $title إلى السلة.';
  }

  @override
  String get specPower => 'القدرة';

  @override
  String get specWarranty => 'الضمان';

  @override
  String get specBrand => 'العلامة التجارية';

  @override
  String get requestQuote => 'طلب عرض سعر';

  @override
  String get addToCart => 'أضف إلى السلة';

  @override
  String quoteRequested(String title) {
    return 'تم طلب عرض سعر لـ $title.';
  }

  @override
  String get requestAQuote => 'طلب عرض سعر';

  @override
  String get quoteRequestHint =>
      'مثال: الكمية المطلوبة، الجدول الزمني للتركيب، عنوان الموقع';

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String searchNoResults(String query) {
    return 'لا توجد نتائج لـ \"$query\"';
  }

  @override
  String get searchPrompt =>
      'ابحث عن الألواح أو العلامات التجارية أو البائعين.';

  @override
  String get wattageCalculatorScreenTitle => 'حاسبة الطاقة';

  @override
  String get wattageCalculatorIntro =>
      'أجب عن سؤالين وسنقدّر حجم النظام وعدد الألواح التي يحتاجها منزلك.';

  @override
  String get dailyUsageTitle => 'متوسط استهلاك الكهرباء اليومي';

  @override
  String get dailyUsageSubtitle => 'كمية الطاقة التي يستهلكها منزلك يوميًا';

  @override
  String get unitKwh => 'ك.و.س';

  @override
  String get peakSunlightTitle => 'ساعات ذروة أشعة الشمس';

  @override
  String get peakSunlightSubtitle =>
      'متوسط ساعات ضوء النهار القوي على سطح منزلك';

  @override
  String get unitHours => 'س';

  @override
  String get recommendedSystem => 'النظام الموصى به';

  @override
  String panelEstimate(int count, int wattage) {
    return '$count لوحًا · $wattage واط لكل لوح';
  }

  @override
  String get seeMatchingPanels => 'عرض الألواح المناسبة';

  @override
  String get wattageDisclaimer =>
      'تقدير فقط — سيؤكد البائع الحجم الدقيق بعد زيارة الموقع.';

  @override
  String get ordersTitle => 'الطلبات';

  @override
  String get ordersEmptyTitle => 'لا توجد طلبات بعد';

  @override
  String get ordersEmptyBody => 'ستظهر طلباتك هنا عند إرسالها.';

  @override
  String get learnTitle => 'تعلّم';

  @override
  String get learnArticleWattageTitle => 'اختيار القدرة الكهربائية المناسبة';

  @override
  String get learnArticleWattageBody =>
      'يستهلك المنزل النموذجي 10–15 كيلوواط ساعة يوميًا. اقسم استهلاكك اليومي على عدد ساعات ذروة أشعة الشمس على سطح منزلك (عادة 4–6 ساعات في العراق) لتقدير حجم النظام بالكيلوواط. استخدم حاسبة الطاقة في الرئيسية للحصول على تقدير سريع — سيؤكد البائع الحجم الدقيق بعد زيارة الموقع، لأن زاوية السطح والتظليل وكفاءة الألواح كلها عوامل مؤثرة.';

  @override
  String get learnArticleInstallationTitle => 'كيف يتم التركيب';

  @override
  String get learnArticleInstallationBody =>
      'بعد تقديم طلبك، يحدد البائع موعدًا لزيارة الموقع لتأكيد نقاط التثبيت ومسارات الأسلاك. يستغرق التركيب عادةً يومًا إلى يومين لنظام سكني. يتولى الفريق التصاريح عند الحاجة، ويوصّل العاكس، ويشرح لك تطبيق المراقبة قبل التسليم.';

  @override
  String get learnArticleFinancingTitle => 'التمويل والضمانات';

  @override
  String get learnArticleFinancingBody =>
      'تحمل معظم الألواح ضمانًا لمدة 25 عامًا على إنتاج الطاقة وضمانًا أقصر (10–12 عامًا) يغطي العيوب. عادةً ما تحمل البطاريات والعواكس ضمانات لمدة 5–10 أعوام. يقدّم بعض البائعين على سولاري تمويلًا بدون دفعة أولى على الأنظمة السكنية — ابحث عن لافتة \"عرض محدود\" في الرئيسية.';

  @override
  String get learnArticleMaintenanceTitle => 'صيانة نظامك';

  @override
  String get learnArticleMaintenanceBody =>
      'تحتاج الألواح إلى صيانة بسيطة — غسلة عرضية لإزالة الغبار تحافظ على الإنتاج ثابتًا. تحقق من مؤشر حالة العاكس أو تطبيق المراقبة بشكل دوري؛ عادةً ما يعني الضوء الأحمر أو الكهرماني أنه من الأفضل الاتصال بالمُركِّب. يقدّم معظم البائعين فحصًا سنويًا كجزء من باقة التركيب.';

  @override
  String get learnArticleNetMeteringTitle => 'شرح عداد الصافي';

  @override
  String get learnArticleNetMeteringBody =>
      'يتيح لك عداد الصافي إرسال فائض الطاقة الشمسية إلى الشبكة واستعادته لاحقًا دون تكلفة إضافية، مما يجعل الشبكة تعمل بشكل فعّال كبطارية. تختلف الإتاحة والشروط حسب مزود الخدمة — اسأل المُركِّب عمّا إذا كانت متاحة في منطقتك قبل تحديد حجم البطارية في نظامك.';

  @override
  String get vendorApplyGenericError =>
      'تعذّر الإرسال — تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get vendorApplyTitle => 'هل تملك شركة طاقة شمسية؟';

  @override
  String get vendorApplyIntro =>
      'اعرض منتجاتك وتواصل مع عملاء في جميع أنحاء العراق. أخبرنا عن شركتك — سنتابع للتحقق وإعدادك.';

  @override
  String get businessNameLabel => 'اسم الشركة';

  @override
  String get businessNameValidator => 'أدخل اسم شركتك';

  @override
  String get cityLabel => 'المدينة';

  @override
  String get cityValidator => 'أدخل مدينتك';

  @override
  String get phoneNumberLabel => 'رقم الهاتف';

  @override
  String get phoneNumberValidator => 'أدخل رقم هاتف';

  @override
  String get emailLabel => 'البريد الإلكتروني';

  @override
  String get emailValidator => 'أدخل بريدك الإلكتروني';

  @override
  String get emailInvalidError => 'أدخل بريدًا إلكترونيًا صالحًا';

  @override
  String get whatDoYouSellLabel => 'ماذا تبيع؟ (اختياري)';

  @override
  String get submitApplication => 'إرسال الطلب';

  @override
  String get applicationSubmittedTitle => 'تم إرسال الطلب';

  @override
  String get applicationSubmittedBody =>
      'سنراجع طلبك ونرسل لك القرار عبر البريد الإلكتروني. بعد الموافقة، سجّل الدخول إلى بوابة البائع باسم المستخدم وكلمة المرور.';

  @override
  String get vendorApplySignInIntro =>
      'للتقديم كبائع تحتاج إلى حساب في سولاري مع رقم هاتف موثّق.';

  @override
  String get vendorApplySignInButton => 'تسجيل الدخول أو إنشاء حساب';

  @override
  String get vendorApplyVerifiedPhoneLabel => 'رقم الهاتف الموثّق';

  @override
  String get vendorApplyPendingTitle => 'الطلب قيد المراجعة';

  @override
  String vendorApplyPendingBody(String business) {
    return 'نقوم بمراجعة $business. بعد الموافقة، سجّل الدخول إلى بوابة البائع باسم المستخدم وكلمة المرور.';
  }

  @override
  String get vendorApplyApprovedTitle => 'تمت الموافقة عليك';

  @override
  String get vendorApplyApprovedBody =>
      'حساب البائع جاهز. افتح تبويب الحساب لإدارة منتجاتك.';

  @override
  String get vendorApplyRejectedNotice =>
      'لم تتم الموافقة على طلبك السابق. يمكنك التقديم مرة أخرى.';

  @override
  String get addressLabel => 'العنوان التفصيلي';

  @override
  String get addressValidator => 'أدخل عنوانك التفصيلي';

  @override
  String get mapLocationLabel => 'الموقع على الخريطة';

  @override
  String get setLocationOnMap => 'تحديد الموقع على الخريطة';

  @override
  String get changeLocation => 'تغيير';

  @override
  String get locationNotSet => 'غير محدد';

  @override
  String get companyImageLabel => 'صورة شركتك (الشعار أو الواجهة)';

  @override
  String get companyImageAdd => 'اختر صورة';

  @override
  String get companyImageChange => 'تغيير الصورة';

  @override
  String get companyImageRequiredError => 'أضف صورة لشركتك.';

  @override
  String get locationRequiredError => 'حدّد موقع شركتك على الخريطة.';

  @override
  String get pickLocationTitle => 'حدّد موقعك';

  @override
  String get pickLocationHint =>
      'اسحب الخريطة لتحديد موقع العلامة، أو استخدم موقعك الحالي.';

  @override
  String get confirmLocation => 'تأكيد الموقع';

  @override
  String get locationPermissionDenied =>
      'تم رفض إذن الموقع — اسحب العلامة يدويًا بدلاً من ذلك.';

  @override
  String get locationServiceDisabled =>
      'خدمات الموقع متوقفة — اسحب العلامة يدويًا بدلاً من ذلك.';

  @override
  String get locationFetchFailed =>
      'تعذّر تحديد موقعك — اسحب العلامة يدويًا بدلاً من ذلك.';

  @override
  String get myProductsTitle => 'منتجاتي';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get couldntLoadProducts => 'تعذّر تحميل منتجاتك.';

  @override
  String get noProductsYetTitle => 'لا توجد منتجات بعد';

  @override
  String get noProductsYetBody => 'اضغط على \"إضافة منتج\" لإدراج أول عنصر لك.';

  @override
  String get removeProductTitle => 'إزالة هذا المنتج؟';

  @override
  String get remove => 'إزالة';

  @override
  String get couldntRemoveProduct => 'تعذّرت إزالة هذا المنتج — حاول مرة أخرى.';

  @override
  String couldntSaveWithReason(String reason) {
    return 'تعذّر الحفظ — $reason';
  }

  @override
  String get errorPermissionDenied => 'لا تملك الصلاحية للقيام بذلك.';

  @override
  String get errorCheckValues => 'تحقق من القيم وحاول مرة أخرى.';

  @override
  String get errorCheckConnection => 'تحقق من اتصالك وحاول مرة أخرى.';

  @override
  String get editProductTitle => 'تعديل المنتج';

  @override
  String get addProductTitle => 'إضافة منتج';

  @override
  String get categoryLabel => 'الفئة';

  @override
  String get brandLabel => 'العلامة التجارية';

  @override
  String get productNameLabel => 'اسم المنتج';

  @override
  String get specLabel => 'المواصفات (مثال: 450 واط، 5 كيلوواط ساعة)';

  @override
  String get priceLabel => 'السعر (دولار أمريكي)';

  @override
  String get priceValidator => 'أدخل سعرًا صالحًا';

  @override
  String get imageUrlLabel => 'رابط الصورة';

  @override
  String get warrantyOptionalLabel => 'الضمان (اختياري)';

  @override
  String get descriptionOptionalLabel => 'الوصف (اختياري)';

  @override
  String get saveChanges => 'حفظ التغييرات';

  @override
  String get publishProduct => 'نشر المنتج';

  @override
  String get categoryResidential => 'سكني';

  @override
  String get categoryCommercial => 'تجاري';

  @override
  String get categoryBattery => 'بطارية';

  @override
  String get categoryInverter => 'عاكس';

  @override
  String get homeBulkTitle => 'سوق الأعمال\nB2B';

  @override
  String get homeBulkSubtitle =>
      'تاجر مباشرة مع الشركات الأخرى — أسعار الجملة وطلبات الكميات.';

  @override
  String get homeBulkCta => 'افتح';

  @override
  String get bulkMarketTitle => 'سوق الأعمال B2B';

  @override
  String get bulkTabWholesale => 'الجملة';

  @override
  String get bulkTabRequests => 'الطلبات';

  @override
  String get bulkTabMine => 'منشوراتي';

  @override
  String get bulkPostFab => 'انشر';

  @override
  String get bulkPostListing => 'انشر عرض جملة';

  @override
  String get bulkPostListingHint => 'بِع بالجملة بأسعار حسب الكمية';

  @override
  String get bulkPostRequest => 'انشر طلب شراء بالجملة';

  @override
  String get bulkPostRequestHint => 'أخبر الموردين بما تحتاج شراءه';

  @override
  String get bulkEmptyListings => 'لا توجد عروض جملة بعد.';

  @override
  String get bulkEmptyRequests => 'لا توجد طلبات جملة بعد.';

  @override
  String get bulkEmptyMine => 'لم تنشر أي شيء بعد.';

  @override
  String get bulkLoadError => 'تعذّر تحميل السوق.';

  @override
  String get bulkCountryAll => 'الكل';

  @override
  String get bulkCountryIraq => 'العراق';

  @override
  String get bulkCountryChina => 'الصين';

  @override
  String bulkFromPrice(String price, String unit) {
    return 'ابتداءً من $price / $unit';
  }

  @override
  String bulkMinOrder(String amount) {
    return 'الحد الأدنى $amount';
  }

  @override
  String bulkQuantityNeeded(String amount) {
    return 'مطلوب $amount';
  }

  @override
  String bulkTargetPrice(String amount) {
    return 'السعر المستهدف $amount';
  }

  @override
  String bulkTierRow(String qty, String unit) {
    return '$qty+ $unit';
  }

  @override
  String get bulkPriceTiers => 'شرائح الأسعار';

  @override
  String bulkDeliverTo(String city) {
    return 'التسليم إلى $city';
  }

  @override
  String get bulkContactSupplier => 'تواصل';

  @override
  String get bulkCall => 'اتصال';

  @override
  String get bulkWhatsApp => 'واتساب';

  @override
  String get bulkClosePost => 'إغلاق المنشور';

  @override
  String get bulkClosed => 'مغلق';

  @override
  String get bulkYours => 'لك';

  @override
  String get bulkFormTitleLabel => 'العنوان';

  @override
  String get bulkFormTitleHint => 'مثال: ألواح 450 واط';

  @override
  String get bulkFormDescriptionLabel => 'التفاصيل';

  @override
  String get bulkFormUnitLabel => 'الوحدة';

  @override
  String get bulkFormUnitHint => 'قطعة، لوح، كغ…';

  @override
  String get bulkTierQtyLabel => 'من كمية';

  @override
  String get bulkTierPriceLabel => 'سعر الوحدة (دولار)';

  @override
  String get bulkAddTier => 'إضافة شريحة سعر';

  @override
  String get bulkRemoveTier => 'حذف';

  @override
  String get bulkQuantityLabel => 'الكمية المطلوبة';

  @override
  String get bulkTargetPriceLabel => 'السعر المستهدف للوحدة بالدولار (اختياري)';

  @override
  String get bulkDeliveryCityLabel => 'مدينة التسليم (اختياري)';

  @override
  String get bulkSubmitPost => 'نشر';

  @override
  String get bulkFieldRequired => 'مطلوب';

  @override
  String get bulkInvalidNumber => 'أدخل رقماً صحيحاً';

  @override
  String get bulkPosted => 'تم النشر';

  @override
  String get bulkPostFailed => 'تعذّر النشر. حاول مجدداً.';

  @override
  String get bulkDuplicateTier => 'كل شريحة تحتاج كمية مختلفة.';

  @override
  String get applyCountryLabel => 'بلد الشركة';

  @override
  String get signInIdentifierLabel => 'اسم المستخدم أو البريد الإلكتروني';

  @override
  String get bulkOpenMarket => 'افتح سوق الأعمال B2B';

  @override
  String get bulkSortNewest => 'الأحدث';

  @override
  String get bulkSortPriceLow => 'السعر: من الأقل';

  @override
  String get bulkSortQtyHigh => 'الكمية: من الأعلى';

  @override
  String get bulkNoResults => 'لا توجد نتائج مطابقة.';

  @override
  String get bulkFormCategoryLabel => 'الفئة (اختياري)';

  @override
  String get bulkFormCategoryNone => 'بدون فئة';

  @override
  String get bulkLanguagesHint =>
      'اكتب بأي لغة تريد — يراه المشترون بلغتهم عند توفرها.';

  @override
  String get bulkFormPhotoLabel => 'صورة (اختياري)';

  @override
  String get bulkFormPhotoAdd => 'أضف صورة';

  @override
  String get bulkFormPhotoChange => 'تغيير الصورة';

  @override
  String get bulkTitleNeeded => 'أضف عنواناً بلغة واحدة على الأقل.';

  @override
  String get signUpPhoneTaken =>
      'يوجد حساب بهذا الرقم بالفعل. سجّل الدخول، أو استخدم رقماً آخر.';

  @override
  String get checkoutTitle => 'إتمام الطلب';

  @override
  String get checkoutDeliverTo => 'موقع التوصيل';

  @override
  String get checkoutChooseLocation => 'اختر على الخريطة';

  @override
  String get checkoutAddressLabel => 'تفاصيل العنوان';

  @override
  String get checkoutAddressHint => 'الشارع، المبنى، أقرب معلم';

  @override
  String get checkoutNoteLabel => 'ملاحظة للبائع (اختياري)';

  @override
  String get checkoutPayment => 'الدفع';

  @override
  String get checkoutCod => 'الدفع عند الاستلام';

  @override
  String get checkoutCodHint => 'ادفع للبائع نقداً عند وصول طلبك.';

  @override
  String get checkoutSummary => 'ملخص الطلب';

  @override
  String get checkoutTotal => 'المجموع';

  @override
  String get checkoutPlaceOrder => 'تأكيد الطلب';

  @override
  String get checkoutSellersNote =>
      'المنتجات من عدة بائعين تصبح طلبات منفصلة — كل بائع يؤكد ويوصل طلبه.';

  @override
  String get checkoutSignInTitle => 'سجّل الدخول لإتمام الطلب';

  @override
  String get checkoutSignInBody =>
      'تحتاج الطلبات إلى حساب برقم هاتف موثّق ليتصل بك البائع للتأكيد.';

  @override
  String get checkoutLocationRequired => 'اختر موقع التوصيل على الخريطة.';

  @override
  String get checkoutAddressRequired => 'أدخل تفاصيل عنوانك.';

  @override
  String get checkoutFailed => 'تعذّر إرسال طلبك. حاول مجدداً.';

  @override
  String get orderPlacedTitle => 'تم إرسال الطلب';

  @override
  String get orderPlacedBody =>
      'سيتصل بك البائع للتأكيد. ادفع نقداً عند الاستلام.';

  @override
  String get orderViewOrders => 'عرض طلباتي';

  @override
  String get orderStatusPlaced => 'بانتظار البائع';

  @override
  String get orderStatusConfirmed => 'مؤكد';

  @override
  String get orderStatusOutForDelivery => 'في الطريق';

  @override
  String get orderStatusDelivered => 'تم التوصيل';

  @override
  String get orderStatusCancelled => 'ملغى';

  @override
  String get ordersSignInTitle => 'سجّل الدخول لرؤية طلباتك';

  @override
  String orderItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count منتجات',
      one: 'منتج واحد',
    );
    return '$_temp0';
  }

  @override
  String get orderCancel => 'إلغاء الطلب';

  @override
  String get orderCancelConfirmTitle => 'إلغاء هذا الطلب؟';

  @override
  String get orderCancelConfirmBody =>
      'لم يؤكده البائع بعد، لذا يمكنك الإلغاء.';

  @override
  String get orderKeep => 'الإبقاء على الطلب';

  @override
  String get orderCancelledToast => 'تم إلغاء الطلب.';

  @override
  String get orderActionFailed => 'حدث خطأ. حاول مجدداً.';

  @override
  String get orderDeliverTo => 'التوصيل إلى';

  @override
  String orderFrom(String seller) {
    return 'من $seller';
  }

  @override
  String orderCancelReason(String reason) {
    return 'السبب: $reason';
  }

  @override
  String get quoteSignInBody => 'سجّل الدخول ليتصل بك البائع بالسعر.';

  @override
  String get cityAll => 'كل المدن';

  @override
  String get cityPickerTitle => 'اختر مدينة';

  @override
  String companiesNoneInCity(String city) {
    return 'لا توجد شركات في $city بعد.';
  }

  @override
  String get cityChoose => 'اختر مدينتك';

  @override
  String get navServices => 'الخدمات';

  @override
  String get servicesTitle => 'الخدمات';

  @override
  String get servicesIntro => 'احجز خبير طاقة شمسية إلى منزلك.';

  @override
  String get serviceInstallation => 'التركيب';

  @override
  String get serviceInstallationHint =>
      'زيارة الموقع والتثبيت والتوصيل والإعداد';

  @override
  String get serviceCleaning => 'تنظيف الألواح';

  @override
  String get serviceCleaningHint => 'الغبار يقلل الطاقة — نظّفها';

  @override
  String get serviceCallCenter => 'مركز الاتصال';

  @override
  String get serviceCallCenterHint => 'أسئلة أو مشاكل أو مساعدة في الاختيار';

  @override
  String get serviceCall => 'اتصال';

  @override
  String get serviceWhatsApp => 'واتساب';

  @override
  String get serviceSupportNotSet => 'سيتوفر رقم مركز الاتصال قريباً.';

  @override
  String get serviceMyRequests => 'طلباتي';

  @override
  String get serviceNoRequests => 'لم تحجز أي خدمة بعد.';

  @override
  String get serviceRequestTitleInstallation => 'احجز تركيباً';

  @override
  String get serviceRequestTitleCleaning => 'احجز تنظيف ألواح';

  @override
  String get serviceLocation => 'الموقع';

  @override
  String get servicePreferredDate => 'التاريخ المفضل (اختياري)';

  @override
  String get serviceAnyDate => 'أي يوم';

  @override
  String get servicePanelCount => 'عدد الألواح (اختياري)';

  @override
  String get serviceSystemSize => 'حجم النظام بالكيلوواط (اختياري)';

  @override
  String get serviceNote => 'هل هناك ما يجب أن نعرفه؟ (اختياري)';

  @override
  String get serviceSubmit => 'إرسال الطلب';

  @override
  String get serviceSent => 'تم إرسال الطلب — سنتصل بك لتأكيد الموعد.';

  @override
  String get serviceFailed => 'تعذّر إرسال طلبك. حاول مجدداً.';

  @override
  String get serviceSignInBody => 'سجّل الدخول ليتصل بك فريقنا لترتيب الزيارة.';

  @override
  String get serviceStatusNew => 'بانتظار التأكيد';

  @override
  String get serviceStatusScheduled => 'مجدول';

  @override
  String get serviceStatusCompleted => 'مكتمل';

  @override
  String get serviceStatusCancelled => 'ملغى';

  @override
  String serviceScheduledFor(String date) {
    return 'مجدول في $date';
  }

  @override
  String get serviceCancel => 'إلغاء الطلب';

  @override
  String get accountHelp => 'المساعدة والدعم';

  @override
  String get accountB2B => 'سوق الأعمال B2B';

  @override
  String get accountDelete => 'حذف الحساب';

  @override
  String get accountDeleteTitle => 'حذف حسابك؟';

  @override
  String get accountDeleteBody =>
      'سيؤدي هذا إلى حذف حسابك وملفك نهائياً. تبقى الطلبات السابقة لدى البائعين كسجلات. لا يمكن التراجع عن ذلك.';

  @override
  String get accountDeleteConfirm => 'حذف';

  @override
  String get accountDeleted => 'تم حذف حسابك.';

  @override
  String get accountDeleteFailed => 'تعذّر حذف حسابك. حاول مجدداً.';

  @override
  String get aboutBody =>
      'تربطك سولاري بشركات طاقة شمسية موثوقة في جميع أنحاء العراق — ألواح وبطاريات ومحولات وتركيب وتنظيف.';

  @override
  String get aboutCompany => 'سولاري، أحد منتجات Quadcores';

  @override
  String aboutVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get accountGuestTitle => 'سجّل الدخول إلى سولاري';

  @override
  String get accountGuestBody =>
      'تابع طلباتك واحجز التركيب واحفظ بياناتك في مكان واحد.';

  @override
  String get accountCreateAccount => 'إنشاء حساب';

  @override
  String get accountEditProfile => 'تعديل الملف';

  @override
  String get accountYourName => 'اسمك';

  @override
  String get accountSave => 'حفظ';

  @override
  String get accountSaved => 'تم الحفظ.';

  @override
  String get accountMyOrders => 'طلباتي';

  @override
  String get accountMyServices => 'طلبات الخدمة';

  @override
  String get accountSectionActivity => 'النشاط';

  @override
  String get accountSectionBusiness => 'الأعمال';

  @override
  String get accountSectionPreferences => 'التفضيلات';

  @override
  String get accountSectionSupport => 'المساعدة';

  @override
  String get accountCity => 'المدينة';

  @override
  String get accountNotSet => 'غير محدد';

  @override
  String get learnCourses => 'الدورات';

  @override
  String get learnQuickVideos => 'فيديوهات قصيرة';

  @override
  String learnEpisodes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count حلقات',
      one: 'حلقة واحدة',
    );
    return '$_temp0';
  }

  @override
  String learnMinutes(int count) {
    return '$count دقيقة';
  }

  @override
  String get learnFree => 'مجاني';

  @override
  String get learnPremium => 'مميز';

  @override
  String get learnFreePreview => 'معاينة مجانية';

  @override
  String learnEpisodeN(int number) {
    return 'الحلقة $number';
  }

  @override
  String get learnLockedTitle => 'دورة مميزة';

  @override
  String get learnLockedBody =>
      'الدورات المدفوعة قادمة قريباً. يمكنك مشاهدة الحلقة الأولى مجاناً الآن.';

  @override
  String get learnStartCourse => 'ابدأ الدورة';

  @override
  String get profileTitle => 'تعديل الملف الشخصي';

  @override
  String get profileDetails => 'بياناتك';

  @override
  String get profileEmailOptional => 'البريد الإلكتروني (اختياري)';

  @override
  String get profileEmailHint => 'يُستخدم للإيصالات وتسجيل الدخول';

  @override
  String get profilePhoneVerified => 'هاتف موثّق';

  @override
  String get profilePhoneNote =>
      'هاتفك هو رقم الدخول الموثّق ولا يمكن تغييره هنا.';

  @override
  String get profileSecurity => 'الأمان';

  @override
  String get profileChangePassword => 'تغيير كلمة المرور';

  @override
  String get profileSaved => 'تم حفظ الملف الشخصي.';

  @override
  String get profileSaveFailed => 'تعذّر حفظ ملفك. حاول مجدداً.';

  @override
  String get passwordCurrent => 'كلمة المرور الحالية';

  @override
  String get passwordNew => 'كلمة المرور الجديدة';

  @override
  String get passwordConfirm => 'تأكيد كلمة المرور الجديدة';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get passwordRequired => 'أدخل كلمة المرور الحالية.';

  @override
  String get passwordChanged => 'تم تغيير كلمة المرور.';

  @override
  String get passwordChangeFailed => 'تعذّر تغيير كلمة المرور. حاول مجدداً.';

  @override
  String get profilePersonalInfo => 'المعلومات الشخصية';

  @override
  String get profileLoginSecurity => 'تسجيل الدخول والأمان';

  @override
  String get profileAdd => 'إضافة';

  @override
  String get profileNameHelp => 'هكذا سيخاطبك البائعون وفريقنا.';

  @override
  String get profileUsernameHelp =>
      'يمكنك تسجيل الدخول باسم المستخدم. 3–20 حرفاً صغيراً أو رقماً أو شرطة سفلية.';

  @override
  String get profileEmailHelp =>
      'اختياري. يُستخدم للإيصالات ويمكنك تسجيل الدخول به.';

  @override
  String get profileRemoveEmail => 'إزالة البريد';

  @override
  String get addressTitle => 'عنوان التوصيل';

  @override
  String get addressNone => 'غير محدد';

  @override
  String get addressHelp =>
      'يُستخدم تلقائياً عند الطلب وحجز الخدمات. يمكنك تغييره في كل مرة.';

  @override
  String get addressSaved => 'تم حفظ العنوان.';
}
