import 'package:cloud_firestore/cloud_firestore.dart';

/// 用户档案模型 - 存储在Firestore中
class UserProfile {
  final String userId;
  final DateTime accountCreatedAt;
  final DateTime lastLoginAt;
  final String loginProvider; // google/facebook
  final String? country;
  final String? language;
  final String username;
  final String displayName;
  final String email;
  final String? photoUrl;
  final bool isActive;

  UserProfile({
    required this.userId,
    required this.accountCreatedAt,
    required this.lastLoginAt,
    required this.loginProvider,
    this.country,
    this.language,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.isActive = true,
  });

  /// 从Firestore文档创建
  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      userId: doc.id,
      accountCreatedAt: (data['accountCreatedAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp).toDate(),
      loginProvider: data['loginProvider'] ?? 'unknown',
      country: data['country'],
      language: data['language'],
      username: data['username'] ?? '',
      displayName: data['displayName'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
    );
  }

  /// 转换为Firestore文档
  Map<String, dynamic> toFirestore() {
    return {
      'accountCreatedAt': Timestamp.fromDate(accountCreatedAt),
      'lastLoginAt': Timestamp.fromDate(lastLoginAt),
      'loginProvider': loginProvider,
      'country': country,
      'language': language,
      'username': username,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'isActive': isActive,
    };
  }

  /// 创建副本并更新部分字段
  UserProfile copyWith({
    DateTime? lastLoginAt,
    String? country,
    String? language,
    String? username,
    String? displayName,
    String? photoUrl,
    bool? isActive,
  }) {
    return UserProfile(
      userId: userId,
      accountCreatedAt: accountCreatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      loginProvider: loginProvider,
      country: country ?? this.country,
      language: language ?? this.language,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      email: email,
      photoUrl: photoUrl ?? this.photoUrl,
      isActive: isActive ?? this.isActive,
    );
  }
}