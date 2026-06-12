// api_service.dart — All Developer 2 endpoints with correct URLs from Swagger
import 'dart:convert';
import 'package:registering_attendance/core/http_interceptor.dart' as http;

class ApiService {
  static const String baseUrl = 'http://msngroup-001-site1.ktempurl.com/api';

  static const String sessionExpiredMessage =
      'Your session has expired. Please log in again.';
  static const String noInternetMessage =
      'No internet connection. Check your network.';
  static const String timeoutMessage =
      'Request timed out. Please try again.';
  static const String serverErrorMessage =
      'Server error. Please try again later.';

  static String loginErrorMessage(int statusCode) {
    if (statusCode == 401) {
      return 'Invalid Email OR Password.';
    }
    if (statusCode == 400) {
      return 'Account not activated yet, or you are using an unauthorized device.';
    }
    if (statusCode == 404) {
      return 'Account not found. Check your university code.';
    }
    if (statusCode == 429) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  static String activationErrorMessage(int statusCode) {
    if (statusCode == 404) {
      return 'This email is not registered in the system. Please contact Student Affairs.';
    }
    if (statusCode == 400) {
      return 'Invalid university code, weak password, or account is already activated.';
    }
    if (statusCode == 429) {
      return 'Too many activation attempts. Please wait a moment.';
    }
    if (statusCode == 401) {
      return 'Unauthorized request. Please try again.';
    }
    if (statusCode == 409) {
      return 'Account already activated.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  static String createDoctorTaErrorMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Email already exists, or invalid input data. Please check and try again.';
    }
    if (statusCode == 401 || statusCode == 403) {
      return 'Unauthorized. Your session may have expired.';
    }
    if (statusCode == 409) {
      return 'Email already exists.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  static String createCourseErrorMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
    }
    if (statusCode == 401) {
      return sessionExpiredMessage;
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  static String deleteUserErrorMessage(int statusCode) {
    if (statusCode == 404) {
      return 'User not found.';
    }
    if (statusCode == 401) {
      return sessionExpiredMessage;
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String deleteCourseErrorMessage(int statusCode) {
    if (statusCode == 404) {
      return 'Course not found.';
    }
    if (statusCode == 401) {
      return sessionExpiredMessage;
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    if (statusCode == 400) {
      return 'Invalid request. Please check your input and try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  static String attendanceSubmitErrorMessage(int statusCode) {
    if (statusCode == 400) {
      return 'Cannot submit attendance — session may be closed or already submitted.';
    }
    if (statusCode == 401) {
      return sessionExpiredMessage;
    }
    if (statusCode == 403) {
      return "You don't have permission to do this.";
    }
    if (statusCode == 404) {
      return 'Session or student not found.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  static String sessionActionErrorMessage(
    int statusCode, {
    required bool isResume,
  }) {
    if (statusCode == 400) {
      return isResume
          ? 'This session is already active.'
          : 'This session is already stopped.';
    }
    if (statusCode == 401) {
      return sessionExpiredMessage;
    }
    if (statusCode == 403) {
      return "You don't have permission to do this.";
    }
    if (statusCode == 404) {
      return 'Session not found.';
    }
    if (statusCode >= 500 && statusCode <= 599) {
      return serverErrorMessage;
    }
    return 'Something went wrong. Please try again.';
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> activateAccount({
    required String universityEmail,
    required String universityCode,
    required String newPassword,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/activate'),
      headers: {'accept': '*/*', 'Content-Type': 'application/json'},
      body: jsonEncode({
        "universityEmail": universityEmail,
        "universityCode": universityCode,
        "newPassword": newPassword,
        "deviceId": deviceId,
      }),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Auth/Login'),
      headers: {'accept': '*/*', 'Content-Type': 'application/json'},
      body: jsonEncode({"email": email, "password": password, "deviceId": deviceId}),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // ─── Course — Developer 2 ──────────────────────────────────────────────────

  /// GET /Course/number-of-enrolled-students/{courseId}
  /// Doctor / TA / Admin
  static Future<Map<String, dynamic>> getEnrolledCount({
    required String courseId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Course/number-of-enrolled-students/$courseId'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// GET /Course/get-enrolled-students/{courseId}?search=
  /// Doctor / TA / Admin
  static Future<Map<String, dynamic>> getEnrolledStudents({
    required String courseId,
    required String token,
    String? search,
  }) async {
    String url = '$baseUrl/Course/get-enrolled-students/$courseId';
    if (search != null && search.isNotEmpty) url += '?search=${Uri.encodeComponent(search)}';
    final response = await http.get(
      Uri.parse(url),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // ─── Attendance Reports — Developer 2 ─────────────────────────────────────

  /// GET /Attendance/lecture-report/{courseId}?totalMarks=
  /// Doctor only
  static Future<Map<String, dynamic>> getLectureReport({
    required String courseId,
    required String token,
    String? totalMarks,
  }) async {
    String url = '$baseUrl/Attendance/lecture-report/$courseId';
    if (totalMarks != null && totalMarks.isNotEmpty) url += '?totalMarks=$totalMarks';
    final response = await http.get(
      Uri.parse(url),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// GET /Attendance/section-report/{courseId}?totalMarks=
  /// Doctor or TA
  static Future<Map<String, dynamic>> getSectionReport({
    required String courseId,
    required String token,
    String? totalMarks,
  }) async {
    String url = '$baseUrl/Attendance/section-report/$courseId';
    if (totalMarks != null && totalMarks.isNotEmpty) url += '?totalMarks=$totalMarks';
    final response = await http.get(
      Uri.parse(url),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// GET /Attendance/absence-warnings/{courseId}
  /// Doctor only
  static Future<Map<String, dynamic>> getAbsenceWarnings({
    required String courseId,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Attendance/absence-warnings/$courseId'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// GET /Attendance/session-attendees/{sessionId}?search=
  /// Doctor / TA / Admin
  static Future<Map<String, dynamic>> getSessionAttendees({
    required String sessionId,
    required String token,
    String? search,
  }) async {
    String url = '$baseUrl/Attendance/session-attendees/$sessionId';
    if (search != null && search.isNotEmpty) url += '?search=${Uri.encodeComponent(search)}';
    final response = await http.get(
      Uri.parse(url),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // ─── Session History — Developer 2 ────────────────────────────────────────

  /// GET /Session/course-sessions/{courseId}/{type}
  /// type = "Lecture" | "Section"
  static Future<Map<String, dynamic>> getCourseSessions({
    required String courseId,
    required String token,
    required String type, // "Lecture" or "Section"
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Session/course-sessions/$courseId/$type'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // ─── Session Management — Doctor/TA ───────────────────────────────────────

  /// POST /Session/create
  static Future<Map<String, dynamic>> createSession({
    required String token,
    required int courseId,
    required String title,
    required String sessionType, // "Lecture" | "Section"
    required double latitude,
    required double longitude,
    int allowRadius = 50,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Session/create'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        "courseId": courseId,
        "title": title,
        "sessionType": sessionType,
        "latitude": latitude,
        "longitude": longitude,
        "allowRadius": allowRadius,
      }),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// PUT /Session/stop/{sessionId}
  static Future<Map<String, dynamic>> stopSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Session/stop/$sessionId'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  /// PUT /Session/resume/{sessionId}
  static Future<Map<String, dynamic>> resumeSession({
    required String token,
    required String sessionId,
  }) async {
    final response = await http.put(
      Uri.parse('$baseUrl/Session/resume/$sessionId'),
      headers: {'accept': '*/*', 'Authorization': 'Bearer $token'},
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  // ─── Admin Operations ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> resetStudentAccount({
    required String code,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Admin/reset-student-account'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(code),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> deleteUser({
    required String userCode,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Admin/delete-user/$userCode'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> deleteCourse({
    required int courseId,
    required String token,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/Admin/delete-course/$courseId'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> bulkDeleteStudents({
    required List<String> codes,
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Admin/bulk-delete-students'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(codes),
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> resetSystemForNewYear({
    required String token,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/Admin/reset-system-for-new-year'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }

  static Future<Map<String, dynamic>> getAdminStatistic({
    required String endpoint,
    required String token,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/Admin/$endpoint'),
      headers: {
        'accept': '*/*',
        'Authorization': 'Bearer $token',
      },
    );
    return {'statusCode': response.statusCode, 'body': response.body};
  }
}

