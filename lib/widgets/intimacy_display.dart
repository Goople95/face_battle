import 'package:flutter/material.dart';
import '../models/intimacy_data.dart';
import '../services/intimacy_service.dart';

class IntimacyDisplay extends StatelessWidget {
  final String npcId;
  final bool showDetails;
  final VoidCallback? onTap;
  
  const IntimacyDisplay({
    super.key,
    required this.npcId,
    this.showDetails = false,
    this.onTap,
  });
  
  @override
  Widget build(BuildContext context) {
    final intimacyService = IntimacyService();
    final intimacy = intimacyService.getIntimacy(npcId);
    
    if (showDetails) {
      return _buildDetailedDisplay(context, intimacy);
    } else {
      return _buildCompactDisplay(context, intimacy);
    }
  }
  
  Widget _buildCompactDisplay(BuildContext context, IntimacyData intimacy) {
    // 始终使用粉色
    final color = Colors.pink.shade400;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.6),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.4),
            blurRadius: 6,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 不再显示图标，直接显示等级信息
          Text(
            'Lv.${intimacy.intimacyLevel}',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(
                  blurRadius: 1,
                  color: Colors.black26,
                  offset: Offset(0.5, 0.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          // 进度条
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: intimacy.levelProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }
  
  Widget _buildDetailedDisplay(BuildContext context, IntimacyData intimacy) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.2),
            _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                _getIconForLevel(intimacy.intimacyLevel),
                size: 24,
                color: _getColorForLevel(intimacy.intimacyLevel),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      intimacy.levelTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getColorForLevel(intimacy.intimacyLevel),
                      ),
                    ),
                    Text(
                      'Level ${intimacy.intimacyLevel}',
                      style: TextStyle(
                        fontSize: 12,
                        color: _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${intimacy.intimacyPoints} pts',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getColorForLevel(intimacy.intimacyLevel),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: intimacy.levelProgress,
                        minHeight: 8,
                        backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getColorForLevel(intimacy.intimacyLevel),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${(intimacy.levelProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: _getColorForLevel(intimacy.intimacyLevel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '距离下一级还需 ${intimacy.pointsToNextLevel} 点',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          if (intimacy.totalGames > 0) ...[
            const SizedBox(height: 12),
            Divider(
              color: _getColorForLevel(intimacy.intimacyLevel).withValues(alpha: 0.2),
              height: 1,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  icon: Icons.sports_esports,
                  label: '对局',
                  value: intimacy.totalGames.toString(),
                  color: _getColorForLevel(intimacy.intimacyLevel),
                ),
                _buildStatItem(
                  icon: Icons.emoji_events,
                  label: '胜利',
                  value: intimacy.wins.toString(),
                  color: Colors.green,
                ),
                _buildStatItem(
                  icon: Icons.percent,
                  label: '胜率',
                  value: '${(intimacy.winRate * 100).toInt()}%',
                  color: _getColorForLevel(intimacy.intimacyLevel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: color.withValues(alpha: 0.7)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Color _getColorForLevel(int level) {
    if (level <= 2) return Colors.blueGrey.shade400;
    if (level <= 4) return Colors.blue.shade600;
    if (level <= 6) return Colors.deepPurple.shade600;
    if (level <= 8) return Colors.orange.shade700;
    if (level <= 10) return Colors.red.shade600;
    return Colors.pink.shade600;  // 最高级别
  }
  
  IconData _getIconForLevel(int level) {
    if (level <= 2) return Icons.person_outline;
    if (level <= 4) return Icons.people_outline;
    if (level <= 6) return Icons.favorite_border;
    if (level <= 8) return Icons.favorite;
    return Icons.favorite_sharp;
  }
}