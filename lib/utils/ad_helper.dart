import 'package:flutter/material.dart';
import '../services/admob_service.dart';

/// 广告辅助类 - 提供统一的广告展示流程
class AdHelper {
  /// 显示带加载对话框的激励视频广告
  /// 
  /// [context] 当前的BuildContext
  /// [onRewarded] 用户获得奖励后的回调
  /// [onCompleted] 广告流程完成后的回调（无论成功还是失败）
  /// [loadingText] 加载对话框显示的文字，默认为"正在加载广告..."
  static Future<void> showRewardedAdWithLoading({
    required BuildContext context,
    required Function(int rewardAmount) onRewarded,
    VoidCallback? onCompleted,
    String loadingText = '正在加载广告...',
  }) async {
    print('📺 AdHelper.showRewardedAdWithLoading 被调用');
    if (!context.mounted) {
      print('❌ Context not mounted');
      return;
    }
    
    bool isLoadingDialogOpen = true;
    print('📺 准备显示加载对话框');
    
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        print('📺 加载对话框 builder 被调用');
        // 在builder内部调用AdMob服务，确保使用正确的context
        AdMobService().showRewardedAd(
          onRewarded: (rewardAmount) {
            print('📺 AdHelper收到奖励回调: $rewardAmount');
            // 调用奖励回调
            onRewarded(rewardAmount);
          },
          onAdClosed: () {
            print('📺 AdHelper收到广告关闭回调');
            // 广告关闭后关闭加载对话框
            if (isLoadingDialogOpen && dialogContext.mounted) {
              isLoadingDialogOpen = false;
              Navigator.of(dialogContext).pop();
            }
            // 调用完成回调
            onCompleted?.call();
          },
          onAdFailed: () {
            print('📺 AdHelper收到广告失败回调');
            // 广告失败时关闭加载对话框
            if (isLoadingDialogOpen && dialogContext.mounted) {
              isLoadingDialogOpen = false;
              Navigator.of(dialogContext).pop();
            }
            
            // 显示错误提示
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('广告加载失败，请稍后再试'),
                  backgroundColor: Colors.red,
                ),
              );
            }
            
            // 调用完成回调
            onCompleted?.call();
          },
        );
        
        // 返回加载对话框UI
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                ),
                const SizedBox(height: 16),
                Text(
                  loadingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  /// 显示带加载对话框的激励视频广告（需要先关闭当前对话框的情况）
  /// 
  /// 适用于从另一个对话框触发广告的场景
  static Future<void> showRewardedAdAfterDialogClose({
    required BuildContext context,
    required Function(int rewardAmount) onRewarded,
    VoidCallback? onCompleted,
    String loadingText = '正在加载广告...',
  }) async {
    // 先关闭当前对话框
    if (context.mounted && Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    
    // 延迟一下确保对话框已关闭
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!context.mounted) return;
    
    // 调用标准的广告显示流程
    await showRewardedAdWithLoading(
      context: context,
      onRewarded: onRewarded,
      onCompleted: onCompleted,
      loadingText: loadingText,
    );
  }
}