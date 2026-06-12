import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'College Attendance System'**
  String get appName;

  /// No description provided for @appDescription.
  ///
  /// In en, this message translates to:
  /// **'A new Flutter project.'**
  String get appDescription;

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @activate.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activate;

  /// No description provided for @activateAccount.
  ///
  /// In en, this message translates to:
  /// **'Activate Account'**
  String get activateAccount;

  /// No description provided for @enterYourDetails.
  ///
  /// In en, this message translates to:
  /// **'Enter your credentials to access the college attendance system'**
  String get enterYourDetails;

  /// No description provided for @enterDetailsToActivate.
  ///
  /// In en, this message translates to:
  /// **'Enter your details to activate your college attendance account'**
  String get enterDetailsToActivate;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @enterEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterEmail;

  /// No description provided for @universityEmail.
  ///
  /// In en, this message translates to:
  /// **'University Email'**
  String get universityEmail;

  /// No description provided for @enterUniversityEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter university email'**
  String get enterUniversityEmail;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// No description provided for @enterStrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter a strong password (min. 6 characters)'**
  String get enterStrongPassword;

  /// No description provided for @universityCode.
  ///
  /// In en, this message translates to:
  /// **'University Code'**
  String get universityCode;

  /// No description provided for @enterUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get enterUniversityCode;

  /// No description provided for @enterCode.
  ///
  /// In en, this message translates to:
  /// **'Enter your code'**
  String get enterCode;

  /// No description provided for @deviceId.
  ///
  /// In en, this message translates to:
  /// **'Device ID'**
  String get deviceId;

  /// No description provided for @refreshDeviceId.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refreshDeviceId;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get alreadyHaveAccount;

  /// No description provided for @dontHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// No description provided for @emailIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Email is required'**
  String get emailIsRequired;

  /// No description provided for @enterValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid email address'**
  String get enterValidEmail;

  /// No description provided for @passwordIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required'**
  String get passwordIsRequired;

  /// No description provided for @codeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Code is required'**
  String get codeIsRequired;

  /// No description provided for @loginSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Login successful!'**
  String get loginSuccessful;

  /// No description provided for @activationSuccessful.
  ///
  /// In en, this message translates to:
  /// **'Account activated successfully!'**
  String get activationSuccessful;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password, or account not activated yet.'**
  String get loginFailed;

  /// No description provided for @sessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session has expired. Please log in again.'**
  String get sessionExpired;

  /// No description provided for @noInternetConnection.
  ///
  /// In en, this message translates to:
  /// **'No internet connection. Check your network.'**
  String get noInternetConnection;

  /// No description provided for @requestTimeout.
  ///
  /// In en, this message translates to:
  /// **'Request timed out. Please try again.'**
  String get requestTimeout;

  /// No description provided for @serverError.
  ///
  /// In en, this message translates to:
  /// **'Server error. Please try again later.'**
  String get serverError;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get somethingWentWrong;

  /// No description provided for @authenticationRequired.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authenticationRequired;

  /// No description provided for @accountNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found. Check your university code.'**
  String get accountNotFound;

  /// No description provided for @tooManyAttempts.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get tooManyAttempts;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @collegeAttendanceSystem.
  ///
  /// In en, this message translates to:
  /// **'College Attendance System'**
  String get collegeAttendanceSystem;

  /// No description provided for @studentDashboard.
  ///
  /// In en, this message translates to:
  /// **'Student Dashboard'**
  String get studentDashboard;

  /// No description provided for @adminDashboard.
  ///
  /// In en, this message translates to:
  /// **'Admin Dashboard'**
  String get adminDashboard;

  /// No description provided for @doctorDashboard.
  ///
  /// In en, this message translates to:
  /// **'Doctor Dashboard'**
  String get doctorDashboard;

  /// No description provided for @dashboardMenu.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Menu'**
  String get dashboardMenu;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @loadingStatistics.
  ///
  /// In en, this message translates to:
  /// **'Loading statistics...'**
  String get loadingStatistics;

  /// No description provided for @updatesAutomatically.
  ///
  /// In en, this message translates to:
  /// **'Updates automatically every 30 seconds'**
  String get updatesAutomatically;

  /// No description provided for @myCourses.
  ///
  /// In en, this message translates to:
  /// **'My Courses'**
  String get myCourses;

  /// No description provided for @coursesList.
  ///
  /// In en, this message translates to:
  /// **'List Courses'**
  String get coursesList;

  /// No description provided for @noAccessPermission.
  ///
  /// In en, this message translates to:
  /// **'No Access Permission'**
  String get noAccessPermission;

  /// No description provided for @connectionError.
  ///
  /// In en, this message translates to:
  /// **'Connection Error'**
  String get connectionError;

  /// No description provided for @noDataAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Data Available'**
  String get noDataAvailable;

  /// No description provided for @authenticationFailed.
  ///
  /// In en, this message translates to:
  /// **'Authentication Failed'**
  String get authenticationFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @doctors.
  ///
  /// In en, this message translates to:
  /// **'Doctors'**
  String get doctors;

  /// No description provided for @tas.
  ///
  /// In en, this message translates to:
  /// **'TAs'**
  String get tas;

  /// No description provided for @students.
  ///
  /// In en, this message translates to:
  /// **'Students'**
  String get students;

  /// No description provided for @courses.
  ///
  /// In en, this message translates to:
  /// **'Courses'**
  String get courses;

  /// No description provided for @staffManagement.
  ///
  /// In en, this message translates to:
  /// **'Staff Management'**
  String get staffManagement;

  /// No description provided for @createDoctorTA.
  ///
  /// In en, this message translates to:
  /// **'Create Dr,TA'**
  String get createDoctorTA;

  /// No description provided for @createDoctor.
  ///
  /// In en, this message translates to:
  /// **'Create Doctor'**
  String get createDoctor;

  /// No description provided for @createTA.
  ///
  /// In en, this message translates to:
  /// **'Create Teaching Assistant'**
  String get createTA;

  /// No description provided for @listDoctors.
  ///
  /// In en, this message translates to:
  /// **'List Doctors'**
  String get listDoctors;

  /// No description provided for @listTAs.
  ///
  /// In en, this message translates to:
  /// **'List TAs'**
  String get listTAs;

  /// No description provided for @deleteUser.
  ///
  /// In en, this message translates to:
  /// **'Delete User'**
  String get deleteUser;

  /// No description provided for @createDoctorAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Doctor Account'**
  String get createDoctorAccount;

  /// No description provided for @createTAAccount.
  ///
  /// In en, this message translates to:
  /// **'Create TA Account'**
  String get createTAAccount;

  /// No description provided for @createNewAccount.
  ///
  /// In en, this message translates to:
  /// **'Create New Account'**
  String get createNewAccount;

  /// No description provided for @fillDetailsToCreate.
  ///
  /// In en, this message translates to:
  /// **'Fill in the details to create a new account'**
  String get fillDetailsToCreate;

  /// No description provided for @accountCreationSteps.
  ///
  /// In en, this message translates to:
  /// **'Account Creation Steps'**
  String get accountCreationSteps;

  /// No description provided for @selectAccountType.
  ///
  /// In en, this message translates to:
  /// **'Select the Account Type (Doctor or Teaching Assistant).'**
  String get selectAccountType;

  /// No description provided for @enterFullName.
  ///
  /// In en, this message translates to:
  /// **'Enter the full name of the staff member.'**
  String get enterFullName;

  /// No description provided for @provideValidEmail.
  ///
  /// In en, this message translates to:
  /// **'Provide a valid email address.'**
  String get provideValidEmail;

  /// No description provided for @setSecurePassword.
  ///
  /// In en, this message translates to:
  /// **'Set a secure password (minimum 6 characters).'**
  String get setSecurePassword;

  /// No description provided for @clickCreateButton.
  ///
  /// In en, this message translates to:
  /// **'Click the Create button to finalize.'**
  String get clickCreateButton;

  /// No description provided for @accountType.
  ///
  /// In en, this message translates to:
  /// **'Account Type'**
  String get accountType;

  /// No description provided for @doctor.
  ///
  /// In en, this message translates to:
  /// **'Doctor'**
  String get doctor;

  /// No description provided for @teachingAssistant.
  ///
  /// In en, this message translates to:
  /// **'Teaching Assistant'**
  String get teachingAssistant;

  /// No description provided for @fullName.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get fullName;

  /// No description provided for @enterDoctorName.
  ///
  /// In en, this message translates to:
  /// **'Enter doctor name'**
  String get enterDoctorName;

  /// No description provided for @enterTAName.
  ///
  /// In en, this message translates to:
  /// **'Enter TA name'**
  String get enterTAName;

  /// No description provided for @emailAddress.
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get emailAddress;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createAccount.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get createAccount;

  /// No description provided for @doctorAccountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Doctor account created successfully'**
  String get doctorAccountCreatedSuccessfully;

  /// No description provided for @taAccountCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Teaching assistant account created successfully'**
  String get taAccountCreatedSuccessfully;

  /// No description provided for @exit.
  ///
  /// In en, this message translates to:
  /// **'Exit'**
  String get exit;

  /// No description provided for @authenticationTokenNotFound.
  ///
  /// In en, this message translates to:
  /// **'Authentication token not found'**
  String get authenticationTokenNotFound;

  /// No description provided for @studentManagement.
  ///
  /// In en, this message translates to:
  /// **'Student Management'**
  String get studentManagement;

  /// No description provided for @bulkCreateStudents.
  ///
  /// In en, this message translates to:
  /// **'Bulk Create Students'**
  String get bulkCreateStudents;

  /// No description provided for @createMultipleStudents.
  ///
  /// In en, this message translates to:
  /// **'Create Multiple Students'**
  String get createMultipleStudents;

  /// No description provided for @addStudentsOneByOne.
  ///
  /// In en, this message translates to:
  /// **'Add students one by one or in bulk'**
  String get addStudentsOneByOne;

  /// No description provided for @bulkDeleteStudents.
  ///
  /// In en, this message translates to:
  /// **'Bulk Delete Students'**
  String get bulkDeleteStudents;

  /// No description provided for @resetAccounts.
  ///
  /// In en, this message translates to:
  /// **'Reset Accounts'**
  String get resetAccounts;

  /// No description provided for @resetAccountsPage.
  ///
  /// In en, this message translates to:
  /// **'Reset Students Accounts'**
  String get resetAccountsPage;

  /// No description provided for @resetStudentsNewYear.
  ///
  /// In en, this message translates to:
  /// **'Reset Students For New Year'**
  String get resetStudentsNewYear;

  /// No description provided for @importFromExcel.
  ///
  /// In en, this message translates to:
  /// **'Import From Excel'**
  String get importFromExcel;

  /// No description provided for @uploadExcel.
  ///
  /// In en, this message translates to:
  /// **'Upload Excel'**
  String get uploadExcel;

  /// No description provided for @importExcel.
  ///
  /// In en, this message translates to:
  /// **'Upload an Excel file with a column named \"University Code\" or \"code\"'**
  String get importExcel;

  /// No description provided for @uploading.
  ///
  /// In en, this message translates to:
  /// **'Uploading...'**
  String get uploading;

  /// No description provided for @importing.
  ///
  /// In en, this message translates to:
  /// **'Importing...'**
  String get importing;

  /// No description provided for @clearAll.
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @addStudent.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudent;

  /// No description provided for @addStudentManually.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudentManually;

  /// No description provided for @studentName.
  ///
  /// In en, this message translates to:
  /// **'Student Name'**
  String get studentName;

  /// No description provided for @enterStudentName.
  ///
  /// In en, this message translates to:
  /// **'Enter student full name'**
  String get enterStudentName;

  /// No description provided for @studentCode.
  ///
  /// In en, this message translates to:
  /// **'Student Code'**
  String get studentCode;

  /// No description provided for @studentsToAdd.
  ///
  /// In en, this message translates to:
  /// **'Students to Add'**
  String get studentsToAdd;

  /// No description provided for @ready.
  ///
  /// In en, this message translates to:
  /// **'Ready'**
  String get ready;

  /// No description provided for @studentAdded.
  ///
  /// In en, this message translates to:
  /// **'Student added to list'**
  String get studentAdded;

  /// No description provided for @pleaseAddAtLeastOne.
  ///
  /// In en, this message translates to:
  /// **'Please add at least one student'**
  String get pleaseAddAtLeastOne;

  /// No description provided for @pleaseFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix all errors before adding'**
  String get pleaseFixErrors;

  /// No description provided for @createStudents.
  ///
  /// In en, this message translates to:
  /// **'Create Students'**
  String get createStudents;

  /// No description provided for @studentsCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Students created successfully!'**
  String get studentsCreatedSuccessfully;

  /// No description provided for @importedStudents.
  ///
  /// In en, this message translates to:
  /// **'Imported {count} students, skipped {skipped} rows.'**
  String importedStudents(int count, int skipped);

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: {error}'**
  String importFailed(String error);

  /// No description provided for @errorCreatingStudents.
  ///
  /// In en, this message translates to:
  /// **'Error creating students: {error}'**
  String errorCreatingStudents(String error);

  /// No description provided for @confirmDeletion.
  ///
  /// In en, this message translates to:
  /// **'Confirm Deletion'**
  String get confirmDeletion;

  /// No description provided for @areYouSurDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete user with code: {code}?'**
  String areYouSurDeleteUser(String code);

  /// No description provided for @dangerZone.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Danger Zone'**
  String get dangerZone;

  /// No description provided for @thisActionCannotBeUndone.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete the user and all their data. This cannot be undone.'**
  String get thisActionCannotBeUndone;

  /// No description provided for @howToDeleteUser.
  ///
  /// In en, this message translates to:
  /// **'How to Delete a User'**
  String get howToDeleteUser;

  /// No description provided for @howToFindUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'How to Find University Code'**
  String get howToFindUniversityCode;

  /// No description provided for @userCodeFormat.
  ///
  /// In en, this message translates to:
  /// **'User code format: \"TA-XXXX\" for TAs, \"DR-XXXX\" for Doctors'**
  String get userCodeFormat;

  /// No description provided for @makesurecorrectcode.
  ///
  /// In en, this message translates to:
  /// **'Make sure you have the correct code before deleting'**
  String get makesurecorrectcode;

  /// No description provided for @deletedUsersCannotRecover.
  ///
  /// In en, this message translates to:
  /// **'Deleted users cannot be recovered'**
  String get deletedUsersCannotRecover;

  /// No description provided for @deleteBothDoctorsAndTAs.
  ///
  /// In en, this message translates to:
  /// **'This deletes both doctors and teaching assistants'**
  String get deleteBothDoctorsAndTAs;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteUserSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'User deleted successfully!'**
  String get deleteUserSuccessfully;

  /// No description provided for @courseManagement.
  ///
  /// In en, this message translates to:
  /// **'Course Management'**
  String get courseManagement;

  /// No description provided for @createCourse.
  ///
  /// In en, this message translates to:
  /// **'Create Course'**
  String get createCourse;

  /// No description provided for @assignStaff.
  ///
  /// In en, this message translates to:
  /// **'Assign Staff'**
  String get assignStaff;

  /// No description provided for @assignStaffToCourse.
  ///
  /// In en, this message translates to:
  /// **'Assign Staff to Course'**
  String get assignStaffToCourse;

  /// No description provided for @assignDoctorOrTA.
  ///
  /// In en, this message translates to:
  /// **'Assign Doctor or TA'**
  String get assignDoctorOrTA;

  /// No description provided for @courseCode.
  ///
  /// In en, this message translates to:
  /// **'Course Code'**
  String get courseCode;

  /// No description provided for @enterCourseCode.
  ///
  /// In en, this message translates to:
  /// **'e.g., CS101'**
  String get enterCourseCode;

  /// No description provided for @courseId.
  ///
  /// In en, this message translates to:
  /// **'Course ID'**
  String get courseId;

  /// No description provided for @enterCourseIdNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter course ID number'**
  String get enterCourseIdNumber;

  /// No description provided for @staffUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'Staff University Code'**
  String get staffUniversityCode;

  /// No description provided for @enterStaffUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'e.g., DR-XXXX or TA-XXXX'**
  String get enterStaffUniversityCode;

  /// No description provided for @courseName.
  ///
  /// In en, this message translates to:
  /// **'Course Name'**
  String get courseName;

  /// No description provided for @enterCourseName.
  ///
  /// In en, this message translates to:
  /// **'Enter course name'**
  String get enterCourseName;

  /// No description provided for @courseDescription.
  ///
  /// In en, this message translates to:
  /// **'Course Description'**
  String get courseDescription;

  /// No description provided for @enterCourseDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter course description'**
  String get enterCourseDescription;

  /// No description provided for @staffAssignedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Staff assigned successfully!'**
  String get staffAssignedSuccessfully;

  /// No description provided for @courseCreatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Course created successfully!'**
  String get courseCreatedSuccessfully;

  /// No description provided for @courseDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Course deleted successfully!'**
  String get courseDeletedSuccessfully;

  /// No description provided for @courseEnrollmentPage.
  ///
  /// In en, this message translates to:
  /// **'Course Enrollment'**
  String get courseEnrollmentPage;

  /// No description provided for @enrollStudent.
  ///
  /// In en, this message translates to:
  /// **'Enroll Student'**
  String get enrollStudent;

  /// No description provided for @enrollStudentManually.
  ///
  /// In en, this message translates to:
  /// **'Single student manual registration'**
  String get enrollStudentManually;

  /// No description provided for @bulkEnrollPage.
  ///
  /// In en, this message translates to:
  /// **'Bulk Enroll'**
  String get bulkEnrollPage;

  /// No description provided for @bulkEnrollStudents.
  ///
  /// In en, this message translates to:
  /// **'Excel import or multiple codes'**
  String get bulkEnrollStudents;

  /// No description provided for @studentUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'Student University Code'**
  String get studentUniversityCode;

  /// No description provided for @enrollmentErrorAlreadyEnrolled.
  ///
  /// In en, this message translates to:
  /// **'Student is already enrolled in this course.'**
  String get enrollmentErrorAlreadyEnrolled;

  /// No description provided for @enrollmentErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get enrollmentErrorPermission;

  /// No description provided for @enrollmentErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'Course not found.'**
  String get enrollmentErrorNotFound;

  /// No description provided for @enrollmentErrorTooMany.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment and try again.'**
  String get enrollmentErrorTooMany;

  /// No description provided for @enrollmentErrorInvalidRequest.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check your input and try again.'**
  String get enrollmentErrorInvalidRequest;

  /// No description provided for @studentEnrolledSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Student enrolled successfully!'**
  String get studentEnrolledSuccessfully;

  /// No description provided for @enrollStudents.
  ///
  /// In en, this message translates to:
  /// **'Enroll Students'**
  String get enrollStudents;

  /// No description provided for @bulkEnrollHowTo.
  ///
  /// In en, this message translates to:
  /// **'Bulk Enroll How-To'**
  String get bulkEnrollHowTo;

  /// No description provided for @bulkEnrollOption1.
  ///
  /// In en, this message translates to:
  /// **'Option 1: Use \"Import from Excel\" to upload a .xlsx file with a \"University Code\" column.'**
  String get bulkEnrollOption1;

  /// No description provided for @bulkEnrollOption2.
  ///
  /// In en, this message translates to:
  /// **'Option 2: Manually enter university codes one by one in the \"Add Manually\" section.'**
  String get bulkEnrollOption2;

  /// No description provided for @bulkEnrollOption3.
  ///
  /// In en, this message translates to:
  /// **'Review the compiled list of students below.'**
  String get bulkEnrollOption3;

  /// No description provided for @bulkEnrollOption4.
  ///
  /// In en, this message translates to:
  /// **'Enter the Course ID in the top field.'**
  String get bulkEnrollOption4;

  /// No description provided for @bulkEnrollOption5.
  ///
  /// In en, this message translates to:
  /// **'Click \"Enroll Students\" to finalize the registration.'**
  String get bulkEnrollOption5;

  /// No description provided for @bulkEnrollOption6.
  ///
  /// In en, this message translates to:
  /// **'A report will show which students were added, skipped, or not found.'**
  String get bulkEnrollOption6;

  /// No description provided for @courseEnrollmentHowTo.
  ///
  /// In en, this message translates to:
  /// **'How to Enroll a Student'**
  String get courseEnrollmentHowTo;

  /// No description provided for @courseEnrollmentStep1.
  ///
  /// In en, this message translates to:
  /// **'Find the internal Course ID number of the target course.'**
  String get courseEnrollmentStep1;

  /// No description provided for @courseEnrollmentStep2.
  ///
  /// In en, this message translates to:
  /// **'Obtain the student\'s exact University Code.'**
  String get courseEnrollmentStep2;

  /// No description provided for @courseEnrollmentStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter both details into the fields below.'**
  String get courseEnrollmentStep3;

  /// No description provided for @courseEnrollmentStep4.
  ///
  /// In en, this message translates to:
  /// **'Click \"Enroll Student\" to finalize the registration.'**
  String get courseEnrollmentStep4;

  /// No description provided for @pleaseBothCodes.
  ///
  /// In en, this message translates to:
  /// **'Please enter both codes.'**
  String get pleaseBothCodes;

  /// No description provided for @pleaseFixErrorsForm.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors in the form'**
  String get pleaseFixErrorsForm;

  /// No description provided for @sessionManagement.
  ///
  /// In en, this message translates to:
  /// **'Session Management'**
  String get sessionManagement;

  /// No description provided for @startNewSession.
  ///
  /// In en, this message translates to:
  /// **'Start New Session'**
  String get startNewSession;

  /// No description provided for @createSession.
  ///
  /// In en, this message translates to:
  /// **'Create Session'**
  String get createSession;

  /// No description provided for @createSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a Lecture or Section session with GPS'**
  String get createSessionSubtitle;

  /// No description provided for @stopActiveSession.
  ///
  /// In en, this message translates to:
  /// **'Stop Active Session'**
  String get stopActiveSession;

  /// No description provided for @stopActiveSessionSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Manually stop a running session by ID'**
  String get stopActiveSessionSubtitle;

  /// No description provided for @viewAllSessions.
  ///
  /// In en, this message translates to:
  /// **'View All Sessions'**
  String get viewAllSessions;

  /// No description provided for @viewAllSessionsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Lectures & Sections history · Tap to see attendees'**
  String get viewAllSessionsSubtitle;

  /// No description provided for @sessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Session Title'**
  String get sessionTitle;

  /// No description provided for @enterSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'e.g., Chapter 4: Data Structures'**
  String get enterSessionTitle;

  /// No description provided for @sessionType.
  ///
  /// In en, this message translates to:
  /// **'Session Type'**
  String get sessionType;

  /// No description provided for @lecture.
  ///
  /// In en, this message translates to:
  /// **'Lecture'**
  String get lecture;

  /// No description provided for @section.
  ///
  /// In en, this message translates to:
  /// **'Section'**
  String get section;

  /// No description provided for @allowedRadius.
  ///
  /// In en, this message translates to:
  /// **'Allowed Radius (meters)'**
  String get allowedRadius;

  /// No description provided for @enterAllowedRadius.
  ///
  /// In en, this message translates to:
  /// **'e.g., 50'**
  String get enterAllowedRadius;

  /// No description provided for @startSession.
  ///
  /// In en, this message translates to:
  /// **'Start Session'**
  String get startSession;

  /// No description provided for @sessionStarted.
  ///
  /// In en, this message translates to:
  /// **'Session started successfully!'**
  String get sessionStarted;

  /// No description provided for @sessionStopped.
  ///
  /// In en, this message translates to:
  /// **'Session stopped successfully!'**
  String get sessionStopped;

  /// No description provided for @sessionResumed.
  ///
  /// In en, this message translates to:
  /// **'Session resumed successfully!'**
  String get sessionResumed;

  /// No description provided for @sessionAlreadyRunning.
  ///
  /// In en, this message translates to:
  /// **'There is already a running session. Do you want to continue with it?'**
  String get sessionAlreadyRunning;

  /// No description provided for @continueAction.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueAction;

  /// No description provided for @pleaseEnterSessionId.
  ///
  /// In en, this message translates to:
  /// **'Please enter a Session ID'**
  String get pleaseEnterSessionId;

  /// No description provided for @invalidSessionIdFormat.
  ///
  /// In en, this message translates to:
  /// **'Invalid Session ID format'**
  String get invalidSessionIdFormat;

  /// No description provided for @stopSession.
  ///
  /// In en, this message translates to:
  /// **'Stop Session'**
  String get stopSession;

  /// No description provided for @enterSessionIdStop.
  ///
  /// In en, this message translates to:
  /// **'Enter the Session ID you wish to stop:'**
  String get enterSessionIdStop;

  /// No description provided for @enterSessionId.
  ///
  /// In en, this message translates to:
  /// **'Session ID'**
  String get enterSessionId;

  /// No description provided for @sessionCreationSteps.
  ///
  /// In en, this message translates to:
  /// **'Session Creation Steps'**
  String get sessionCreationSteps;

  /// No description provided for @courseInformation.
  ///
  /// In en, this message translates to:
  /// **'Course Information'**
  String get courseInformation;

  /// No description provided for @course.
  ///
  /// In en, this message translates to:
  /// **'Course'**
  String get course;

  /// No description provided for @attendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendance;

  /// No description provided for @registerAttendance.
  ///
  /// In en, this message translates to:
  /// **'Register Attendance'**
  String get registerAttendance;

  /// No description provided for @scanQRCode.
  ///
  /// In en, this message translates to:
  /// **'Scan QR Code'**
  String get scanQRCode;

  /// No description provided for @enterPINCode.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN Code'**
  String get enterPINCode;

  /// No description provided for @activeSessionOpen.
  ///
  /// In en, this message translates to:
  /// **'An active session is open!'**
  String get activeSessionOpen;

  /// No description provided for @liveSession.
  ///
  /// In en, this message translates to:
  /// **'Live Session'**
  String get liveSession;

  /// No description provided for @liveAttendance.
  ///
  /// In en, this message translates to:
  /// **'Live Attendance'**
  String get liveAttendance;

  /// No description provided for @attendeesCount.
  ///
  /// In en, this message translates to:
  /// **'Live Attendees Count'**
  String get attendeesCount;

  /// No description provided for @scanQRCodeStudentApp.
  ///
  /// In en, this message translates to:
  /// **'Scan using Student App'**
  String get scanQRCodeStudentApp;

  /// No description provided for @orEnterPin.
  ///
  /// In en, this message translates to:
  /// **'OR ENTER PIN'**
  String get orEnterPin;

  /// No description provided for @manualEntry.
  ///
  /// In en, this message translates to:
  /// **'Manual Entry PIN'**
  String get manualEntry;

  /// No description provided for @pinAutoChangeSeconds.
  ///
  /// In en, this message translates to:
  /// **'PIN and QR automatically change every {seconds} seconds'**
  String pinAutoChangeSeconds(int seconds);

  /// No description provided for @fullScreen.
  ///
  /// In en, this message translates to:
  /// **'Full Screen'**
  String get fullScreen;

  /// No description provided for @attendanceSubmitted.
  ///
  /// In en, this message translates to:
  /// **'Attendance submitted!'**
  String get attendanceSubmitted;

  /// No description provided for @manualAttendance.
  ///
  /// In en, this message translates to:
  /// **'Manual Attendance'**
  String get manualAttendance;

  /// No description provided for @enterStudentCodeManual.
  ///
  /// In en, this message translates to:
  /// **'Enter the student\'s University Code to record attendance manually:'**
  String get enterStudentCodeManual;

  /// No description provided for @addStudentManual.
  ///
  /// In en, this message translates to:
  /// **'Add Student'**
  String get addStudentManual;

  /// No description provided for @locationPermissionsDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are denied'**
  String get locationPermissionsDenied;

  /// No description provided for @locationPermissionsPermanentlyDenied.
  ///
  /// In en, this message translates to:
  /// **'Location permissions are permanently denied'**
  String get locationPermissionsPermanentlyDenied;

  /// No description provided for @networkError.
  ///
  /// In en, this message translates to:
  /// **'Network error'**
  String get networkError;

  /// No description provided for @attendanceDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Attendance deleted successfully'**
  String get attendanceDeletedSuccessfully;

  /// No description provided for @studentAddedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Student added successfully'**
  String get studentAddedSuccessfully;

  /// No description provided for @attendanceIsClosed.
  ///
  /// In en, this message translates to:
  /// **'Attendance is Closed'**
  String get attendanceIsClosed;

  /// No description provided for @reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports;

  /// No description provided for @lectureReport.
  ///
  /// In en, this message translates to:
  /// **'Lecture Report'**
  String get lectureReport;

  /// No description provided for @lectureReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance insights'**
  String get lectureReportSubtitle;

  /// No description provided for @sectionReport.
  ///
  /// In en, this message translates to:
  /// **'Section Report'**
  String get sectionReport;

  /// No description provided for @sectionReportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Labs & Exercises'**
  String get sectionReportSubtitle;

  /// No description provided for @sessionHistory.
  ///
  /// In en, this message translates to:
  /// **'Session History'**
  String get sessionHistory;

  /// No description provided for @sessionHistorySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Past sessions'**
  String get sessionHistorySubtitle;

  /// No description provided for @absenceWarnings.
  ///
  /// In en, this message translates to:
  /// **'Absence Warnings'**
  String get absenceWarnings;

  /// No description provided for @absenceWarningsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'At-risk students'**
  String get absenceWarningsSubtitle;

  /// No description provided for @enrolledStudents.
  ///
  /// In en, this message translates to:
  /// **'Enrolled Students'**
  String get enrolledStudents;

  /// No description provided for @totalMarks.
  ///
  /// In en, this message translates to:
  /// **'Total Marks (optional)'**
  String get totalMarks;

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// No description provided for @code.
  ///
  /// In en, this message translates to:
  /// **'Code'**
  String get code;

  /// No description provided for @attended.
  ///
  /// In en, this message translates to:
  /// **'Attended'**
  String get attended;

  /// No description provided for @absent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get absent;

  /// No description provided for @totalLectures.
  ///
  /// In en, this message translates to:
  /// **'Total Lectures: {count}'**
  String totalLectures(int count);

  /// No description provided for @marks.
  ///
  /// In en, this message translates to:
  /// **'Marks: {marks}'**
  String marks(String marks);

  /// No description provided for @totalSections.
  ///
  /// In en, this message translates to:
  /// **'Total Sections: {count}'**
  String totalSections(int count);

  /// No description provided for @exportToExcel.
  ///
  /// In en, this message translates to:
  /// **'Export to Excel'**
  String get exportToExcel;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @searchByNameCode.
  ///
  /// In en, this message translates to:
  /// **'Search by name or university code...'**
  String get searchByNameCode;

  /// No description provided for @searchByNameOrCode.
  ///
  /// In en, this message translates to:
  /// **'Search by name or code...'**
  String get searchByNameOrCode;

  /// No description provided for @studentEnrolled.
  ///
  /// In en, this message translates to:
  /// **'{count} student(s) enrolled'**
  String studentEnrolled(int count);

  /// No description provided for @absenceWarningsPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Absence Warnings'**
  String get absenceWarningsPageTitle;

  /// No description provided for @attendanceReports.
  ///
  /// In en, this message translates to:
  /// **'Attendance Reports'**
  String get attendanceReports;

  /// No description provided for @attendanceReportsSubtitle.
  ///
  /// In en, this message translates to:
  /// **'View your attendance summary'**
  String get attendanceReportsSubtitle;

  /// No description provided for @dangerYouExceededAbsenceLimit.
  ///
  /// In en, this message translates to:
  /// **'Danger: You have exceeded the allowed absence limit (3) and may be deprived of exams.'**
  String get dangerYouExceededAbsenceLimit;

  /// No description provided for @noStudentsAttendedYet.
  ///
  /// In en, this message translates to:
  /// **'No students attended yet'**
  String get noStudentsAttendedYet;

  /// No description provided for @noSessionsFound.
  ///
  /// In en, this message translates to:
  /// **'No sessions found.'**
  String get noSessionsFound;

  /// No description provided for @noStudentsFound.
  ///
  /// In en, this message translates to:
  /// **'No students found'**
  String get noStudentsFound;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @submit.
  ///
  /// In en, this message translates to:
  /// **'Submit'**
  String get submit;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear Search'**
  String get clearSearch;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @previous.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previous;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @ok.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get ok;

  /// No description provided for @done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @updateRadius.
  ///
  /// In en, this message translates to:
  /// **'Update Radius'**
  String get updateRadius;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @areYouSureLogout.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to logout from your account?'**
  String get areYouSureLogout;

  /// No description provided for @errorStopping.
  ///
  /// In en, this message translates to:
  /// **'Error stopping session: {error}'**
  String errorStopping(String error);

  /// No description provided for @changeAllowedScanDistance.
  ///
  /// In en, this message translates to:
  /// **'Change the allowed scanning distance for students (in meters).'**
  String get changeAllowedScanDistance;

  /// No description provided for @meters.
  ///
  /// In en, this message translates to:
  /// **'{count} meters'**
  String meters(int count);

  /// No description provided for @radiusUpdatedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Radius updated successfully!'**
  String get radiusUpdatedSuccessfully;

  /// No description provided for @permissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get permissionDenied;

  /// No description provided for @invalidRequestCheckInput.
  ///
  /// In en, this message translates to:
  /// **'Invalid request. Please check your input and try again.'**
  String get invalidRequestCheckInput;

  /// No description provided for @noPermissionDoThis.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to do this.'**
  String get noPermissionDoThis;

  /// No description provided for @alreadyClosed.
  ///
  /// In en, this message translates to:
  /// **'Session is already closed.'**
  String get alreadyClosed;

  /// No description provided for @alreadyActive.
  ///
  /// In en, this message translates to:
  /// **'This session is already active.'**
  String get alreadyActive;

  /// No description provided for @conflictingSession.
  ///
  /// In en, this message translates to:
  /// **'A conflicting session already exists for this course.'**
  String get conflictingSession;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @arabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @assignStaffDescription.
  ///
  /// In en, this message translates to:
  /// **'Enter the course code and the staff university code to link them together.'**
  String get assignStaffDescription;

  /// No description provided for @errorAssigningStaff.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorAssigningStaff(String error);

  /// No description provided for @failedToConnect.
  ///
  /// In en, this message translates to:
  /// **'Failed to connect: {error}'**
  String failedToConnect(String error);

  /// No description provided for @noAttendanceRecordsFound.
  ///
  /// In en, this message translates to:
  /// **'No attendance records found'**
  String get noAttendanceRecordsFound;

  /// No description provided for @noAttendanceRecords.
  ///
  /// In en, this message translates to:
  /// **'No attendance records'**
  String get noAttendanceRecords;

  /// No description provided for @pointsString.
  ///
  /// In en, this message translates to:
  /// **'{marks} pts'**
  String pointsString(String marks);

  /// No description provided for @codeString.
  ///
  /// In en, this message translates to:
  /// **'Code: {code}'**
  String codeString(String code);

  /// No description provided for @totalStudents.
  ///
  /// In en, this message translates to:
  /// **'Total Students'**
  String get totalStudents;

  /// No description provided for @totalCourses.
  ///
  /// In en, this message translates to:
  /// **'Total Courses'**
  String get totalCourses;

  /// No description provided for @noCoursesAssignedYet.
  ///
  /// In en, this message translates to:
  /// **'No courses assigned yet'**
  String get noCoursesAssignedYet;

  /// No description provided for @noCoursesMatchSearch.
  ///
  /// In en, this message translates to:
  /// **'No courses match your search'**
  String get noCoursesMatchSearch;

  /// No description provided for @reportsAndAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Reports & Analytics'**
  String get reportsAndAnalytics;

  /// No description provided for @fillRequiredCourse.
  ///
  /// In en, this message translates to:
  /// **'Fill in all required fields to create a new course'**
  String get fillRequiredCourse;

  /// No description provided for @createNewCourse.
  ///
  /// In en, this message translates to:
  /// **'Create New Course'**
  String get createNewCourse;

  /// No description provided for @courseCreationSteps.
  ///
  /// In en, this message translates to:
  /// **'Course Creation Steps'**
  String get courseCreationSteps;

  /// No description provided for @courseCreationStep1.
  ///
  /// In en, this message translates to:
  /// **'Enter a clear, descriptive name for the course.'**
  String get courseCreationStep1;

  /// No description provided for @courseCreationStep2.
  ///
  /// In en, this message translates to:
  /// **'Provide a unique Course Code (e.g., CS4710).'**
  String get courseCreationStep2;

  /// No description provided for @courseCreationStep3.
  ///
  /// In en, this message translates to:
  /// **'Enter the exact University Code of the Doctor assigned to this course.'**
  String get courseCreationStep3;

  /// No description provided for @courseCreationStep4.
  ///
  /// In en, this message translates to:
  /// **'Provide a brief description of the course contents.'**
  String get courseCreationStep4;

  /// No description provided for @courseCreationStep5.
  ///
  /// In en, this message translates to:
  /// **'Click "Create Course" to finalize.'**
  String get courseCreationStep5;

  /// No description provided for @doctorUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'Doctor University Code'**
  String get doctorUniversityCode;

  /// No description provided for @enterDoctorUniversityCode.
  ///
  /// In en, this message translates to:
  /// **'Enter doctor university code (e.g., DR-1234)'**
  String get enterDoctorUniversityCode;

  /// No description provided for @courseNameIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Course name is required'**
  String get courseNameIsRequired;

  /// No description provided for @courseNameMustBeAtLeast2Chars.
  ///
  /// In en, this message translates to:
  /// **'Course name must be at least 2 characters'**
  String get courseNameMustBeAtLeast2Chars;

  /// No description provided for @courseCodeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Course code is required'**
  String get courseCodeIsRequired;

  /// No description provided for @courseCodeMustBeAtLeast2Chars.
  ///
  /// In en, this message translates to:
  /// **'Course code must be at least 2 characters'**
  String get courseCodeMustBeAtLeast2Chars;

  /// No description provided for @courseDescriptionIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get courseDescriptionIsRequired;

  /// No description provided for @courseDescriptionMustBeAtLeast5Chars.
  ///
  /// In en, this message translates to:
  /// **'Description must be at least 5 characters'**
  String get courseDescriptionMustBeAtLeast5Chars;

  /// No description provided for @doctorUniversityCodeIsRequired.
  ///
  /// In en, this message translates to:
  /// **'Doctor University Code is required'**
  String get doctorUniversityCodeIsRequired;

  /// No description provided for @doctorUniversityCodeMustBeValid.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid University Code (e.g., DR-1234)'**
  String get doctorUniversityCodeMustBeValid;

  /// No description provided for @passwordRequirements.
  ///
  /// In en, this message translates to:
  /// **'Password requirements:'**
  String get passwordRequirements;

  /// No description provided for @atLeast6Chars.
  ///
  /// In en, this message translates to:
  /// **'At least 6 characters'**
  String get atLeast6Chars;

  /// No description provided for @manualAdd.
  ///
  /// In en, this message translates to:
  /// **'Manual Add'**
  String get manualAdd;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// No description provided for @noSessionsFoundForType.
  ///
  /// In en, this message translates to:
  /// **'No {type} sessions found.'**
  String noSessionsFoundForType(String type);

  /// No description provided for @removeThisStudent.
  ///
  /// In en, this message translates to:
  /// **'Remove this student?'**
  String get removeThisStudent;

  /// No description provided for @errorConnectingServer.
  ///
  /// In en, this message translates to:
  /// **'Error connecting to server'**
  String get errorConnectingServer;

  /// No description provided for @deleteAttendance.
  ///
  /// In en, this message translates to:
  /// **'Delete Attendance'**
  String get deleteAttendance;

  /// No description provided for @searchDoctors.
  ///
  /// In en, this message translates to:
  /// **'Search doctors...'**
  String get searchDoctors;

  /// No description provided for @searchTAs.
  ///
  /// In en, this message translates to:
  /// **'Search TAs...'**
  String get searchTAs;

  /// No description provided for @autoRefreshEvery30Seconds.
  ///
  /// In en, this message translates to:
  /// **'Auto-refresh every 30 seconds'**
  String get autoRefreshEvery30Seconds;

  /// No description provided for @doctorCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 doctors} =1{1 doctor} other{{count} doctors}}'**
  String doctorCount(int count);

  /// No description provided for @taCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{0 TAs} =1{1 TA} other{{count} TAs}}'**
  String taCount(int count);

  /// No description provided for @noDoctorsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No doctors available'**
  String get noDoctorsAvailable;

  /// No description provided for @noDoctorsFound.
  ///
  /// In en, this message translates to:
  /// **'No doctors found'**
  String get noDoctorsFound;

  /// No description provided for @noTAsAvailable.
  ///
  /// In en, this message translates to:
  /// **'No Teaching Assistants available'**
  String get noTAsAvailable;

  /// No description provided for @noTAsFound.
  ///
  /// In en, this message translates to:
  /// **'No TAs found'**
  String get noTAsFound;

  /// No description provided for @tryDifferentSearchTerm.
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearchTerm;

  /// No description provided for @generalInformation.
  ///
  /// In en, this message translates to:
  /// **'General Information'**
  String get generalInformation;

  /// No description provided for @doctorProfile.
  ///
  /// In en, this message translates to:
  /// **'Doctor Profile'**
  String get doctorProfile;

  /// No description provided for @taProfile.
  ///
  /// In en, this message translates to:
  /// **'Teaching Assistant Profile'**
  String get taProfile;

  /// No description provided for @doctorDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Doctor deleted successfully!'**
  String get doctorDeletedSuccessfully;

  /// No description provided for @taDeletedSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'TA deleted successfully!'**
  String get taDeletedSuccessfully;

  /// No description provided for @cannotDeleteDoctorAssigned.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete this doctor because they are currently assigned to one or more courses. Please unassign them first.'**
  String get cannotDeleteDoctorAssigned;

  /// No description provided for @cannotDeleteTAAssigned.
  ///
  /// In en, this message translates to:
  /// **'Cannot delete this TA because they are currently assigned to one or more courses. Please unassign them first.'**
  String get cannotDeleteTAAssigned;

  /// No description provided for @confirmDeleteDoctor.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete Dr. {name}?\n\nThis will permanently remove their account and access.'**
  String confirmDeleteDoctor(String name);

  /// No description provided for @confirmDeleteTA.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete TA \'{name}\'?\n\nThis will permanently remove their account and access.'**
  String confirmDeleteTA(String name);
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
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
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
