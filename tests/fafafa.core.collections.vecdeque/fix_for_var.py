#!/usr/bin/env python3
"""
批量修复 Test_vecdeque.pas 文件中的 for var 语法错误
"""

import re
import sys

def fix_for_var_syntax(content):
    """修复 for var 语法为传统 for 循环"""
    lines = content.split('\n')
    fixed_lines = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # 检查是否包含 for var 语法
        for_var_match = re.search(r'(\s*)for var (\w+) := (.+?) to (.+?) do', line)
        if for_var_match:
            indent = for_var_match.group(1)
            var_name = for_var_match.group(2)
            start_val = for_var_match.group(3)
            end_val = for_var_match.group(4)
            
            # 查找这个方法的变量声明部分
            # 向上查找到 'var' 关键字
            var_section_found = False
            var_insert_line = -1
            
            # 向上查找变量声明部分
            for j in range(i - 1, max(0, i - 50), -1):
                if 'var' in lines[j] and not lines[j].strip().startswith('//'):
                    var_insert_line = j
                    var_section_found = True
                    break
                elif lines[j].strip().startswith('procedure ') or lines[j].strip().startswith('function '):
                    # 如果找到了方法声明但没有找到var部分，需要添加var部分
                    break
            
            # 如果找到了var部分，检查是否已经声明了这个变量
            if var_section_found:
                var_already_declared = False
                for j in range(var_insert_line, i):
                    if f'{var_name}:' in lines[j] and 'Integer' in lines[j]:
                        var_already_declared = True
                        break
                
                # 如果变量还没有声明，添加声明
                if not var_already_declared:
                    # 在var部分的最后添加变量声明
                    for j in range(var_insert_line + 1, i):
                        if lines[j].strip() == 'begin' or lines[j].strip().startswith('begin'):
                            # 在begin之前插入变量声明
                            lines.insert(j, f'  {var_name}: Integer;')
                            i += 1  # 调整当前行号
                            break
                        elif j == i - 1:
                            # 如果到了当前行还没找到begin，在当前行之前插入
                            lines.insert(j + 1, f'  {var_name}: Integer;')
                            i += 1
                            break
            
            # 替换 for var 语法
            new_line = line.replace(f'for var {var_name} := {start_val} to {end_val} do', 
                                  f'for {var_name} := {start_val} to {end_val} do')
            fixed_lines.append(new_line)
        else:
            fixed_lines.append(line)
        
        i += 1
    
    return '\n'.join(fixed_lines)

def main():
    input_file = 'Test_vecdeque.pas'
    
    try:
        print(f"读取文件: {input_file}")
        with open(input_file, 'r', encoding='utf-8') as f:
            content = f.read()
        
        print("修复 for var 语法...")
        fixed_content = fix_for_var_syntax(content)
        
        # 备份原文件
        backup_file = input_file + '.backup'
        print(f"备份原文件到: {backup_file}")
        with open(backup_file, 'w', encoding='utf-8') as f:
            f.write(content)
        
        # 写入修复后的文件
        print(f"写入修复后的文件: {input_file}")
        with open(input_file, 'w', encoding='utf-8') as f:
            f.write(fixed_content)
        
        print("修复完成！")
        
    except Exception as e:
        print(f"错误: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
