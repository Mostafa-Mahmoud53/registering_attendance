// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'نظام تسجيل الحضور بالجامعة';

  @override
  String get appDescription => 'مشروع فلاتر جديد.';

  @override
  String get studentAttendanceApplication => 'تطبيق حضور وغياب الطلاب';

  @override
  String get forAssistanceContactIT =>
      'للمساعدة، يرجى التواصل مع قسم تكنولوجيا المعلومات في جامعتك';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get activate => 'تفعيل الحساب';

  @override
  String get activateAccount => 'تفعيل الحساب';

  @override
  String get enterYourDetails =>
      'أدخل بيانات اعتمادك للوصول إلى نظام الحضور الجامعي';

  @override
  String get enterDetailsToActivate =>
      'أدخل تفاصيلك لتفعيل حساب الحضور الجامعي الخاص بك';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get enterEmail => 'أدخل بريدك الإلكتروني';

  @override
  String get universityEmail => 'البريد الجامعي';

  @override
  String get enterUniversityEmail => 'أدخل البريد الجامعي';

  @override
  String get password => 'كلمة المرور';

  @override
  String get enterPassword => 'أدخل كلمة مرورك';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get enterStrongPassword => 'أدخل كلمة مرور قوية (6 أحرف على الأقل)';

  @override
  String get universityCode => 'الكود الجامعي';

  @override
  String get enterUniversityCode => 'أدخل كودك';

  @override
  String get enterCode => 'أدخل الكود';

  @override
  String get deviceId => 'معرف الجهاز';

  @override
  String get refreshDeviceId => 'تحديث';

  @override
  String get alreadyHaveAccount => 'هل لديك حساب بالفعل؟';

  @override
  String get dontHaveAccount => 'ليس لديك حساب؟';

  @override
  String get emailIsRequired => 'البريد الإلكتروني مطلوب';

  @override
  String get enterValidEmail => 'يرجى إدخال عنوان بريد إلكتروني صحيح';

  @override
  String get passwordIsRequired => 'كلمة المرور مطلوبة';

  @override
  String get codeIsRequired => 'الكود مطلوب';

  @override
  String get loginSuccessful => 'تم تسجيل الدخول بنجاح!';

  @override
  String get activationSuccessful => 'تم تفعيل الحساب بنجاح!';

  @override
  String get loginFailed =>
      'بريد إلكتروني أو كلمة مرور غير صحيحة، أو الحساب لم يتم تفعيله بعد.';

  @override
  String get sessionExpired => 'انتهت جلستك. يرجى تسجيل الدخول مرة أخرى.';

  @override
  String get noInternetConnection =>
      'لا توجد اتصالات بالإنترنت. تحقق من شبكتك.';

  @override
  String get requestTimeout => 'انتهت مهلة الطلب. يرجى المحاولة مرة أخرى.';

  @override
  String get serverError => 'خطأ في الخادم. يرجى المحاولة لاحقاً.';

  @override
  String get somethingWentWrong => 'حدث خطأ ما. يرجى المحاولة مرة أخرى.';

  @override
  String get authenticationRequired => 'المصادقة مطلوبة';

  @override
  String get accountNotFound => 'الحساب غير موجود. تحقق من رمزك الجامعي.';

  @override
  String get tooManyAttempts =>
      'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get collegeAttendanceSystem => 'نظام تسجيل الحضور بالجامعة';

  @override
  String get studentDashboard => 'لوحة الطالب';

  @override
  String get adminDashboard => 'لوحة تحكم الإدارة';

  @override
  String get doctorDashboard => 'لوحة تحكم عضو هيئة التدريس';

  @override
  String get dashboardMenu => 'قائمة لوحة التحكم';

  @override
  String get welcome => 'أهلا وسهلا';

  @override
  String get loadingStatistics => 'جاري تحميل الإحصائيات...';

  @override
  String get updatesAutomatically => 'يتم التحديث تلقائياً كل 30 ثانية';

  @override
  String get myCourses => 'مقرراتي';

  @override
  String get coursesList => 'قائمة المقررات';

  @override
  String get noAccessPermission => 'لا توجد أذونات وصول';

  @override
  String get connectionError => 'خطأ في الاتصال';

  @override
  String get noDataAvailable => 'لا توجد بيانات متاحة';

  @override
  String get authenticationFailed => 'فشلت المصادقة';

  @override
  String get retry => 'إعادة محاولة';

  @override
  String get doctors => 'أعضاء هيئة تدريس';

  @override
  String get tas => 'معيدون';

  @override
  String get students => 'الطلاب';

  @override
  String get courses => 'المقررات';

  @override
  String get totalCourses => 'إجمالي المقررات';

  @override
  String get totalStudents => 'إجمالي الطلاب';

  @override
  String get searchCourses => 'البحث في المقررات...';

  @override
  String get noCoursesAssigned => 'لم يتم تعيين مقررات بعد';

  @override
  String get noCoursesMatch => 'لا توجد مقررات تطابق بحثك';

  @override
  String get staffManagement => 'إدارة الموظفين';

  @override
  String get createDoctorTA => 'إضافة عضو هيئة تدريس/معيد';

  @override
  String get createDoctor => 'إضافة عضو هيئة تدريس';

  @override
  String get createTA => 'إنشاء معيد';

  @override
  String get listDoctors => 'عرض أعضاء هيئة التدريس';

  @override
  String get listTAs => 'قائمة المعيدين';

  @override
  String get deleteUser => 'حذف مستخدم';

  @override
  String get createDoctorAccount => 'إنشاء حساب عضو هيئة تدريس';

  @override
  String get createTAAccount => 'إنشاء حساب معيد';

  @override
  String get createNewAccount => 'إنشاء حساب جديد';

  @override
  String get fillDetailsToCreate => 'ملء التفاصيل لإنشاء حساب جديد';

  @override
  String get accountCreationSteps => 'خطوات إنشاء الحساب';

  @override
  String get selectAccountType => 'حدد نوع الحساب (عضو هيئة تدريس أو معيد).';

  @override
  String get enterFullName => 'أدخل الاسم الكامل لموظف الكادر.';

  @override
  String get provideValidEmail => 'قدم عنوان بريد إلكتروني صحيح.';

  @override
  String get setSecurePassword =>
      'قم بتعيين كلمة مرور آمنة (6 أحرف على الأقل).';

  @override
  String get clickCreateButton => 'انقر على زر الإنشاء لإنهاء العملية.';

  @override
  String get accountType => 'نوع الحساب';

  @override
  String get doctor => 'عضو هيئة تدريس';

  @override
  String get teachingAssistant => 'معيد';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get enterDoctorName => 'أدخل اسم عضو هيئة التدريس';

  @override
  String get enterTAName => 'أدخل اسم المعيد';

  @override
  String get emailAddress => 'عنوان البريد الإلكتروني';

  @override
  String get create => 'إنشاء';

  @override
  String get createAccount => 'إنشاء حساب';

  @override
  String get doctorAccountCreatedSuccessfully =>
      'تم إنشاء حساب عضو هيئة التدريس بنجاح';

  @override
  String get taAccountCreatedSuccessfully => 'تم إنشاء حساب المعيد بنجاح';

  @override
  String get exit => 'خروج';

  @override
  String get authenticationTokenNotFound => 'لم يتم العثور على رمز المصادقة';

  @override
  String get studentManagement => 'إدارة الطلاب';

  @override
  String get bulkCreateStudents => 'إنشاء طلاب دفعة واحدة';

  @override
  String get createMultipleStudents => 'إنشاء عدة طلاب';

  @override
  String get addStudentsOneByOne =>
      'إضافة الطلاب واحداً تلو الآخر أو بكميات كبيرة';

  @override
  String get bulkDeleteStudents => 'حذف الطلاب دفعة واحدة';

  @override
  String get resetAccounts => 'إعادة تعيين الحسابات';

  @override
  String get resetAccountsPage => 'إعادة تعيين حسابات الطلاب';

  @override
  String get resetStudentsNewYear => 'إعادة تعيين الطلاب للسنة الجديدة';

  @override
  String get importFromExcel => 'استيراد من إكسل';

  @override
  String get uploadExcel => 'رفع ملف إكسل';

  @override
  String get importExcel =>
      'قم بتحميل ملف إكسل يحتوي على عمود باسم \"كود الجامعة\" أو \"الكود\"';

  @override
  String get uploading => 'جاري التحميل...';

  @override
  String get importing => 'جاري الاستيراد...';

  @override
  String get clearAll => 'حذف الكل';

  @override
  String get clear => 'مسح';

  @override
  String get addStudent => 'إضافة طالب';

  @override
  String get addStudentManually => 'إضافة طالب';

  @override
  String get studentName => 'اسم الطالب';

  @override
  String get enterStudentName => 'أدخل الاسم الكامل للطالب';

  @override
  String get studentCode => 'كود الطالب';

  @override
  String get studentsToAdd => 'الطلاب المراد إضافتهم';

  @override
  String get ready => 'جاهز';

  @override
  String get studentAdded => 'تم إضافة الطالب إلى القائمة';

  @override
  String get pleaseAddAtLeastOne => 'يرجى إضافة طالب واحد على الأقل';

  @override
  String get pleaseFixErrors => 'يرجى إصلاح جميع الأخطاء قبل الإضافة';

  @override
  String get createStudents => 'إنشاء طلاب';

  @override
  String get studentsCreatedSuccessfully => 'تم إنشاء الطلاب بنجاح!';

  @override
  String importedStudents(int count, int skipped) {
    return 'تم استيراد $count طلاب، تم تخطي $skipped صفوف.';
  }

  @override
  String importFailed(String error) {
    return 'فشل الاستيراد: $error';
  }

  @override
  String errorCreatingStudents(String error) {
    return 'خطأ في إنشاء الطلاب: $error';
  }

  @override
  String get confirmDeletion => 'تأكيد الحذف';

  @override
  String areYouSurDeleteUser(String code) {
    return 'هل أنت متأكد من رغبتك في حذف المستخدم برمز: $code؟';
  }

  @override
  String get dangerZone => '⚠️ منطقة الخطر';

  @override
  String get thisActionCannotBeUndone =>
      'سيؤدي هذا الإجراء إلى حذف المستخدم وجميع بياناته بشكل دائم. لا يمكن التراجع عن هذا.';

  @override
  String get howToDeleteUser => 'كيفية حذف مستخدم';

  @override
  String get howToFindUniversityCode => 'كيفية العثور على الكود الجامعي';

  @override
  String get userCodeFormat =>
      'صيغة الكود: \"TA-XXXX\" للمعيدين، \"DR-XXXX\" للأطباء';

  @override
  String get makesurecorrectcode => 'تأكد من أن لديك الكود الصحيح قبل الحذف';

  @override
  String get deletedUsersCannotRecover =>
      'لا يمكن استرجاع المستخدمين المحذوفين';

  @override
  String get deleteBothDoctorsAndTAs => 'هذا يحذف كل من الأطباء والمعيدين';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get deleteUserSuccessfully => 'تم حذف المستخدم بنجاح!';

  @override
  String get courseManagement => 'إدارة المقررات';

  @override
  String get createCourse => 'إنشاء مقرر';

  @override
  String get assignStaff => 'تعيين الموظفين';

  @override
  String get assignStaffToCourse => 'تعيين الموظفين للمقرر';

  @override
  String get assignDoctorOrTA => 'تعيين عضو هيئة تدريس أو معيد';

  @override
  String get courseCode => 'كود المقرر';

  @override
  String get enterCourseCode => 'مثال: CS101';

  @override
  String get courseId => 'معرف المقرر';

  @override
  String get enterCourseIdNumber => 'أدخل رقم معرف المقرر';

  @override
  String get staffUniversityCode => 'كود الموظف الجامعي';

  @override
  String get enterStaffUniversityCode => 'مثال: DR-XXXX أو TA-XXXX';

  @override
  String get courseName => 'اسم المقرر';

  @override
  String get enterCourseName => 'أدخل اسم المقرر';

  @override
  String get courseDescription => 'وصف المقرر';

  @override
  String get enterCourseDescription => 'أدخل وصف المقرر';

  @override
  String get staffAssignedSuccessfully => 'تم تعيين الموظف بنجاح!';

  @override
  String get courseCreatedSuccessfully => 'تم إنشاء المقرر بنجاح!';

  @override
  String get courseDeletedSuccessfully => 'تم حذف المقرر بنجاح!';

  @override
  String get courseEnrollmentPage => 'تسجيل المقرر';

  @override
  String get enrollStudent => 'تسجيل طالب';

  @override
  String get enrollStudentManually => 'تسجيل طالب واحد يدوياً';

  @override
  String get bulkEnrollPage => 'تسجيل جماعي';

  @override
  String get bulkEnrollStudents => 'استيراد من إكسل أو رموز متعددة';

  @override
  String get studentUniversityCode => 'كود الطالب الجامعي';

  @override
  String get enrollmentErrorAlreadyEnrolled =>
      'الطالب مسجل بالفعل في هذا المقرر.';

  @override
  String get enrollmentErrorPermission => 'ليس لديك إذن للقيام بهذا.';

  @override
  String get enrollmentErrorNotFound => 'المقرر غير موجود.';

  @override
  String get enrollmentErrorTooMany =>
      'محاولات كثيرة جداً. يرجى الانتظار قليلاً ثم المحاولة مرة أخرى.';

  @override
  String get enrollmentErrorInvalidRequest =>
      'طلب غير صحيح. يرجى التحقق من مدخلاتك ومحاولة مرة أخرى.';

  @override
  String get studentEnrolledSuccessfully => 'تم تسجيل الطالب بنجاح!';

  @override
  String get enrollStudents => 'تسجيل الطلاب';

  @override
  String get bulkEnrollHowTo => 'كيفية التسجيل الجماعي';

  @override
  String get bulkEnrollOption1 =>
      'الخيار 1: استخدم \"الاستيراد من إكسل\" لتحميل ملف .xlsx بعمود \"كود الجامعة\".';

  @override
  String get bulkEnrollOption2 =>
      'الخيار 2: أدخل رموز الجامعة يدويًا واحدًا تلو الآخر في قسم \"الإضافة اليدوية\".';

  @override
  String get bulkEnrollOption3 => 'راجع قائمة الطلاب المترجمة أدناه.';

  @override
  String get bulkEnrollOption4 => 'أدخل معرف المقرر في الحقل العلوي.';

  @override
  String get bulkEnrollOption5 => 'انقر فوق \"تسجيل الطلاب\" لإنهاء التسجيل.';

  @override
  String get bulkEnrollOption6 =>
      'ستظهر تقرير يوضح الطلاب المضافين والمتخطيين أو غير الموجودين.';

  @override
  String get courseEnrollmentHowTo => 'كيفية تسجيل طالب';

  @override
  String get courseEnrollmentStep1 =>
      'ابحث عن رقم معرف المقرر الداخلي للمقرر المستهدف.';

  @override
  String get courseEnrollmentStep2 => 'احصل على رمز الجامعة الدقيق للطالب.';

  @override
  String get courseEnrollmentStep3 => 'أدخل التفاصيل في الحقول أدناه.';

  @override
  String get courseEnrollmentStep4 =>
      'انقر فوق \"تسجيل الطالب\" لإنهاء التسجيل.';

  @override
  String get pleaseBothCodes => 'يرجى إدخال كلا الكودين.';

  @override
  String get pleaseFixErrorsForm => 'يرجى إصلاح الأخطاء في النموذج';

  @override
  String get sessionManagement => 'إدارة الجلسات';

  @override
  String get startNewSession => 'بدء جلسة جديدة';

  @override
  String get createSession => 'إنشاء جلسة';

  @override
  String get createSessionSubtitle => 'إنشاء جلسة محاضرة أو قسم مع GPS';

  @override
  String get stopActiveSession => 'إيقاف الجلسة النشطة';

  @override
  String get stopActiveSessionSubtitle =>
      'إيقاف الجلسة النشطة يدويًا بواسطة المعرف';

  @override
  String get viewAllSessions => 'عرض جميع الجلسات';

  @override
  String get viewAllSessionsSubtitle =>
      'سجل المحاضرات والأقسام · انقر لرؤية الحاضرين';

  @override
  String get sessionTitle => 'عنوان الجلسة';

  @override
  String get enterSessionTitle => 'مثال: الفصل 4: هياكل البيانات';

  @override
  String get sessionType => 'نوع الجلسة';

  @override
  String get lecture => 'محاضرة';

  @override
  String get section => 'سكشن';

  @override
  String get allowedRadius => 'نطاق مسموح (متر)';

  @override
  String get enterAllowedRadius => 'مثال: 50';

  @override
  String get startSession => 'بدء الجلسة';

  @override
  String get sessionStarted => 'تم بدء الجلسة بنجاح!';

  @override
  String get sessionStopped => 'تم إيقاف الجلسة بنجاح!';

  @override
  String get sessionResumed => 'تم استئناف الجلسة بنجاح!';

  @override
  String get sessionAlreadyRunning =>
      'توجد جلسة قيد التشغيل بالفعل. هل تريد الاستمرار معها؟';

  @override
  String get continueAction => 'متابعة';

  @override
  String get pleaseEnterSessionId => 'يرجى إدخال معرف الجلسة';

  @override
  String get invalidSessionIdFormat => 'صيغة معرف الجلسة غير صحيحة';

  @override
  String get stopSession => 'إيقاف الجلسة';

  @override
  String get enterSessionIdStop => 'أدخل معرف الجلسة الذي تريد إيقافه:';

  @override
  String get enterSessionId => 'معرف الجلسة';

  @override
  String get sessionCreationSteps => 'خطوات إنشاء الجلسة';

  @override
  String get courseInformation => 'معلومات المقرر';

  @override
  String get course => 'المقرر';

  @override
  String get attendance => 'الحضور';

  @override
  String get registerAttendance => 'تسجيل الحضور';

  @override
  String get scanQRCode => 'مسح رمز QR';

  @override
  String get enterPINCode => 'إدخال رمز PIN';

  @override
  String get activeSessionOpen => '!توجد جلسة نشطة الآن';

  @override
  String get liveSession => 'جلسة مباشرة';

  @override
  String get liveAttendance => 'الحضور المباشر';

  @override
  String get attendeesCount => 'عدد الحاضرين المباشر';

  @override
  String get scanQRCodeStudentApp => 'امسح باستخدام تطبيق الطالب';

  @override
  String get orEnterPin => 'أو أدخل رمز PIN';

  @override
  String get manualEntry => 'إدخال يدوي لرمز PIN';

  @override
  String pinAutoChangeSeconds(int seconds) {
    return 'يتغير رمز PIN و QR تلقائياً كل $seconds ثانية';
  }

  @override
  String get fullScreen => 'ملء الشاشة';

  @override
  String get attendanceSubmitted => 'تم تقديم الحضور!';

  @override
  String get manualAttendance => 'الحضور اليدوي';

  @override
  String get enterStudentCodeManual =>
      'أدخل كود الجامعة للطالب لتسجيل الحضور يدويًا:';

  @override
  String get addStudentManual => 'إضافة طالب';

  @override
  String get locationPermissionsDenied => 'تم رفض أذونات الموقع';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'تم رفض أذونات الموقع بشكل دائم';

  @override
  String get networkError => 'خطأ في الشبكة';

  @override
  String get attendanceDeletedSuccessfully => 'تم حذف الحضور بنجاح';

  @override
  String get studentAddedSuccessfully => 'تم إضافة الطالب بنجاح';

  @override
  String get attendanceIsClosed => 'انتهى الحضور';

  @override
  String get reports => 'التقارير';

  @override
  String get lectureReport => 'تقرير المحاضرة';

  @override
  String get lectureReportSubtitle => 'رؤى الحضور';

  @override
  String get sectionReport => 'تقرير السكشن';

  @override
  String get sectionReportSubtitle => 'المختبرات والتمارين';

  @override
  String get sessionHistory => 'سجل الجلسات';

  @override
  String get sessionHistorySubtitle => 'الجلسات السابقة';

  @override
  String get absenceWarnings => 'تحذيرات الغياب';

  @override
  String get absenceWarningsSubtitle => 'الطلاب المعرضون للخطر';

  @override
  String get enrolledStudents => 'الطلاب المسجلون';

  @override
  String get totalMarks => 'إجمالي الدرجات (اختياري)';

  @override
  String get apply => 'تطبيق';

  @override
  String get code => 'الكود';

  @override
  String get attended => 'حاضر';

  @override
  String get absent => 'غائب';

  @override
  String totalLectures(int count) {
    return 'إجمالي المحاضرات: $count';
  }

  @override
  String marks(String marks) {
    return 'الدرجات: $marks';
  }

  @override
  String totalSections(int count) {
    return 'إجمالي الأقسام: $count';
  }

  @override
  String get exportToExcel => 'تصدير إلى إكسل';

  @override
  String exportFailed(String error) {
    return 'فشل التصدير: $error';
  }

  @override
  String get searchByNameCode => 'ابحث بالاسم أو الكود الجامعي...';

  @override
  String get searchByNameOrCode => 'ابحث بالاسم أو الكود...';

  @override
  String studentEnrolled(int count) {
    return '$count طالب(ة) مسجل(ة)';
  }

  @override
  String get absenceWarningsPageTitle => 'تحذيرات الغياب';

  @override
  String get attendanceReports => 'تقارير الحضور';

  @override
  String get attendanceReportsSubtitle => 'اعرض ملخص حضورك';

  @override
  String get dangerYouExceededAbsenceLimit =>
      'خطر: لقد تجاوزت حد الغياب المسموح (3) وقد يتم منعك من الامتحانات.';

  @override
  String get noStudentsAttendedYet => 'لم يحضر أي طلاب حتى الآن';

  @override
  String get noSessionsFound => 'لم يتم العثور على أي جلسات.';

  @override
  String get noStudentsFound => 'لم يتم العثور على طلاب';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get refresh => 'تحديث';

  @override
  String get submit => 'إرسال';

  @override
  String get search => 'بحث';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get next => 'التالي';

  @override
  String get previous => 'السابق';

  @override
  String get back => 'رجوع';

  @override
  String get close => 'إغلاق';

  @override
  String get ok => 'موافق';

  @override
  String get done => 'تم';

  @override
  String get save => 'حفظ';

  @override
  String get update => 'تحديث';

  @override
  String get updateRadius => 'تحديث النطاق';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get areYouSureLogout =>
      'هل أنت متأكد من رغبتك في تسجيل الخروج من حسابك؟';

  @override
  String errorStopping(String error) {
    return 'خطأ في إيقاف الجلسة: $error';
  }

  @override
  String get changeAllowedScanDistance =>
      'تغيير مسافة المسح المسموحة للطلاب (بالأمتار).';

  @override
  String meters(int count) {
    return '$count متر';
  }

  @override
  String get radiusUpdatedSuccessfully => 'تم تحديث النطاق بنجاح!';

  @override
  String get permissionDenied => 'ليس لديك إذن للقيام بهذا.';

  @override
  String get invalidRequestCheckInput =>
      'طلب غير صحيح. يرجى التحقق من مدخلاتك ومحاولة مرة أخرى.';

  @override
  String get noPermissionDoThis => 'ليس لديك إذن للقيام بهذا.';

  @override
  String get alreadyClosed => 'الجلسة مغلقة بالفعل.';

  @override
  String get alreadyActive => 'هذه الجلسة نشطة بالفعل.';

  @override
  String get conflictingSession =>
      'توجد جلسة متضاربة موجودة بالفعل لهذا المقرر.';

  @override
  String get language => 'اللغة';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get doctorsList => 'قائمة الأطباء';

  @override
  String get teachingAssistantsList => 'قائمة المعيدين';

  @override
  String doctorsCount(String count) {
    return '$count أطباء';
  }

  @override
  String taCount(String count) {
    return '$count معيدين';
  }

  @override
  String get autoRefresh30 => 'تحديث تلقائي كل 30 ثانية';

  @override
  String get searchDoctors => '...ابحث عن الأطباء';

  @override
  String get searchTAs => '...ابحث عن المعيدين';

  @override
  String get passwordReqs => ':متطلبات كلمة المرور';

  @override
  String get atLeast6Chars => '6 أحرف على الأقل';

  @override
  String get howToDeleteStudents => 'كيفية حذف الطلاب';

  @override
  String get deleteOption1 =>
      'الخيار 1: استخدم \"استيراد من إكسل\" لرفع ملف .xlsx يحتوي على عمود \"كود الجامعة\"';

  @override
  String get deleteOption2 =>
      'الخيار 2: أدخل أكواد الجامعة يدوياً واحداً تلو الآخر في قسم \"إضافة يدوياً\"';

  @override
  String get deleteOption3 => 'راجع القائمة المجمعة للطلاب أدناه.';

  @override
  String get deleteOption4 =>
      'انقر على \"حذف الطلاب\" لإزالتهم نهائياً من النظام';

  @override
  String get deleteOption5 => 'تحذير: لا يمكن التراجع عن هذا الإجراء';

  @override
  String get uploadExcelHint =>
      'قم برفع ملف إكسل يحتوي على عمود باسم \"university code\" أو \"code\"';

  @override
  String get clearBtn => 'مسح';

  @override
  String get addManually => 'إضافة يدوياً';

  @override
  String get enterCodeAndPressAdd => 'أدخل كود الجامعة واضغط إضافة';

  @override
  String get addBtn => 'إضافة';

  @override
  String get addStudentsBulkSubtitle =>
      'أضف الطلاب واحداً تلو الآخر أو دفعة واحدة';

  @override
  String get howToCreateStudents => 'كيفية إنشاء الطلاب';

  @override
  String get createOption1 =>
      'الخيار 1: استخدم \"استيراد من إكسل\" لرفع ملف .xlsx يحتوي على أعمدة \"Name\"، \"University Email\"، و \"University Code\"';

  @override
  String get createOption2 =>
      'الخيار 2: استخدم نموذج \"إضافة طالب\" اليدوي لإضافة الطلاب للقائمة أدناه';

  @override
  String get createOption3 =>
      'راجع قائمة \"الطلاب المراد إضافتهم\" أدناه لضمان الدقة';

  @override
  String get createOption4 =>
      'انقر على \"إنشاء الطلاب\" للإنهاء والإرسال للخادم';

  @override
  String get uploadExcelCreateHint =>
      'قم برفع ملف إكسل بأعمدة: name, universityEmail, universityCode';

  @override
  String get addStudentBtn => 'إضافة طالب';

  @override
  String get scanQrCode => 'مسح رمز QR';

  @override
  String get enterPinCode => 'إدخال كود PIN';

  @override
  String get totalStats => 'الإجمالي';

  @override
  String get absentStats => 'غياب';

  @override
  String get attendedStats => 'حضور';

  @override
  String get dangerAbsenceLimit =>
      'خطر: لقد تجاوزت الحد المسموح للغياب (3) وقد تُحرم من الامتحانات';

  @override
  String get sectionsTab => 'سكاشن';

  @override
  String get lecturesTab => 'محاضرات';

  @override
  String get activeSession => 'الجلسة النشطة';

  @override
  String get enterPinDescription =>
      'يرجى إدخال رمز الـ PIN المكون من 4 أرقام المقدم من الدكتور لتسجيل حضورك';

  @override
  String get enterPinTitle => 'إدخال رمز PIN';

  @override
  String get pinCodeLabel => 'رمز PIN';

  @override
  String get submitPinBtn => 'إرسال رمز PIN';

  @override
  String get reassignDoctor => 'نقل الكورس لدكتور آخر';

  @override
  String get reassignDoctorSubtitle => 'نقل المقرر إلى دكتور آخر';

  @override
  String get newDoctorCode => 'كود الدكتور الجديد';

  @override
  String get enterNewDoctorCode => 'مثال: DOC-XXXX';

  @override
  String get confirm => 'تأكيد';

  @override
  String get reassignSuccess => 'تم نقل المقرر للدكتور بنجاح!';

  @override
  String reassignError(String error) {
    return 'فشل نقل الدكتور: $error';
  }

  @override
  String get pleaseEnterDoctorCode => 'يرجى إدخال الكود الجامعي للدكتور الجديد';

  @override
  String get viewDashboard => 'عرض لوحة التحكم';

  @override
  String get viewDashboardSubtitle => 'التحليلات وإدارة الجلسات';

  @override
  String get courseCreationSteps => 'خطوات إنشاء المقرر';

  @override
  String get courseCreationStep1 => 'أدخل اسمًا واضحًا ووصفيًا للمقرر.';

  @override
  String get courseCreationStep2 => 'وفر كود مقرر فريدًا (مثال: CS4710).';

  @override
  String get courseCreationStep3 =>
      'أدخل كود الجامعة الصحيح للعضو المسؤول عن هذا المقرر.';

  @override
  String get courseCreationStep4 => 'أضف وصفًا مختصرًا لمحتوى المقرر.';

  @override
  String get courseCreationStep5 => 'اضغط \"إنشاء مقرر\" لإتمام العملية.';

  @override
  String get doctorUniversityCode => 'كود الأستاذ الجامعي';

  @override
  String get enterDoctorUniversityCode =>
      'أدخل كود الأستاذ الجامعي (مثال: DR-1234)';

  @override
  String get courseNameIsRequired => 'اسم المقرر مطلوب';

  @override
  String get courseNameMustBeAtLeast2Chars =>
      'اسم المقرر يجب أن يكون على الأقل حرفين';

  @override
  String get courseCodeIsRequired => 'كود المقرر مطلوب';

  @override
  String get courseCodeMustBeAtLeast2Chars =>
      'كود المقرر يجب أن يكون على الأقل حرفين';

  @override
  String get courseDescriptionIsRequired => 'الوصف مطلوب';

  @override
  String get courseDescriptionMustBeAtLeast5Chars =>
      'الوصف يجب أن يكون على الأقل 5 أحرف';

  @override
  String get doctorUniversityCodeIsRequired => 'كود الأستاذ الجامعي مطلوب';

  @override
  String get doctorUniversityCodeMustBeValid =>
      'يرجى إدخال كود جامعي صحيح (مثال: DR-1234)';

  @override
  String get deleteSession => 'حذف الجلسة';

  @override
  String get deleteSessionWarning =>
      'هل أنت متأكد من حذف هذه الجلسة بالكامل؟ لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get sessionDeletedSuccessfully => 'تم حذف الجلسة بنجاح!';

  @override
  String deleteSessionError(String error) {
    return 'فشل حذف الجلسة: $error';
  }

  @override
  String get resetSystemTitle => 'تهيئة النظام للعام الجديد';

  @override
  String get resetSystemSubtitle => 'تحضير النظام للعام الدراسي الجديد';

  @override
  String get fullSystemReset => 'إعادة تهيئة النظام بالكامل';

  @override
  String get resetSystemDescription =>
      'يقوم بتهيئة النظام بالكامل للعام الدراسي الجديد. سيتم حذف جميع سجلات الحضور وبيانات الجلسات مع الحفاظ على حسابات المستخدمين والمقررات.';

  @override
  String get resetSystemWarning =>
      '⚠️ تحذير خطير: سيتم حذف جميع سجلات الحضور وتاريخ الجلسات وبيانات التسجيل للعام الدراسي السابق بشكل نهائي. سيتم الحفاظ على حسابات المستخدمين والمقررات. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get proceedReset => 'تأكيد التهيئة';

  @override
  String get resetEntireSystem => 'تهيئة النظام بالكامل';

  @override
  String get resetSystemSuccess => 'تمت تهيئة النظام للعام الجديد بنجاح!';

  @override
  String resetSystemError(String error) {
    return 'فشل تهيئة النظام: $error';
  }

  @override
  String get dataPreserved => 'حسابات المستخدمين والمقررات → محفوظة';

  @override
  String get dataDeleted => 'الجلسات والحضور والتسجيلات → محذوفة';

  @override
  String get singleAccount => 'حساب واحد';

  @override
  String get newYearReset => 'إعادة تعيين السنة الجديدة';

  @override
  String get resetStudentAccount => 'إعادة تعيين حساب الطالب';

  @override
  String get enterStudentUniversityCodeReset =>
      'أدخل كود الجامعة للطالب لإعادة تعيين حسابه. سيسمح له هذا باستخدام شاشة \"التفعيل\" مرة أخرى.';

  @override
  String get howToResetAccount => 'كيفية إعادة تعيين الحساب';

  @override
  String get obtainStudentUniversityCode => 'احصل على كود جامعة الطالب.';

  @override
  String get enterExactUniversityCode =>
      'أدخل كود الجامعة الدقيق في الحقل أدناه.';

  @override
  String get clickResetAccountButton => 'انقر على \"إعادة تعيين الحساب\".';

  @override
  String get studentWillActivateAgain =>
      'بعد النجاح، سيتمكن الطالب من تفعيل حسابه مرة أخرى من جهازه الخاص.';

  @override
  String get studentUniversityCodeReset => 'كود جامعة الطالب';

  @override
  String get enterUniversityCodeExample =>
      'أدخل كود الجامعة (مثال: ST-20205522)';

  @override
  String get resetAccount => 'إعادة تعيين الحساب';

  @override
  String get accountResetSuccessfully => 'تم إعادة تعيين الحساب بنجاح';

  @override
  String failedToResetAccount(String error) {
    return 'فشل في إعادة تعيين الحساب: $error';
  }

  @override
  String get studentUniversityCodeRequired => 'كود جامعة الطالب مطلوب';

  @override
  String get invalidUniversityCode =>
      'يرجى إدخال كود جامعة صحيح (مثال: ST-20205522)';

  @override
  String get whatHappensResetStudent =>
      'ماذا يحدث عند إعادة تعيين حساب الطالب؟';

  @override
  String get studentCanUseActivateScreen =>
      'يمكن للطالب استخدام شاشة ال\"التفعيل\" مرة أخرى';

  @override
  String get accountStatusReset => 'حالة الحساب معاد تعيينها';

  @override
  String get completeActivationAgain => 'يحتاج لإكمال عملية التفعيل مرة أخرى';

  @override
  String get previousAccountDataAffected => 'قد تتأثر بيانات الحساب السابقة';
}
