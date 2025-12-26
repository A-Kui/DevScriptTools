# Design Document: Icon Rename Tool

## Overview

Icon Rename Tool 是一个 Shell 脚本，用于批量重命名 iOS 开发中的 icon 文件。脚本采用纯 Bash 实现，无需任何外部依赖，可在 macOS 上直接运行。

核心流程：
1. 接收目录路径和可选的 icon 名称
2. 扫描目录中的图片文件
3. 按基础名称分组（识别 @2x/@3x 后缀）
4. 为每组生成统一的新名称
5. 执行重命名并报告缺失的分辨率变体

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    icon_rename.sh                        │
├─────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐  │
│  │   Input     │  │   Core      │  │    Output       │  │
│  │   Handler   │──│   Processor │──│    Reporter     │  │
│  └─────────────┘  └─────────────┘  └─────────────────┘  │
│        │                │                   │           │
│        ▼                ▼                   ▼           │
│  - 参数解析        - 文件扫描          - 进度显示       │
│  - 目录验证        - 分组识别          - 缺失报告       │
│  - 交互提示        - 随机后缀生成      - 结果汇总       │
│                    - 文件重命名                         │
└─────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Input Handler

负责处理用户输入和参数验证。

```bash
# 参数解析
# $1 - 目录路径 (可选)
# $2 - icon 名称 (可选)

parse_arguments() {
    local dir="$1"
    local name="$2"
    
    # 如果未提供目录，交互式提示
    if [[ -z "$dir" ]]; then
        read -p "请输入目录路径: " dir
    fi
    
    # 验证目录存在
    if [[ ! -d "$dir" ]]; then
        echo "错误: 目录不存在 - $dir"
        exit 1
    fi
    
    echo "$dir" "$name"
}
```

### 2. Random Suffix Generator

生成6位随机字符串。

```bash
generate_random_suffix() {
    # 使用 /dev/urandom 生成随机字符
    # 字符集: a-z, A-Z, 0-9
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | head -c 6
}
```

### 3. File Scanner & Grouper

扫描目录并按基础名称分组。

```bash
# 提取基础名称 (移除 @2x/@3x 后缀)
get_base_name() {
    local filename="$1"
    # 移除扩展名
    local name="${filename%.*}"
    # 移除 @2x/@3x 后缀
    name="${name%@2x}"
    name="${name%@3x}"
    echo "$name"
}

# 获取 scale 后缀
get_scale_suffix() {
    local filename="$1"
    local name="${filename%.*}"
    if [[ "$name" == *"@3x" ]]; then
        echo "@3x"
    elif [[ "$name" == *"@2x" ]]; then
        echo "@2x"
    else
        echo ""  # @1x 没有后缀
    fi
}
```

### 4. File Renamer

执行文件重命名操作。

```bash
rename_file() {
    local old_path="$1"
    local new_name="$2"
    local dir=$(dirname "$old_path")
    local new_path="$dir/$new_name"
    
    mv "$old_path" "$new_path"
    echo "✓ $(basename "$old_path") → $new_name"
}
```

### 5. Missing Variant Checker

检查并报告缺失的分辨率变体。

```bash
check_missing_variants() {
    local base_name="$1"
    local dir="$2"
    local ext="$3"
    local missing=()
    
    # 检查 @1x
    if [[ ! -f "$dir/${base_name}.${ext}" ]]; then
        missing+=("@1x")
    fi
    # 检查 @2x
    if [[ ! -f "$dir/${base_name}@2x.${ext}" ]]; then
        missing+=("@2x")
    fi
    # 检查 @3x
    if [[ ! -f "$dir/${base_name}@3x.${ext}" ]]; then
        missing+=("@3x")
    fi
    
    echo "${missing[@]}"
}
```

## Data Models

### Icon Group 数据结构

使用关联数组存储分组信息：

```bash
# 关联数组: base_name -> "file1|file2|file3"
declare -A icon_groups

# 示例数据:
# icon_groups["编组 6"]="编组 6.png|编组 6@2x.png|编组 6@3x.png"
```

### 重命名映射

```bash
# 输入文件名 -> 输出文件名
# 编组 6.png      -> icon_khj9o2.png
# 编组 6@2x.png   -> icon_khj9o2@2x.png
# 编组 6@3x.png   -> icon_khj9o2@3x.png
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Random Suffix Format

*For any* generated random suffix, it SHALL consist of exactly 6 characters, and each character SHALL be from the set [a-zA-Z0-9].

**Validates: Requirements 2.3**

### Property 2: Scale Suffix Preservation

*For any* input file with a scale suffix (@2x or @3x), the renamed output file SHALL preserve the same scale suffix in the same position (before the extension).

**Validates: Requirements 3.4**

### Property 3: Group Consistency

*For any* Icon_Group (files sharing the same base name), all files in the group SHALL be renamed with the same random suffix.

**Validates: Requirements 3.3**

### Property 4: Missing Variant Detection

*For any* Icon_Group, if any of the three variants (@1x, @2x, @3x) is missing, the system SHALL report exactly which variants are missing.

**Validates: Requirements 4.1, 4.2**

### Property 5: Output Format Consistency

*For any* renamed file, the output filename SHALL follow the format: `{name}_{random_suffix}{scale_suffix}.{extension}`.

**Validates: Requirements 2.4**

## Error Handling

| 错误场景 | 处理方式 |
|---------|---------|
| 目录不存在 | 显示错误信息，退出脚本 (exit 1) |
| 目录为空 | 显示提示信息，正常退出 |
| 无图片文件 | 显示提示信息，正常退出 |
| 文件重命名失败 | 显示错误信息，继续处理其他文件 |
| 权限不足 | 显示错误信息，退出脚本 |

## Testing Strategy

### 手动测试用例

由于是 Shell 脚本，主要通过手动测试验证：

1. **基本功能测试**
   - 创建测试目录，包含 `test.png`, `test@2x.png`, `test@3x.png`
   - 运行脚本，验证重命名结果

2. **缺失变体测试**
   - 创建只有 `test.png`, `test@2x.png` 的目录
   - 验证脚本报告 `@3x` 缺失

3. **多组文件测试**
   - 创建多组 icon 文件
   - 验证每组使用不同的随机后缀

4. **边界情况测试**
   - 空目录
   - 无图片文件的目录
   - 文件名包含特殊字符

### 自动化测试脚本

可创建 `test_icon_rename.sh` 进行自动化验证：

```bash
#!/bin/bash
# 创建临时测试目录
# 运行脚本
# 验证输出文件名格式
# 清理测试目录
```
