// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'College Attendance System';

  @override
  String get appDescription => 'A new Flutter project.';

  @override
  String get login => 'Login';

  @override
  String get activate => 'Activate Account';

  @override
  String get activateAccount => 'Activate Account';

  @override
  String get enterYourDetails =>
      'Enter your credentials to access the college attendance system';

  @override
  String get enterDetailsToActivate =>
      'Enter your details to activate your college attendance account';

  @override
  String get email => 'Email';

  @override
  String get enterEmail => 'Enter your email';

  @override
  String get universityEmail => 'University Email';

  @override
  String get enterUniversityEmail => 'Enter university email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get newPassword => 'New Password';

  @override
  String get enterStrongPassword =>
      'Enter a strong password (min. 6 characters)';

  @override
  String get universityCode => 'University Code';

  @override
  String get enterUniversityCode => 'Enter your code';

  @override
  String get enterCode => 'Enter your code';

  @override
  String get deviceId => 'Device ID';

  @override
  String get refreshDeviceId => 'Refresh';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get emailIsRequired => 'Email is required';

  @override
  String get enterValidEmail => 'Please enter a valid email address';

  @override
  String get passwordIsRequired => 'Password is required';

  @override
  String get codeIsRequired => 'Code is required';

  @override
  String get loginSuccessful => 'Login successful!';

  @override
  String get activationSuccessful => 'Account activated successfully!';

  @override
  String get loginFailed =>
      'Incorrect email or password, or account not activated yet.';

  @override
  String get sessionExpired => 'Your session has expired. Please log in again.';

  @override
  String get noInternetConnection =>
      'No internet connection. Check your network.';

  @override
  String get requestTimeout => 'Request timed out. Please try again.';

  @override
  String get serverError => 'Server error. Please try again later.';

  @override
  String get somethingWentWrong => 'Something went wrong. Please try again.';

  @override
  String get authenticationRequired => 'Authentication Required';

  @override
  String get accountNotFound =>
      'Account not found. Check your university code.';

  @override
  String get tooManyAttempts =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get dashboard => 'Dashboard';

  @override
  String get collegeAttendanceSystem => 'College Attendance System';

  @override
  String get studentDashboard => 'Student Dashboard';

  @override
  String get adminDashboard => 'Admin Dashboard';

  @override
  String get doctorDashboard => 'Doctor Dashboard';

  @override
  String get dashboardMenu => 'Dashboard Menu';

  @override
  String get welcome => 'Welcome';

  @override
  String get loadingStatistics => 'Loading statistics...';

  @override
  String get updatesAutomatically => 'Updates automatically every 30 seconds';

  @override
  String get myCourses => 'My Courses';

  @override
  String get coursesList => 'List Courses';

  @override
  String get noAccessPermission => 'No Access Permission';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get noDataAvailable => 'No Data Available';

  @override
  String get authenticationFailed => 'Authentication Failed';

  @override
  String get retry => 'Retry';

  @override
  String get doctors => 'Doctors';

  @override
  String get tas => 'TAs';

  @override
  String get students => 'Students';

  @override
  String get courses => 'Courses';

  @override
  String get staffManagement => 'Staff Management';

  @override
  String get createDoctorTA => 'Create Dr,TA';

  @override
  String get createDoctor => 'Create Doctor';

  @override
  String get createTA => 'Create Teaching Assistant';

  @override
  String get listDoctors => 'List Doctors';

  @override
  String get listTAs => 'List TAs';

  @override
  String get deleteUser => 'Delete User';

  @override
  String get createDoctorAccount => 'Create Doctor Account';

  @override
  String get createTAAccount => 'Create TA Account';

  @override
  String get createNewAccount => 'Create New Account';

  @override
  String get fillDetailsToCreate =>
      'Fill in the details to create a new account';

  @override
  String get accountCreationSteps => 'Account Creation Steps';

  @override
  String get selectAccountType =>
      'Select the Account Type (Doctor or Teaching Assistant).';

  @override
  String get enterFullName => 'Enter the full name of the staff member.';

  @override
  String get provideValidEmail => 'Provide a valid email address.';

  @override
  String get setSecurePassword =>
      'Set a secure password (minimum 6 characters).';

  @override
  String get clickCreateButton => 'Click the Create button to finalize.';

  @override
  String get accountType => 'Account Type';

  @override
  String get doctor => 'Doctor';

  @override
  String get teachingAssistant => 'Teaching Assistant';

  @override
  String get fullName => 'Full Name';

  @override
  String get enterDoctorName => 'Enter doctor name';

  @override
  String get enterTAName => 'Enter TA name';

  @override
  String get emailAddress => 'Email Address';

  @override
  String get create => 'Create';

  @override
  String get createAccount => 'Create Account';

  @override
  String get doctorAccountCreatedSuccessfully =>
      'Doctor account created successfully';

  @override
  String get taAccountCreatedSuccessfully =>
      'Teaching assistant account created successfully';

  @override
  String get exit => 'Exit';

  @override
  String get authenticationTokenNotFound => 'Authentication token not found';

  @override
  String get studentManagement => 'Student Management';

  @override
  String get bulkCreateStudents => 'Bulk Create Students';

  @override
  String get createMultipleStudents => 'Create Multiple Students';

  @override
  String get addStudentsOneByOne => 'Add students one by one or in bulk';

  @override
  String get bulkDeleteStudents => 'Bulk Delete Students';

  @override
  String get resetAccounts => 'Reset Accounts';

  @override
  String get resetAccountsPage => 'Reset Students Accounts';

  @override
  String get resetStudentsNewYear => 'Reset Students For New Year';

  @override
  String get importFromExcel => 'Import From Excel';

  @override
  String get uploadExcel => 'Upload Excel';

  @override
  String get importExcel =>
      'Upload an Excel file with a column named \"University Code\" or \"code\"';

  @override
  String get uploading => 'Uploading...';

  @override
  String get importing => 'Importing...';

  @override
  String get clearAll => 'Clear All';

  @override
  String get clear => 'Clear';

  @override
  String get addStudent => 'Add Student';

  @override
  String get addStudentManually => 'Add Student';

  @override
  String get studentName => 'Student Name';

  @override
  String get enterStudentName => 'Enter student full name';

  @override
  String get studentCode => 'Student Code';

  @override
  String get studentsToAdd => 'Students to Add';

  @override
  String get ready => 'Ready';

  @override
  String get studentAdded => 'Student added to list';

  @override
  String get pleaseAddAtLeastOne => 'Please add at least one student';

  @override
  String get pleaseFixErrors => 'Please fix all errors before adding';

  @override
  String get createStudents => 'Create Students';

  @override
  String get studentsCreatedSuccessfully => 'Students created successfully!';

  @override
  String importedStudents(int count, int skipped) {
    return 'Imported $count students, skipped $skipped rows.';
  }

  @override
  String importFailed(String error) {
    return 'Import failed: $error';
  }

  @override
  String errorCreatingStudents(String error) {
    return 'Error creating students: $error';
  }

  @override
  String get confirmDeletion => 'Confirm Deletion';

  @override
  String areYouSurDeleteUser(String code) {
    return 'Are you sure you want to delete user with code: $code?';
  }

  @override
  String get dangerZone => '⚠️ Danger Zone';

  @override
  String get thisActionCannotBeUndone =>
      'This action will permanently delete the user and all their data. This cannot be undone.';

  @override
  String get howToDeleteUser => 'How to Delete a User';

  @override
  String get howToFindUniversityCode => 'How to Find University Code';

  @override
  String get userCodeFormat =>
      'User code format: \"TA-XXXX\" for TAs, \"DR-XXXX\" for Doctors';

  @override
  String get makesurecorrectcode =>
      'Make sure you have the correct code before deleting';

  @override
  String get deletedUsersCannotRecover => 'Deleted users cannot be recovered';

  @override
  String get deleteBothDoctorsAndTAs =>
      'This deletes both doctors and teaching assistants';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteUserSuccessfully => 'User deleted successfully!';

  @override
  String get courseManagement => 'Course Management';

  @override
  String get createCourse => 'Create Course';

  @override
  String get assignStaff => 'Assign Staff';

  @override
  String get assignStaffToCourse => 'Assign Staff to Course';

  @override
  String get assignDoctorOrTA => 'Assign Doctor or TA';

  @override
  String get courseCode => 'Course Code';

  @override
  String get enterCourseCode => 'e.g., CS101';

  @override
  String get courseId => 'Course ID';

  @override
  String get enterCourseIdNumber => 'Enter course ID number';

  @override
  String get staffUniversityCode => 'Staff University Code';

  @override
  String get enterStaffUniversityCode => 'e.g., DR-XXXX or TA-XXXX';

  @override
  String get courseName => 'Course Name';

  @override
  String get enterCourseName => 'Enter course name';

  @override
  String get courseDescription => 'Course Description';

  @override
  String get enterCourseDescription => 'Enter course description';

  @override
  String get staffAssignedSuccessfully => 'Staff assigned successfully!';

  @override
  String get courseCreatedSuccessfully => 'Course created successfully!';

  @override
  String get courseDeletedSuccessfully => 'Course deleted successfully!';

  @override
  String get courseEnrollmentPage => 'Course Enrollment';

  @override
  String get enrollStudent => 'Enroll Student';

  @override
  String get enrollStudentManually => 'Single student manual registration';

  @override
  String get bulkEnrollPage => 'Bulk Enroll';

  @override
  String get bulkEnrollStudents => 'Excel import or multiple codes';

  @override
  String get studentUniversityCode => 'Student University Code';

  @override
  String get enrollmentErrorAlreadyEnrolled =>
      'Student is already enrolled in this course.';

  @override
  String get enrollmentErrorPermission =>
      'You don\'t have permission to do this.';

  @override
  String get enrollmentErrorNotFound => 'Course not found.';

  @override
  String get enrollmentErrorTooMany =>
      'Too many attempts. Please wait a moment and try again.';

  @override
  String get enrollmentErrorInvalidRequest =>
      'Invalid request. Please check your input and try again.';

  @override
  String get studentEnrolledSuccessfully => 'Student enrolled successfully!';

  @override
  String get enrollStudents => 'Enroll Students';

  @override
  String get bulkEnrollHowTo => 'Bulk Enroll How-To';

  @override
  String get bulkEnrollOption1 =>
      'Option 1: Use \"Import from Excel\" to upload a .xlsx file with a \"University Code\" column.';

  @override
  String get bulkEnrollOption2 =>
      'Option 2: Manually enter university codes one by one in the \"Add Manually\" section.';

  @override
  String get bulkEnrollOption3 => 'Review the compiled list of students below.';

  @override
  String get bulkEnrollOption4 => 'Enter the Course ID in the top field.';

  @override
  String get bulkEnrollOption5 =>
      'Click \"Enroll Students\" to finalize the registration.';

  @override
  String get bulkEnrollOption6 =>
      'A report will show which students were added, skipped, or not found.';

  @override
  String get courseEnrollmentHowTo => 'How to Enroll a Student';

  @override
  String get courseEnrollmentStep1 =>
      'Find the internal Course ID number of the target course.';

  @override
  String get courseEnrollmentStep2 =>
      'Obtain the student\'s exact University Code.';

  @override
  String get courseEnrollmentStep3 =>
      'Enter both details into the fields below.';

  @override
  String get courseEnrollmentStep4 =>
      'Click \"Enroll Student\" to finalize the registration.';

  @override
  String get pleaseBothCodes => 'Please enter both codes.';

  @override
  String get pleaseFixErrorsForm => 'Please fix the errors in the form';

  @override
  String get sessionManagement => 'Session Management';

  @override
  String get startNewSession => 'Start New Session';

  @override
  String get createSession => 'Create Session';

  @override
  String get createSessionSubtitle =>
      'Create a Lecture or Section session with GPS';

  @override
  String get stopActiveSession => 'Stop Active Session';

  @override
  String get stopActiveSessionSubtitle =>
      'Manually stop a running session by ID';

  @override
  String get viewAllSessions => 'View All Sessions';

  @override
  String get viewAllSessionsSubtitle =>
      'Lectures & Sections history · Tap to see attendees';

  @override
  String get sessionTitle => 'Session Title';

  @override
  String get enterSessionTitle => 'e.g., Chapter 4: Data Structures';

  @override
  String get sessionType => 'Session Type';

  @override
  String get lecture => 'Lecture';

  @override
  String get section => 'Section';

  @override
  String get allowedRadius => 'Allowed Radius (meters)';

  @override
  String get enterAllowedRadius => 'e.g., 50';

  @override
  String get startSession => 'Start Session';

  @override
  String get sessionStarted => 'Session started successfully!';

  @override
  String get sessionStopped => 'Session stopped successfully!';

  @override
  String get sessionResumed => 'Session resumed successfully!';

  @override
  String get sessionAlreadyRunning =>
      'There is already a running session. Do you want to continue with it?';

  @override
  String get continueAction => 'Continue';

  @override
  String get pleaseEnterSessionId => 'Please enter a Session ID';

  @override
  String get invalidSessionIdFormat => 'Invalid Session ID format';

  @override
  String get stopSession => 'Stop Session';

  @override
  String get enterSessionIdStop => 'Enter the Session ID you wish to stop:';

  @override
  String get enterSessionId => 'Session ID';

  @override
  String get sessionCreationSteps => 'Session Creation Steps';

  @override
  String get courseInformation => 'Course Information';

  @override
  String get course => 'Course';

  @override
  String get attendance => 'Attendance';

  @override
  String get registerAttendance => 'Register Attendance';

  @override
  String get scanQRCode => 'Scan QR Code';

  @override
  String get enterPINCode => 'Enter PIN Code';

  @override
  String get activeSessionOpen => 'An active session is open!';

  @override
  String get liveSession => 'Live Session';

  @override
  String get liveAttendance => 'Live Attendance';

  @override
  String get attendeesCount => 'Live Attendees Count';

  @override
  String get scanQRCodeStudentApp => 'Scan using Student App';

  @override
  String get orEnterPin => 'OR ENTER PIN';

  @override
  String get manualEntry => 'Manual Entry PIN';

  @override
  String pinAutoChangeSeconds(int seconds) {
    return 'PIN and QR automatically change every $seconds seconds';
  }

  @override
  String get fullScreen => 'Full Screen';

  @override
  String get attendanceSubmitted => 'Attendance submitted!';

  @override
  String get manualAttendance => 'Manual Attendance';

  @override
  String get enterStudentCodeManual =>
      'Enter the student\'s University Code to record attendance manually:';

  @override
  String get addStudentManual => 'Add Student';

  @override
  String get locationPermissionsDenied => 'Location permissions are denied';

  @override
  String get locationPermissionsPermanentlyDenied =>
      'Location permissions are permanently denied';

  @override
  String get networkError => 'Network error';

  @override
  String get attendanceDeletedSuccessfully => 'Attendance deleted successfully';

  @override
  String get studentAddedSuccessfully => 'Student added successfully';

  @override
  String get attendanceIsClosed => 'Attendance is Closed';

  @override
  String get reports => 'Reports';

  @override
  String get lectureReport => 'Lecture Report';

  @override
  String get lectureReportSubtitle => 'Attendance insights';

  @override
  String get sectionReport => 'Section Report';

  @override
  String get sectionReportSubtitle => 'Labs & Exercises';

  @override
  String get sessionHistory => 'Session History';

  @override
  String get sessionHistorySubtitle => 'Past sessions';

  @override
  String get absenceWarnings => 'Absence Warnings';

  @override
  String get absenceWarningsSubtitle => 'At-risk students';

  @override
  String get enrolledStudents => 'Enrolled Students';

  @override
  String get totalMarks => 'Total Marks (optional)';

  @override
  String get apply => 'Apply';

  @override
  String get code => 'Code';

  @override
  String get attended => 'Attended';

  @override
  String get absent => 'Absent';

  @override
  String totalLectures(int count) {
    return 'Total Lectures: $count';
  }

  @override
  String marks(String marks) {
    return 'Marks: $marks';
  }

  @override
  String totalSections(int count) {
    return 'Total Sections: $count';
  }

  @override
  String get exportToExcel => 'Export to Excel';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get searchByNameCode => 'Search by name or university code...';

  @override
  String get searchByNameOrCode => 'Search by name or code...';

  @override
  String studentEnrolled(int count) {
    return '$count student(s) enrolled';
  }

  @override
  String get absenceWarningsPageTitle => 'Absence Warnings';

  @override
  String get attendanceReports => 'Attendance Reports';

  @override
  String get attendanceReportsSubtitle => 'View your attendance summary';

  @override
  String get dangerYouExceededAbsenceLimit =>
      'Danger: You have exceeded the allowed absence limit (3) and may be deprived of exams.';

  @override
  String get noStudentsAttendedYet => 'No students attended yet';

  @override
  String get noSessionsFound => 'No sessions found.';

  @override
  String get noStudentsFound => 'No students found';

  @override
  String get confirmPassword => 'Confirm Password';

  @override
  String get refresh => 'Refresh';

  @override
  String get submit => 'Submit';

  @override
  String get search => 'Search';

  @override
  String get clearSearch => 'Clear Search';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get back => 'Back';

  @override
  String get close => 'Close';

  @override
  String get ok => 'OK';

  @override
  String get done => 'Done';

  @override
  String get save => 'Save';

  @override
  String get update => 'Update';

  @override
  String get updateRadius => 'Update Radius';

  @override
  String get logout => 'Logout';

  @override
  String get areYouSureLogout =>
      'Are you sure you want to logout from your account?';

  @override
  String errorStopping(String error) {
    return 'Error stopping session: $error';
  }

  @override
  String get changeAllowedScanDistance =>
      'Change the allowed scanning distance for students (in meters).';

  @override
  String meters(int count) {
    return '$count meters';
  }

  @override
  String get radiusUpdatedSuccessfully => 'Radius updated successfully!';

  @override
  String get permissionDenied => 'You don\'t have permission to do this.';

  @override
  String get invalidRequestCheckInput =>
      'Invalid request. Please check your input and try again.';

  @override
  String get noPermissionDoThis => 'You don\'t have permission to do this.';

  @override
  String get alreadyClosed => 'Session is already closed.';

  @override
  String get alreadyActive => 'This session is already active.';

  @override
  String get conflictingSession =>
      'A conflicting session already exists for this course.';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get arabic => 'العربية';

  @override
  String get assignStaffDescription =>
      'Enter the course code and the staff university code to link them together.';

  @override
  String errorAssigningStaff(String error) {
    return 'Error: $error';
  }

  @override
  String failedToConnect(String error) {
    return 'Failed to connect: $error';
  }

  @override
  String get noAttendanceRecordsFound => 'No attendance records found';

  @override
  String get noAttendanceRecords => 'No attendance records';

  @override
  String pointsString(String marks) {
    return '$marks pts';
  }

  @override
  String codeString(String code) {
    return 'Code: $code';
  }

  @override
  String get totalStudents => 'Total Students';

  @override
  String get totalCourses => 'Total Courses';

  @override
  String get noCoursesAssignedYet => 'No courses assigned yet';

  @override
  String get noCoursesMatchSearch => 'No courses match your search';

  @override
  String get reportsAndAnalytics => 'Reports & Analytics';

  @override
  String get fillRequiredCourse =>
      'Fill in all required fields to create a new course';

  @override
  String get createNewCourse => 'Create New Course';

    @override
    String get courseCreationSteps => 'Course Creation Steps';

    @override
    String get courseCreationStep1 => 'Enter a clear, descriptive name for the course.';

    @override
    String get courseCreationStep2 => 'Provide a unique Course Code (e.g., CS4710).';

    @override
    String get courseCreationStep3 =>
      'Enter the exact University Code of the Doctor assigned to this course.';

    @override
    String get courseCreationStep4 =>
      'Provide a brief description of the course contents.';

    @override
    String get courseCreationStep5 => 'Click "Create Course" to finalize.';

    @override
    String get doctorUniversityCode => 'Doctor University Code';

    @override
    String get enterDoctorUniversityCode =>
      'Enter doctor university code (e.g., DR-1234)';

    @override
    String get courseNameIsRequired => 'Course name is required';

    @override
    String get courseNameMustBeAtLeast2Chars =>
      'Course name must be at least 2 characters';

    @override
    String get courseCodeIsRequired => 'Course code is required';

    @override
    String get courseCodeMustBeAtLeast2Chars =>
      'Course code must be at least 2 characters';

    @override
    String get courseDescriptionIsRequired => 'Description is required';

    @override
    String get courseDescriptionMustBeAtLeast5Chars =>
      'Description must be at least 5 characters';

    @override
    String get doctorUniversityCodeIsRequired =>
      'Doctor University Code is required';

    @override
    String get doctorUniversityCodeMustBeValid =>
      'Please enter a valid University Code (e.g., DR-1234)';

  @override
  String get passwordRequirements => 'Password requirements:';

  @override
  String get atLeast6Chars => 'At least 6 characters';

  @override
  String get manualAdd => 'Manual Add';

  @override
  String get tryAgain => 'Try Again';

  @override
  String noSessionsFoundForType(String type) {
    return 'No $type sessions found.';
  }

  @override
  String get removeThisStudent => 'Remove this student?';

  @override
  String get errorConnectingServer => 'Error connecting to server';

  @override
  String get deleteAttendance => 'Delete Attendance';

  @override
  String get searchDoctors => 'Search doctors...';

  @override
  String get searchTAs => 'Search TAs...';

  @override
  String get autoRefreshEvery30Seconds => 'Auto-refresh every 30 seconds';

  @override
  String doctorCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count doctors',
      one: '1 doctor',
      zero: '0 doctors',
    );
    return '$_temp0';
  }

  @override
  String taCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count TAs',
      one: '1 TA',
      zero: '0 TAs',
    );
    return '$_temp0';
  }

  @override
  String get noDoctorsAvailable => 'No doctors available';

  @override
  String get noDoctorsFound => 'No doctors found';

  @override
  String get noTAsAvailable => 'No Teaching Assistants available';

  @override
  String get noTAsFound => 'No TAs found';

  @override
  String get tryDifferentSearchTerm => 'Try a different search term';

  @override
  String get generalInformation => 'General Information';

  @override
  String get doctorProfile => 'Doctor Profile';

  @override
  String get taProfile => 'Teaching Assistant Profile';

  @override
  String get doctorDeletedSuccessfully => 'Doctor deleted successfully!';

  @override
  String get taDeletedSuccessfully => 'TA deleted successfully!';

  @override
  String get cannotDeleteDoctorAssigned =>
      'Cannot delete this doctor because they are currently assigned to one or more courses. Please unassign them first.';

  @override
  String get cannotDeleteTAAssigned =>
      'Cannot delete this TA because they are currently assigned to one or more courses. Please unassign them first.';

  @override
  String confirmDeleteDoctor(String name) {
    return 'Are you sure you want to delete Dr. $name?\n\nThis will permanently remove their account and access.';
  }

  @override
  String confirmDeleteTA(String name) {
    return 'Are you sure you want to delete TA \'$name\'?\n\nThis will permanently remove their account and access.';
  }
}
