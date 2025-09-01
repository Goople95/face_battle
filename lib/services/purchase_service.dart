import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/logger_utils.dart';
import 'cloud_npc_service.dart';

class PurchaseService {
  static final PurchaseService _instance = PurchaseService._internal();
  factory PurchaseService() => _instance;
  PurchaseService._internal();
  
  static PurchaseService get instance => _instance;

  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 已购买的NPC ID列表
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
    
    // 加载已购买的NPCs
    await _loadPurchasedNPCs();
    
    // 监听购买更新
    final purchaseUpdated = _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onDone: _onPurchaseDone,
      onError: _onPurchaseError,
    );
    
    // 恢复之前的购买
    await restorePurchases();
    
    LoggerUtils.info('内购服务初始化完成');
  }
  
  /// 加载已购买的NPC列表
  Future<void> _loadPurchasedNPCs() async {
    final prefs = await SharedPreferences.getInstance();
    final purchased = prefs.getStringList('purchased_npcs') ?? [];
    _purchasedNPCs.addAll(purchased);
    LoggerUtils.info('已加载已购买NPCs: $_purchasedNPCs');
  }
  
  /// 保存已购买的NPC
  Future<void> _savePurchasedNPC(String npcId) async {
    _purchasedNPCs.add(npcId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('purchased_npcs', _purchasedNPCs.toList());
    LoggerUtils.info('保存已购买NPC: $npcId');
  }
  
  /// 检查NPC是否已购买
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
    
    // 创建购买参数
    final PurchaseParam purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: null,
    );
    
    // 发起购买
    try {
      final success = await _inAppPurchase.buyNonConsumable(
        purchaseParam: purchaseParam,
      );
      
      if (!success) {
        LoggerUtils.error('购买请求失败');
        callback?.call(npcId, false, '购买请求失败');
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
          _purchaseCallback?.call(
            _getNPCIdFromProductId(purchase.productID),
            false,
            purchase.error?.message ?? '购买失败',
          );
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
    
    // 保存购买状态
    await _savePurchasedNPC(npcId);
    
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
    // 商品ID格式: vip_npc_1001
    if (productId.startsWith('vip_npc_')) {
      return productId.replaceFirst('vip_npc_', '');
    }
    return productId;
  }
  
  /// 恢复购买
  Future<void> restorePurchases() async {
    LoggerUtils.info('恢复购买...');
    
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