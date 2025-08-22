import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../utils/logger_utils.dart';

/// 统一的云端存储服务
/// 所有Firestore操作都通过此服务进行，确保数据结构一致性
class CloudStorageService {
  static CloudStorageService? _instance;
  static CloudStorageService get instance => _instance ??= CloudStorageService._();
  
  CloudStorageService._();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// 获取当前用户ID
  String? get currentUserId => FirebaseAuth.instance.currentUser?.uid;
  
  /// 检查用户是否已登录
  bool get isUserLoggedIn => currentUserId != null;
  
  /// 获取用户文档引用
  DocumentReference? getUserDocument() {
    final userId = currentUserId;
    if (userId == null) {
      LoggerUtils.warning('CloudStorageService: 用户未登录，无法获取用户文档');
      return null;
    }
    return _firestore.collection('users').doc(userId);
  }
  
  // === 用户数据操作 ===
  
  /// 保存用户主文档数据
  Future<bool> saveUserData(Map<String, dynamic> data, {bool merge = true}) async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return false;
      
      // 添加时间戳
      data['lastUpdated'] = FieldValue.serverTimestamp();
      
      if (merge) {
        await userDoc.set(data, SetOptions(merge: true));
      } else {
        await userDoc.set(data);
      }
      
      LoggerUtils.info('用户数据已保存到云端');
      return true;
    } catch (e) {
      LoggerUtils.error('保存用户数据失败: $e');
      return false;
    }
  }
  
  /// 获取用户主文档数据
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return null;
      
      final snapshot = await userDoc.get();
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      LoggerUtils.error('获取用户数据失败: $e');
      return null;
    }
  }
  
  // === 子集合操作 ===
  
  /// 保存到用户的子集合
  Future<bool> saveToSubcollection(
    String collectionName,
    String documentId,
    Map<String, dynamic> data, {
    bool merge = true,
  }) async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return false;
      
      // 添加时间戳
      data['lastUpdated'] = FieldValue.serverTimestamp();
      
      final docRef = userDoc.collection(collectionName).doc(documentId);
      
      if (merge) {
        await docRef.set(data, SetOptions(merge: true));
      } else {
        await docRef.set(data);
      }
      
      LoggerUtils.info('数据已保存到子集合 $collectionName/$documentId');
      return true;
    } catch (e) {
      LoggerUtils.error('保存到子集合失败 [$collectionName/$documentId]: $e');
      return false;
    }
  }
  
  /// 从用户的子集合获取数据
  Future<Map<String, dynamic>?> getFromSubcollection(
    String collectionName,
    String documentId,
  ) async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return null;
      
      final snapshot = await userDoc
          .collection(collectionName)
          .doc(documentId)
          .get();
      
      if (snapshot.exists) {
        return snapshot.data();
      }
      return null;
    } catch (e) {
      LoggerUtils.error('从子集合获取数据失败 [$collectionName/$documentId]: $e');
      return null;
    }
  }
  
  /// 获取子集合的所有文档
  Future<List<Map<String, dynamic>>> getAllFromSubcollection(
    String collectionName, {
    int? limit,
    String? orderBy,
    bool descending = false,
  }) async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return [];
      
      Query query = userDoc.collection(collectionName);
      
      // 添加排序
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }
      
      // 添加限制
      if (limit != null) {
        query = query.limit(limit);
      }
      
      final snapshot = await query.get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // 添加文档ID
        return data;
      }).toList();
    } catch (e) {
      LoggerUtils.error('获取子集合所有数据失败 [$collectionName]: $e');
      return [];
    }
  }
  
  /// 删除子集合中的文档
  Future<bool> deleteFromSubcollection(
    String collectionName,
    String documentId,
  ) async {
    try {
      final userDoc = getUserDocument();
      if (userDoc == null) return false;
      
      await userDoc.collection(collectionName).doc(documentId).delete();
      
      LoggerUtils.info('已删除子集合文档 $collectionName/$documentId');
      return true;
    } catch (e) {
      LoggerUtils.error('删除子集合文档失败 [$collectionName/$documentId]: $e');
      return false;
    }
  }
  
  // === 特定数据类型的便捷方法 ===
  
  /// 保存游戏进度
  Future<bool> saveGameProgress(Map<String, dynamic> progress) async {
    final userId = currentUserId;
    if (userId == null) return false;
    
    try {
      // 游戏进度保存在用户文档的gameProgress字段下，与profile和device并列
      await _firestore
          .collection('users')
          .doc(userId)
          .set({
            'gameProgress': progress,
          }, SetOptions(merge: true));
      
      LoggerUtils.info('游戏进度已同步到云端（users/$userId 文档的 gameProgress 字段）');
      return true;
    } catch (e) {
      LoggerUtils.error('保存游戏进度失败: $e');
      return false;
    }
  }
  
  /// 获取游戏进度
  Future<Map<String, dynamic>?> getGameProgress() async {
    final userId = currentUserId;
    if (userId == null) return null;
    
    try {
      // 从用户文档的gameProgress字段获取
      final userDoc = await _firestore
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null && data.containsKey('gameProgress')) {
          LoggerUtils.info('从云端加载游戏进度（users/$userId 文档的 gameProgress 字段）');
          return data['gameProgress'] as Map<String, dynamic>;
        }
      }
      
      return null;
    } catch (e) {
      LoggerUtils.error('获取游戏进度失败: $e');
      return null;
    }
  }
  
  /// 保存亲密度数据
  Future<bool> saveIntimacy(String npcId, Map<String, dynamic> intimacyData) async {
    return await saveToSubcollection('intimacy', npcId, intimacyData);
  }
  
  /// 获取亲密度数据
  Future<Map<String, dynamic>?> getIntimacy(String npcId) async {
    return await getFromSubcollection('intimacy', npcId);
  }
  
  /// 获取所有亲密度数据
  Future<List<Map<String, dynamic>>> getAllIntimacy() async {
    return await getAllFromSubcollection('intimacy');
  }
  
  // === 事务操作 ===
  
  /// 执行事务操作
  Future<T?> runTransaction<T>(
    Future<T> Function(Transaction transaction) transactionHandler,
  ) async {
    try {
      return await _firestore.runTransaction(transactionHandler);
    } catch (e) {
      LoggerUtils.error('事务执行失败: $e');
      return null;
    }
  }
  
  // === 批量操作 ===
  
  /// 批量写入操作
  Future<bool> batchWrite(
    Future<void> Function(WriteBatch batch) batchHandler,
  ) async {
    try {
      final batch = _firestore.batch();
      await batchHandler(batch);
      await batch.commit();
      LoggerUtils.info('批量写入操作成功');
      return true;
    } catch (e) {
      LoggerUtils.error('批量写入失败: $e');
      return false;
    }
  }
  
  // === 实时监听 ===
  
  /// 监听用户数据变化
  Stream<Map<String, dynamic>?> watchUserData() {
    final userDoc = getUserDocument();
    if (userDoc == null) {
      return Stream.value(null);
    }
    
    return userDoc.snapshots().map((snapshot) {
      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>?;
      }
      return null;
    });
  }
  
  /// 监听子集合变化
  Stream<List<Map<String, dynamic>>> watchSubcollection(
    String collectionName, {
    String? orderBy,
    bool descending = false,
  }) {
    final userDoc = getUserDocument();
    if (userDoc == null) {
      return Stream.value([]);
    }
    
    Query query = userDoc.collection(collectionName);
    
    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    
    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }
  
  // === 数据清理 ===
  
  /// 清除用户的所有云端数据（危险操作）
  Future<bool> clearAllUserData() async {
    final userDoc = getUserDocument();
    if (userDoc == null) return false;
    
    try {
      // 删除所有子集合
      final subcollections = ['intimacy', 'achievements', 'settings'];
      
      for (final subcollection in subcollections) {
        final docs = await userDoc.collection(subcollection).get();
        for (final doc in docs.docs) {
          await doc.reference.delete();
        }
      }
      
      // 删除主文档
      await userDoc.delete();
      
      // 删除游戏进度
      final userId = currentUserId;
      if (userId != null) {
        await _firestore.collection('gameProgress').doc(userId).delete();
      }
      
      LoggerUtils.info('已清除用户的所有云端数据');
      return true;
    } catch (e) {
      LoggerUtils.error('清除云端数据失败: $e');
      return false;
    }
  }
}