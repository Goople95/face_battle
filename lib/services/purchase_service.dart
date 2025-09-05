import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';
import 'storage/cloud_storage_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();
  
  static PurchaseService get instance => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 已购买的NPC ID列表（仅用于初始数据迁移，实际数据源是GameProgressService）
  // TODO: 在确认所有用户数据迁移完成后，可以移除此本地存储
  final Set<String> _purchasedNPCs = {};
  
  // 购买回调
  Function(String npcId, bool success, String? error)? _purchaseCallback;
  
  // 商品信息缓存
  final Map<String, ProductDetails> _products = {};
  
  bool _isAvailable = false;
  bool get isAvailable => _isAvailable;
  
  /// 初始化内购服务
  Future<void> initialize() async {
    LoggerUtils.info('初始化内购服务...');
    
    // 检查内购是否可用
    _isAvailable = await _inAppPurchase.isAvailable();
    if (!_isAvailable) {
      LoggerUtils.warning('内购服务不可用');
      return;
    }
    
    // 从云端和本地同步已购买的NPCs
    await _syncPurchasedNPCs();
    
    // 监听购买更新
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseDone,
      onError: _onPurchaseError,
    );
    
    // 不自动恢复购买，以Firestore数据为准
    // 用户可以在设置中手动恢复购买（如果需要的话）
    // await restorePurchases();
    
    LoggerUtils.info('内购服务初始化完成');
  }
  
  /// 从云端加载已购买的NPCs
  Future<void> _syncPurchasedNPCs() async {
    LoggerUtils.info('从云端加载已购买的NPCs...');
    
    // 清空内存中的购买记录
    _purchasedNPCs.clear();
    
    // 只从云端获取数据
    if (CloudStorageService.instance.isUserLoggedIn) {
      final cloudPurchased = await CloudStorageService.instance.getPurchasedNPCs();
      _purchasedNPCs.addAll(cloudPurchased);
      LoggerUtils.info('云端已购买NPCs: $_purchasedNPCs');
    } else {
      LoggerUtils.warning('用户未登录，无法加载购买记录');
    }
  }
  
  /// 保存已购买的NPC（只保存到云端）
  Future<void> _savePurchasedNPC(String npcId) async {
    // 添加到内存缓存
    _purchasedNPCs.add(npcId);
    
    // 直接保存到云端（这是唯一的数据源）
    if (CloudStorageService.instance.isUserLoggedIn) {
      await CloudStorageService.instance.addPurchasedNPC(npcId);
      LoggerUtils.info('已保存购买的NPC到云端: $npcId');
    } else {
      LoggerUtils.error('用户未登录，无法保存购买记录');
      // 这种情况不应该发生，因为购买前应该已经登录
      throw Exception('用户未登录，无法保存购买记录');
    }
  }
  
  /// 用户切换时重新加载购买记录
  /// 应该在用户登录/切换账号后调用
  Future<void> reloadForCurrentUser() async {
    LoggerUtils.info('重新加载当前用户的购买记录...');
    await _syncPurchasedNPCs();
  }
  
  /// 检查NPC是否已购买（使用purchased_npcs作为单一数据源）
  bool isNPCPurchased(String npcId) {
    return _purchasedNPCs.contains(npcId);
  }
  
  /// 检查是否拥有某个项目（用于皮肤系统）
  bool hasItem(String itemId) {
    // 如果是NPC解锁项目
    if (itemId.startsWith('vip_npc_')) {
      final npcId = itemId.replaceFirst('vip_npc_', '');
      return isNPCPurchased(npcId);
    }
    // 未来可以扩展支持其他类型的项目
    return _purchasedNPCs.contains(itemId);
  }
  
  /// 获取NPC的商品信息
  Future<ProductDetails?> getProductForNPC(String npcId) async {
    if (!_isAvailable) return null;
    
    // 从云端配置获取商品ID
    final npcs = await CloudNPCService.fetchNPCConfigs();
    final npc = npcs.firstWhere(
      (n) => n.id == npcId,
      orElse: () => throw Exception('NPC $npcId not found'),
    );
    
    if (npc.unlockItemId == null) {
      LoggerUtils.warning('NPC $npcId 没有配置商品ID');
      return null;
    }
    
    // 如果已缓存，直接返回
    if (_products.containsKey(npc.unlockItemId!)) {
      return _products[npc.unlockItemId!];
    }
    
    // 查询商品信息
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
      {npc.unlockItemId!},
    );
    
    if (response.error != null) {
      LoggerUtils.error('查询商品失败: ${response.error}');
      return null;
    }
    
    if (response.productDetails.isEmpty) {
      LoggerUtils.warning('商品 ${npc.unlockItemId} 不存在');
      return null;
    }
    
    final product = response.productDetails.first;
    _products[npc.unlockItemId!] = product;
    return product;
  }
  
  /// 购买NPC
  Future<void> purchaseNPC(
    String npcId, 
    Function(String npcId, bool success, String? error)? callback,
  ) async {
    LoggerUtils.info('开始购买NPC: $npcId');
    _purchaseCallback = callback;
    
    if (!_isAvailable) {
      callback?.call(npcId, false, '内购服务不可用');
      return;
    }
    
    // 检查是否已购买
    if (isNPCPurchased(npcId)) {
      LoggerUtils.info('NPC $npcId 已经购买过了');
      callback?.call(npcId, true, null);
      return;
    }
    
    // 获取商品信息
    final product = await getProductForNPC(npcId);
    if (product == null) {
      callback?.call(npcId, false, '无法获取商品信息');
      return;
    }
    
    // 创建购买参数，绑定当前Firebase用户
    final currentUserId = CloudStorageService.instance.currentUserId;
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: currentUserId, // 将Firebase UID绑定到购买
    );
    
    // 发起购买（使用消耗品方式，允许多个用户购买）
    try {
      final success = await _inAppPurchase.buyConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (!success) {
        LoggerUtils.error('购买请求失败');
        callback?.call(npcId, false, '购买请求失败');
      } else {
        LoggerUtils.info('购买请求已发送，等待Google Play处理');
      }
    } catch (e) {
      LoggerUtils.error('购买异常: $e');
      callback?.call(npcId, false, e.toString());
    }
  }
  
  /// 处理购买更新
  void _onPurchaseUpdate(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      LoggerUtils.info('购买更新: ${purchase.productID}, 状态: ${purchase.status}');
      
      switch (purchase.status) {
        case PurchaseStatus.pending:
          // 购买进行中
          LoggerUtils.info('购买进行中: ${purchase.productID}');
          break;
          
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          // 购买成功或恢复成功
          _handleSuccessfulPurchase(purchase);
          break;
          
        case PurchaseStatus.error:
          // 购买失败
          LoggerUtils.error('购买失败: ${purchase.error}');
          final errorMessage = purchase.error?.message ?? '购买失败';
          
          // 检查是否是"已拥有"错误（通常包含"already own"或类似文字）
          if (errorMessage.toLowerCase().contains('already own') || 
              errorMessage.toLowerCase().contains('already purchased')) {
            LoggerUtils.warning('Google Play提示已拥有，但当前用户未记录此购买');
            // 可以选择：
            // 1. 提示用户使用原账号登录
            // 2. 或者为当前用户也解锁（风险：可能被滥用）
            _purchaseCallback?.call(
              _getNPCIdFromProductId(purchase.productID),
              false,
              '此商品已被其他账号购买。请使用原账号登录或联系客服。',
            );
          } else {
            _purchaseCallback?.call(
              _getNPCIdFromProductId(purchase.productID),
              false,
              errorMessage,
            );
          }
          break;
          
        case PurchaseStatus.canceled:
          // 用户取消
          LoggerUtils.info('用户取消购买: ${purchase.productID}');
          _purchaseCallback?.call(
            _getNPCIdFromProductId(purchase.productID),
            false,
            '购买已取消',
          );
          break;
      }
      
      // 完成购买流程
      if (purchase.pendingCompletePurchase) {
        _inAppPurchase.completePurchase(purchase);
      }
    }
  }
  
  /// 处理成功的购买
  Future<void> _handleSuccessfulPurchase(PurchaseDetails purchase) async {
    LoggerUtils.info('购买成功: ${purchase.productID}');
    LoggerUtils.info('购买详情 - 用户: ${purchase.purchaseID}, 状态: ${purchase.status}');
    
    // 对于消耗型商品，立即标记为已消耗
    if (purchase.status == PurchaseStatus.purchased) {
      LoggerUtils.info('处理消耗型商品购买，立即消耗: ${purchase.productID}');
    }
    
    // 检查是否是恢复购买（手动触发时才会执行到这里）
    if (purchase.status == PurchaseStatus.restored) {
      LoggerUtils.info('处理手动恢复购买: ${purchase.productID}');
      
      // 手动恢复购买时，检查是否应该恢复到当前账号
      final npcId = _getNPCIdFromProductId(purchase.productID);
      final currentUserId = CloudStorageService.instance.currentUserId;
      
      if (currentUserId == null) {
        LoggerUtils.error('用户未登录，无法恢复购买');
        return;
      }
      
      // 记录恢复的购买，让用户决定是否要恢复到当前账号
      LoggerUtils.info('恢复购买 $npcId 到用户 $currentUserId');
    }
    
    // 验证购买（这里可以添加服务器验证）
    final isValid = await _verifyPurchase(purchase);
    if (!isValid) {
      LoggerUtils.error('购买验证失败');
      _purchaseCallback?.call(
        _getNPCIdFromProductId(purchase.productID),
        false,
        '购买验证失败',
      );
      return;
    }
    
    // 获取NPC ID
    final npcId = _getNPCIdFromProductId(purchase.productID);
    
    // 保存到purchased_npcs（本地和云端）
    try {
      await _savePurchasedNPC(npcId);
      LoggerUtils.info('已保存购买的NPC $npcId');
    } catch (e) {
      LoggerUtils.error('保存购买失败: $e');
      _purchaseCallback?.call(npcId, false, '保存失败: $e');
      return;
    }
    
    // 回调成功
    _purchaseCallback?.call(npcId, true, null);
    
    LoggerUtils.info('NPC $npcId 解锁成功');
  }
  
  /// 验证购买（可以添加服务器验证）
  Future<bool> _verifyPurchase(PurchaseDetails purchase) async {
    // TODO: 实现服务器端验证
    // 这里暂时直接返回true，实际应该将receipt发送到服务器验证
    return true;
  }
  
  /// 从商品ID获取NPC ID
  String _getNPCIdFromProductId(String productId) {
    // 商品ID格式: npc_1001 或旧格式 vip_npc_1001
    if (productId.startsWith('vip_npc_')) {
      return productId.replaceFirst('vip_npc_', '');
    }
    if (productId.startsWith('npc_')) {
      return productId.replaceFirst('npc_', '');
    }
    return productId;
  }
  
  /// 手动恢复购买（用户主动触发）
  /// 可以在设置页面提供"恢复购买"按钮调用此方法
  Future<void> restorePurchases() async {
    LoggerUtils.info('用户手动触发恢复购买...');
    
    if (!_isAvailable) {
      LoggerUtils.warning('内购服务不可用，无法恢复购买');
      return;
    }
    
    try {
      await _inAppPurchase.restorePurchases();
      LoggerUtils.info('恢复购买请求已发送');
    } catch (e) {
      LoggerUtils.error('恢复购买失败: $e');
    }
  }
  
  /// 获取所有可购买的VIP NPCs及其价格
  Future<Map<String, ProductDetails>> getAllVIPProducts() async {
    if (!_isAvailable) return {};
    
    // 获取所有NPC配置
    final npcs = await CloudNPCService.fetchNPCConfigs();
    
    // 筛选出VIP NPCs的商品ID
    final productIds = <String>{};
    for (final npc in npcs) {
      if (npc.isVIP && npc.unlockItemId != null) {
        productIds.add(npc.unlockItemId!);
      }
    }
    
    if (productIds.isEmpty) {
      LoggerUtils.info('没有可购买的VIP NPC');
      return {};
    }
    
    // 查询所有商品信息
    final ProductDetailsResponse response = await _inAppPurchase.queryProductDetails(
      productIds,
    );
    
    if (response.error != null) {
      LoggerUtils.error('查询商品失败: ${response.error}');
      return {};
    }
    
    // 构建结果映射
    final result = <String, ProductDetails>{};
    for (final product in response.productDetails) {
      final npcId = _getNPCIdFromProductId(product.id);
      result[npcId] = product;
      _products[product.id] = product; // 缓存
    }
    
    return result;
  }
  
  void _onPurchaseDone() {
    LoggerUtils.info('购买流程结束');
  }
  
  void _onPurchaseError(dynamic error) {
    LoggerUtils.error('购买流程错误: $error');
  }
  
  /// 清理资源
  void dispose() {
    _subscription?.cancel();
  }
  
  /// 获取VIP特权说明
  static Map<String, dynamic> getVIPBenefits() {
    return {
      'intimacyMultiplier': 2,  // 亲密度2倍
      'freeSobering': true,      // 免费醒酒
      'noAds': true,             // 无广告
    };
  }
}