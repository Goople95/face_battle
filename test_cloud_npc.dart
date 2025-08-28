import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  print('测试Firebase Storage访问...\n');
  
  // 测试不同的URL格式
  final urls = [
    'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2Fnpc_config.json?alt=media',
    'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.firebasestorage.app/o/npcs%2Fnpc_config.json?alt=media',
    'https://storage.googleapis.com/liarsdice-fd930.appspot.com/npcs/npc_config.json',
  ];
  
  for (final url in urls) {
    print('尝试: $url');
    try {
      final response = await http.get(Uri.parse(url));
      print('状态码: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('成功! 找到 ${data['npcs']?.length ?? 0} 个NPC');
        break;
      } else {
        print('错误: ${response.body}\n');
      }
    } catch (e) {
      print('异常: $e\n');
    }
  }
  
  // 测试访问NPC资源
  print('\n测试NPC资源访问:');
  final testResource = 'https://firebasestorage.googleapis.com/v0/b/liarsdice-fd930.appspot.com/o/npcs%2F0001%2F1.png?alt=media';
  try {
    final response = await http.head(Uri.parse(testResource));
    print('0001/1.png - 状态码: ${response.statusCode}');
  } catch (e) {
    print('0001/1.png - 错误: $e');
  }
}