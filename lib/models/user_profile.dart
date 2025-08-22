import 'package:cloud_firestore/cloud_firestore.dart';

/// 用户档案模型 - 仅包含基本信息，存储在Firestore users集合中
class UserProfile {
  // 基本信息
  final String userId;
  final String email;
  final String displayName;
  final String? photoUrl;
  
  // 账号信息
  final DateTime accountCreatedAt;
  final DateTime lastLoginAt;
  final String loginMethod;      // google/facebook
  final String userType;         // normal/internal (普通用户/内部团队)
  
  // 语言设置
  final String? deviceLanguage;         // 设备系统语言（每次登录时更新）
  final String? userSelectedLanguage;   // 用户手动选择的语言（在设置界面选择）
  
  // 应用信息
  final String? appVersion;             // 当前应用版本（每次登录时更新）
  
  // 地理位置信息
  final String? country;          // 国家名称
  final String? countryCode;      // 国家代码 (如 CN, US, GB)
  final String? region;           // 省/州 (如 California, 广东省)
  final String? city;             // 城市 (如 San Francisco, 深圳)
  final String? timezone;         // 时区 (如 America/Los_Angeles, Asia/Shanghai)
  final String? utcOffset;        // UTC偏移 (如 UTC+8, UTC-5)
  final String? isp;              // 运营商 (如 AT&T, China Telecom)

  UserProfile({
    required this.userId,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.accountCreatedAt,
    required this.lastLoginAt,
    required this.loginMethod,
    this.userType = 'normal',
    this.deviceLanguage,
    this.userSelectedLanguage,
    this.country,
    this.countryCode,
    this.region,
    this.city,
    this.timezone,
    this.utcOffset,
    this.isp,
    this.appVersion,
  });

  /// 从Firestore文档创建
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Player',
      photoUrl: data['photoUrl'],
      accountCreatedAt: data['accountCreatedAt'] != null 
          ? (data['accountCreatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
      loginMethod: data['loginMethod'] ?? 'unknown',
      userType: data['userType'] ?? 'normal',
      deviceLanguage: data['deviceLanguage'],
      userSelectedLanguage: data['userSelectedLanguage'],
      country: data['country'],
      countryCode: data['countryCode'],
      region: data['region'],
      city: data['city'],
      timezone: data['timezone'],
      utcOffset: data['utcOffset'],
      isp: data['isp'],
      appVersion: data['appVersion'],
    );
  }
  
  /// 从Map创建（用于从profile字段读取）
  factory UserProfile.fromMap(Map<String, dynamic> data) {
    return UserProfile(
      userId: data['userId'] ?? '',
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? 'Player',
      photoUrl: data['photoUrl'],
      accountCreatedAt: data['accountCreatedAt'] is Timestamp 
          ? (data['accountCreatedAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLoginAt: data['lastLoginAt'] is Timestamp
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : DateTime.now(),
      loginMethod: data['loginMethod'] ?? 'unknown',
      userType: data['userType'] ?? 'normal',
      deviceLanguage: data['deviceLanguage'],
      userSelectedLanguage: data['userSelectedLanguage'],
      country: data['country'],
      countryCode: data['countryCode'],
      region: data['region'],
      city: data['city'],
      timezone: data['timezone'],
      utcOffset: data['utcOffset'],
      isp: data['isp'],
      appVersion: data['appVersion'],
    );
  }

  /// 转换为Firestore文档
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'accountCreatedAt': Timestamp.fromDate(accountCreatedAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'loginMethod': loginMethod,
      'userType': userType,
      'deviceLanguage': deviceLanguage,
      'userSelectedLanguage': userSelectedLanguage,
      'country': country,
      'countryCode': countryCode,
      'region': region,
      'city': city,
      'timezone': timezone,
      'utcOffset': utcOffset,
      'isp': isp,
      'appVersion': appVersion,
    };
  }

  /// 创建副本并更新部分字段
  /// 获取有效的语言设置（优先用户选择，其次设备语言，最后默认英语）
  String getEffectiveLanguage() {
    return userSelectedLanguage ?? deviceLanguage ?? 'en';
  }
  
  /// 是否为内部团队成员
  bool get isInternalUser => userType == 'internal';
  
  /// 是否为普通用户
  bool get isNormalUser => userType == 'normal';

  UserProfile copyWith({
    DateTime? lastLoginAt,
    String? displayName,
    String? photoUrl,
    String? deviceLanguage,
    String? userSelectedLanguage,
    String? country,
    String? countryCode,
    String? region,
    String? city,
    String? timezone,
    String? utcOffset,
    String? isp,
    String? appVersion,
  }) {
    return UserProfile(
      userId: userId,
      email: email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      accountCreatedAt: accountCreatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      loginMethod: loginMethod,
      userType: userType,
      deviceLanguage: deviceLanguage ?? this.deviceLanguage,
      userSelectedLanguage: userSelectedLanguage ?? this.userSelectedLanguage,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      region: region ?? this.region,
      city: city ?? this.city,
      timezone: timezone ?? this.timezone,
      utcOffset: utcOffset ?? this.utcOffset,
      isp: isp ?? this.isp,
      appVersion: appVersion ?? this.appVersion,
    );
  }
}