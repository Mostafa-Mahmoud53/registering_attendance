// ignore_for_file: avoid_print
class CreateSessionDto {
  final int courseId;
  final String title;
  final String sessionType;
  final double? latitude;
  final double? longitude;
  final int allowRadius;

  CreateSessionDto({
    required this.courseId,
    required this.title,
    required this.sessionType,
    this.latitude,
    this.longitude,
    required this.allowRadius,
  });

  Map<String, dynamic> toJson() {
    return {
      'courseId': courseId,
      'title': title,
      'sessionType': sessionType,
      'latitude': latitude,
      'longitude': longitude,
      'allowRadius': allowRadius,
    };
  }

  factory CreateSessionDto.fromJson(Map<String, dynamic> json) {
    return CreateSessionDto(
      courseId: json['courseId'] as int,
      title: json['title'] as String,
      sessionType: json['sessionType'] as String,
      latitude: json['latitude'] as double?,
      longitude: json['longitude'] as double?,
      allowRadius: json['allowRadius'] as int,
    );
  }
}

class CreateSessionResponse {
  final String message;
  final int sessionId;
  final String qrContent;
  final String pinCode;
  final bool isResumed;

  CreateSessionResponse({
    required this.message,
    required this.sessionId,
    required this.qrContent,
    required this.pinCode,
    required this.isResumed,
  });

  factory CreateSessionResponse.fromJson(Map<String, dynamic> json) {
    // Support multiple possible field name conventions from the API
    final sessionId =
        json['sessionId'] as int? ??
        json['sessionid'] as int? ??
        json['id'] as int? ??
        json['session_id'] as int? ??
        0;
    final qrContent =
        json['qrContent'] as String? ??
        json['qr_content'] as String? ??
        json['qrcode'] as String? ??
        json['qr'] as String? ??
        '';
    final pinCode =
        json['pinCode'] as String? ??
        json['pin_code'] as String? ??
        json['pin'] as String? ??
        '';

    print('[CreateSessionResponse] sessionId=$sessionId  qrContent=$qrContent  pinCode=$pinCode');

    return CreateSessionResponse(
      message: json['message'] as String? ?? '',
      sessionId: sessionId,
      qrContent: qrContent,
      pinCode: pinCode,
      isResumed: json['isResumed'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'message': message,
      'sessionId': sessionId,
      'qrContent': qrContent,
      'pinCode': pinCode,
      'isResumed': isResumed,
    };
  }
}

class RotateQrResponse {
  final String newQr;
  final String newPin;

  RotateQrResponse({
    required this.newQr,
    required this.newPin,
  });

  factory RotateQrResponse.fromJson(Map<String, dynamic> json) {
    return RotateQrResponse(
      newQr: json['newQr'] as String? ?? '',
      newPin: json['newPin'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'newQr': newQr,
      'newPin': newPin,
    };
  }
}

class SubmitAttendanceDto {
  final int sessionId;
  final String deviceId;
  final double studentLatitude;
  final double studentLongitude;
  final String? scannedQrContent;
  final String? sessionPIN;

  SubmitAttendanceDto({
    required this.sessionId,
    required this.deviceId,
    required this.studentLatitude,
    required this.studentLongitude,
    this.scannedQrContent,
    this.sessionPIN,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'deviceId': deviceId,
      'studentLatitude': studentLatitude,
      'studentLongitude': studentLongitude,
      'scannedQrContent': scannedQrContent,
      'sessionPIN': sessionPIN,
    };
  }

  factory SubmitAttendanceDto.fromJson(Map<String, dynamic> json) {
    return SubmitAttendanceDto(
      sessionId: json['sessionId'] as int,
      deviceId: json['deviceId'] as String,
      studentLatitude: json['studentLatitude'] as double,
      studentLongitude: json['studentLongitude'] as double,
      scannedQrContent: json['scannedQrContent'] as String?,
      sessionPIN: json['sessionPIN'] as String?,
    );
  }
}
