import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import '../services/rules_service.dart';
import '../utils/logger_utils.dart';

class RulesDisplay extends StatefulWidget {
  const RulesDisplay({Key? key}) : super(key: key);

  @override
  State<RulesDisplay> createState() => _RulesDisplayState();
}

class _RulesDisplayState extends State<RulesDisplay> {
  final RulesService _rulesService = RulesService();
  List<String> _rules = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRules();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadRules();
  }

  Future<void> _loadRules() async {
    try {
      await _rulesService.initialize();
      
      final locale = Localizations.localeOf(context);
      final languageCode = locale.languageCode;
      final countryCode = locale.countryCode;
      
      String localeString = languageCode;
      if (countryCode != null && countryCode.isNotEmpty) {
        localeString = '${languageCode}_$countryCode';
      }
      
      setState(() {
        _rules = _rulesService.getRules(localeString);
        _isLoading = false;
      });
    } catch (e) {
      LoggerUtils.error('Failed to load rules: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildDiceImage(int value) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: Image.asset(
        'assets/dice/dice-$value.png',
        width: 18,
        height: 18,
        errorBuilder: (context, error, stackTrace) {
          // 如果图片不存在，显示文字
          return Container(
            width: 18,
            height: 18,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.black54),
          ),
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        );
      },
      ),
    );
  }

  Widget _buildRuleItem(String rule, int index) {
    if (index == 1) {
      // 第二条规则：将所有"1s"相关文字替换为骰子图片
      String processedRule = rule;
      
      // 先处理中文版的特殊情况，去掉「」引号
      processedRule = processedRule.replaceAll('「', '').replaceAll('」', '');
      
      // 替换所有出现的"1s"或相关文字为占位符
      if (rule.contains('1s are')) {
        // 英文版 - 替换所有 "1s"
        processedRule = processedRule.replaceAll('1s', '🎲1🎲');
      } else if (rule.contains('Los unos')) {
        // 西班牙语 - 替换 "unos"
        processedRule = processedRule.replaceAll('unos', '🎲1🎲');
      } else if (rule.contains('Os 1s')) {
        // 葡萄牙语 - 替换所有 "1s"
        processedRule = processedRule.replaceAll('1s', '🎲1🎲');
      } else if (rule.contains('點數')) {
        // 繁体中文 - 替换 "點數 1" 和单独的 "1"
        processedRule = processedRule.replaceFirst(RegExp(r'點數\s*1'), '🎲1🎲');
        processedRule = processedRule.replaceAll(RegExp(r'(?:叫|「)1(?:」|為)'), '叫🎲1🎲為');
      } else if (rule.contains('Angka 1')) {
        // 印尼语 - 替换所有 "1"
        processedRule = processedRule.replaceAll('Angka 1', 'Angka 🎲1🎲');
        processedRule = processedRule.replaceAll('angka 1', 'angka 🎲1🎲');
      }
      
      // 使用 Text.rich 和 WidgetSpan 来内联显示骰子
      List<InlineSpan> spans = [];
      if (processedRule.contains('🎲1🎲')) {
        final segments = processedRule.split('🎲1🎲');
        for (int i = 0; i < segments.length; i++) {
          if (segments[i].isNotEmpty) {
            spans.add(TextSpan(
              text: segments[i],
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ));
          }
          if (i < segments.length - 1) {
            spans.add(WidgetSpan(
              alignment: PlaceholderAlignment.middle,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 2.w),
                child: Image.asset(
                  'assets/dice/dice-1.png',
                  width: 16,
                  height: 16,
                ),
              ),
            ));
          }
        }
      } else {
        spans.add(TextSpan(
          text: processedRule,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ));
      }
      
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '2. ',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(children: spans),
              ),
            ),
          ],
        ),
      );
    } else if (index == 4) {
      // 第五条规则：简化显示，只显示骰子顺序
      List<Widget> parts = [];
      parts.add(_buildDiceImage(1));
      parts.add(const Text(' > ', style: TextStyle(fontSize: 14, color: Colors.white70)));
      parts.add(_buildDiceImage(6));
      parts.add(const Text(' > ', style: TextStyle(fontSize: 14, color: Colors.white70)));
      parts.add(_buildDiceImage(5));
      parts.add(const Text(' > ', style: TextStyle(fontSize: 14, color: Colors.white70)));
      parts.add(_buildDiceImage(4));
      parts.add(const Text(' > ', style: TextStyle(fontSize: 14, color: Colors.white70)));
      parts.add(_buildDiceImage(3));
      parts.add(const Text(' > ', style: TextStyle(fontSize: 14, color: Colors.white70)));
      parts.add(_buildDiceImage(2));
      
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '5. ',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: parts,
              ),
            ),
          ],
        ),
      );
    } else {
      // 其他规则直接显示文字
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 4.h),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${index + 1}. ',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            Expanded(
              child: Text(
                rule,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < _rules.length; i++)
          _buildRuleItem(_rules[i], i),
      ],
    );
  }
}