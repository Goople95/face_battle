#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re

def analyze_api_calls(log_file):
    """分析log文件中的API调用，统计prompt和response的字符数和估算token数"""
    
    with open(log_file, 'r', encoding='utf-8', errors='ignore') as f:
        lines = f.readlines()
    
    # 查找prompt和response的位置
    prompt_starts = []
    response_starts = []
    
    for i, line in enumerate(lines):
        if 'Prompt内容:' in line:
            prompt_starts.append(i)
        elif 'API响应:' in line:
            response_starts.append(i)
    
    print(f"找到 {len(prompt_starts)} 个API调用\n")
    
    prompts = []
    responses = []
    
    # 提取每个prompt的内容
    for idx, start in enumerate(prompt_starts):
        # 找到这个prompt对应的结束位置（下一个日志条目或响应开始）
        end = len(lines)
        for j in range(start + 1, len(lines)):
            if '└───' in lines[j] or '┌───' in lines[j]:
                end = j
                break
        
        # 提取prompt内容
        prompt_text = []
        for j in range(start + 1, end):
            # 移除ANSI颜色代码和格式符号
            line = lines[j]
            line = re.sub(r'\[38;5;\d+m', '', line)
            line = re.sub(r'\[0m', '', line)
            line = re.sub(r'I/flutter \(\d+\): ', '', line)
            line = line.replace('│  ', '').strip()
            if line:
                prompt_text.append(line)
        
        prompts.append('\n'.join(prompt_text))
    
    # 提取每个response的内容
    for idx, start in enumerate(response_starts):
        # 找到这个response对应的结束位置
        end = len(lines)
        for j in range(start + 1, len(lines)):
            if '└───' in lines[j] or '┌───' in lines[j]:
                end = j
                break
        
        # 提取response内容
        response_text = []
        for j in range(start + 1, end):
            # 移除ANSI颜色代码和格式符号
            line = lines[j]
            line = re.sub(r'\[38;5;\d+m', '', line)
            line = re.sub(r'\[0m', '', line)
            line = re.sub(r'I/flutter \(\d+\): ', '', line)
            line = line.replace('│  ', '').strip()
            if line:
                response_text.append(line)
        
        responses.append('\n'.join(response_text))
    
    # 统计分析
    print("=" * 70)
    print("API调用统计分析")
    print("=" * 70)
    
    total_prompt_chars = 0
    total_response_chars = 0
    total_prompt_tokens = 0
    total_response_tokens = 0
    
    for i, (prompt, response) in enumerate(zip(prompts, responses)):
        prompt_chars = len(prompt)
        response_chars = len(response)
        
        # 估算token数（粗略估算）
        # 中文大约1-2个字符一个token，英文大约4个字符一个token
        # 这里简单估算：中文按1.5字符/token，混合内容按2字符/token
        prompt_tokens = estimate_tokens(prompt)
        response_tokens = estimate_tokens(response)
        
        total_prompt_chars += prompt_chars
        total_response_chars += response_chars
        total_prompt_tokens += prompt_tokens
        total_response_tokens += response_tokens
        
        print(f"\n调用 #{i+1}:")
        print(f"  Prompt:  {prompt_chars:6} 字符, 约 {prompt_tokens:4} tokens")
        print(f"  Response: {response_chars:6} 字符, 约 {response_tokens:4} tokens")
        print(f"  比例: Response/Prompt = {response_chars/prompt_chars:.2f} (字符), {response_tokens/prompt_tokens:.2f} (tokens)")
    
    # 总体统计
    print("\n" + "=" * 70)
    print("总体统计")
    print("=" * 70)
    print(f"总Prompt字符数:   {total_prompt_chars:8} 字符")
    print(f"总Response字符数: {total_response_chars:8} 字符")
    print(f"总Prompt tokens:   约 {total_prompt_tokens:6} tokens")
    print(f"总Response tokens: 约 {total_response_tokens:6} tokens")
    print(f"\n平均每次调用:")
    print(f"  Prompt:   {total_prompt_chars/len(prompts):.0f} 字符, 约 {total_prompt_tokens/len(prompts):.0f} tokens")
    print(f"  Response: {total_response_chars/len(responses):.0f} 字符, 约 {total_response_tokens/len(responses):.0f} tokens")
    print(f"\n整体比例:")
    print(f"  Response/Prompt = {total_response_chars/total_prompt_chars:.2f} (字符)")
    print(f"  Response/Prompt = {total_response_tokens/total_prompt_tokens:.2f} (tokens)")
    
    # 输出样本以验证提取正确
    print("\n" + "=" * 70)
    print("第一个Prompt样本（前500字符）:")
    print("=" * 70)
    if prompts:
        print(prompts[0][:500])
    
    print("\n" + "=" * 70)
    print("第一个Response样本:")
    print("=" * 70)
    if responses:
        print(responses[0])

def estimate_tokens(text):
    """估算文本的token数量"""
    # 统计中文字符数
    chinese_chars = len(re.findall(r'[\u4e00-\u9fff]', text))
    # 统计英文和其他字符
    other_chars = len(text) - chinese_chars
    
    # 中文约1.5字符/token，英文约3.5字符/token
    # 这是基于GPT的tokenizer的粗略估算
    chinese_tokens = chinese_chars / 1.5
    other_tokens = other_chars / 3.5
    
    return int(chinese_tokens + other_tokens)

if __name__ == "__main__":
    log_file = r"D:\projects\CompeteWithAI\face_battle\logs\flutter_debug_2025-08-13_103131.txt"
    analyze_api_calls(log_file)