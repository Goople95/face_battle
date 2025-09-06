import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';
import '../models/ai_personality.dart';
import '../models/drinking_state.dart';
import '../services/game_progress_service.dart';
import '../services/npc_skin_service.dart';
import '../services/cloud_npc_service.dart';
import '../services/purchase_service.dart';
import '../utils/ad_helper.dart';
import '../utils/logger_utils.dart';
import '../l10n/generated/app_localizations.dart';
import 'dart:async';

class DrunkDialog extends StatefulWidget {
  final AIPersonality personality;
  final DrinkingState drinkingState;
  final VoidCallback onSoberSuccess;
  
  const DrunkDialog({
    super.key,
    required this.personality,
    required this.drinkingState,
    required this.onSoberSuccess,
  });
  
  @override
  State<DrunkDialog> createState() => _DrunkDialogState();
}

class _DrunkDialogState extends State<DrunkDialog> {
  VideoPlayerController? _videoController;
  Timer? _timer;
  bool _isVideoInitialized = false;
  int _currentMessageIndex = 0; // 当前显示的文案索引
  
  @override
  void initState() {
    super.initState();
    // 不再自动醒酒，让VIP用户也看到对话框
    _initializeVideo();
    _startTimer();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }
  
  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          // 每3秒切换一次文案
          if (timer.tick % 3 == 0) {
            _currentMessageIndex = (_currentMessageIndex + 1) % 3; // 3句话轮流
          }
        });
      }
    });
  }
  
  Future<void> _initializeVideo() async {
    try {
      // 获取当前皮肤ID
      final skinId = NPCSkinService.instance.getSelectedSkinId(widget.personality.id);
      
      // 获取醉酒视频路径
      final videoPath = await CloudNPCService.getSmartResourcePath(
        widget.personality.id,
        'drunk.mp4',
        skinId: skinId,
      );
      
      LoggerUtils.info('加载醉酒视频: ${widget.personality.id}/drunk.mp4 (皮肤$skinId)');
      
      // 根据路径类型选择合适的控制器
      if (videoPath.startsWith('http')) {
        // 网络URL
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      } else if (videoPath.startsWith('assets/')) {
        // 本地asset资源
        _videoController = VideoPlayerController.asset(
          videoPath,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      } else {
        // 本地文件路径（缓存的文件）
        _videoController = VideoPlayerController.file(
          File(videoPath),
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: true,
            allowBackgroundPlayback: false,
          ),
        );
      }
      
      await _videoController!.initialize();
      await _videoController!.setVolume(0); // 静音播放
      await _videoController!.setLooping(true);
      await _videoController!.play();
      
      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
      }
    } catch (e) {
      LoggerUtils.error('Failed to load drunk video: $e');
    }
  }
  
  String _getFormattedSoberTime() {
    final remainingSeconds = widget.drinkingState.getAITotalSoberSeconds(widget.personality.id);
    if (remainingSeconds == 0) return '00:00';
    
    final minutes = remainingSeconds ~/ 60;
    final seconds = remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  
  String _getLocalizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    String localeCode = languageCode;
    if (languageCode == 'zh') {
      localeCode = 'zh_TW';
    }
    return widget.personality.getLocalizedName(localeCode);
  }
  
  String _getCurrentMessage(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_currentMessageIndex) {
      case 0:
        return l10n.npcDrunkMessage1; // "呜呜...我喝太多了"
      case 1:
        return l10n.npcDrunkMessage2; // "頭好暈...現在真的沒辦法陪你玩了"
      case 2:
        return l10n.npcDrunkAdHint; // "看個廣告讓我醒醒酒吧~"
      default:
        return l10n.npcDrunkMessage1;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.all(20.r),
      child: Container(
        width: screenSize.width * 0.9,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.black87,
              Colors.grey.shade900,
            ],
          ),
          border: Border.all(
            color: Colors.red.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 视频播放区域
            Container(
              height: screenSize.height * 0.35,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                color: Colors.black,
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // 视频播放器
                  if (_isVideoInitialized && _videoController != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: SizedBox(
                          width: _videoController!.value.size.width,
                          height: _videoController!.value.size.height,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                    )
                  else
                    const Center(
                      child: CircularProgressIndicator(
                        color: Colors.red,
                      ),
                    ),
                  
                  // 渐变遮罩 - 用于显示字幕
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  // 字幕文字 - 第一人称口吻，轮流显示
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        _getCurrentMessage(context),
                        key: ValueKey(_currentMessageIndex),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 4,
                              color: Colors.black,
                            ),
                          ],
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),
                  
                  // 倒计时标签
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.5),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.timer,
                            color: Colors.red.shade300,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _getFormattedSoberTime(),
                            style: TextStyle(
                              color: Colors.red.shade300,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 底部操作区域
            Container(
              padding: EdgeInsets.all(20.r),
              child: Column(
                children: [
                  // 按钮区域 - 根据是否是VIP显示不同按钮
                  Builder(
                    builder: (context) {
                      final isVIP = PurchaseService.instance.isNPCPurchased(widget.personality.id);
                      
                      if (isVIP) {
                        // VIP用户：显示单个按钮
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              // VIP直接醒酒
                              widget.drinkingState.watchAdToSoberAI(widget.personality.id);
                              widget.drinkingState.save();
                              widget.onSoberSuccess();
                              Navigator.of(context).pop();
                              // 显示VIP醒酒提示
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.of(context)!.vipFreeSober(
                                    _getLocalizedName(context)
                                  )),
                                  backgroundColor: Colors.purple,
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.purple.shade600,
                                    Colors.purple.shade900,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.stars,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    AppLocalizations.of(context)!.vipInstantSober,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      } else {
                        // 非VIP用户：显示两个按钮
                        return Row(
                          children: [
                            // 看广告醒酒按钮
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () {
                                    AdHelper.showRewardedAdAfterDialogClose(
                                      context: context,
                                      onRewarded: (rewardAmount) {
                                        widget.drinkingState.watchAdToSoberAI(widget.personality.id);
                                        widget.drinkingState.save();
                                        GameProgressService.instance.recordAdSober(npcId: widget.personality.id);
                                        widget.onSoberSuccess();
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              AppLocalizations.of(context)!.aiSoberSuccess(
                                                _getLocalizedName(context)
                                              ),
                                            ),
                                            backgroundColor: Colors.green,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 14.h),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.teal.shade700,
                                          Colors.teal.shade900,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.teal.withValues(alpha: 0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          Icons.play_circle_outline,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          AppLocalizations.of(context)!.watchAdToSober,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // 取消按钮
                            Expanded(
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: () => Navigator.of(context).pop(),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(vertical: 14.h),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.grey.shade700,
                                          Colors.grey.shade800,
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Colors.grey.shade600,
                                        width: 1,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        AppLocalizations.of(context)!.cancel,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}