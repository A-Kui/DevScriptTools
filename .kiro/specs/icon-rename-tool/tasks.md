# Implementation Plan: Icon Rename Tool

## Overview

实现一个 Bash 脚本工具，用于批量重命名 iOS icon 文件。脚本将按顺序实现：参数处理 → 文件扫描分组 → 重命名 → 缺失检测。

## Tasks

- [x] 1. 创建脚本基础结构和参数处理
  - 创建 `icon_rename.sh` 文件
  - 添加 shebang 和脚本说明
  - 实现参数解析（目录路径、icon名称）
  - 实现目录存在性验证
  - 实现交互式目录输入（当未提供参数时）
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 5.1, 5.2_

- [x] 2. 实现随机后缀生成器
  - 实现 `generate_random_suffix()` 函数
  - 使用 /dev/urandom 生成6位随机字符
  - 字符集限制为 [a-zA-Z0-9]
  - _Requirements: 2.3_

- [x] 3. 实现文件扫描和分组逻辑
  - 实现 `get_base_name()` 函数提取基础名称
  - 实现 `get_scale_suffix()` 函数获取分辨率后缀
  - 实现 `get_extension()` 函数获取文件扩展名
  - 扫描目录中的 .png/.jpg/.jpeg 文件
  - 按基础名称分组文件
  - _Requirements: 1.5, 3.1, 3.2_

- [x] 4. 实现文件重命名功能
  - 实现 `rename_group()` 函数
  - 为每个分组生成统一的随机后缀
  - 按格式 `{name}_{suffix}{scale}.{ext}` 重命名
  - 保留原始的 @2x/@3x 后缀
  - 显示重命名进度
  - _Requirements: 2.1, 2.2, 2.4, 3.3, 3.4, 5.3_

- [x] 5. 实现缺失变体检测
  - 实现 `check_missing_variants()` 函数
  - 检查每个分组是否包含 @1x/@2x/@3x
  - 收集并显示缺失的变体列表
  - _Requirements: 4.1, 4.2, 4.3, 4.4_

- [x] 6. 实现结果汇总输出
  - 显示处理的文件总数
  - 显示重命名成功的文件数
  - 显示缺失变体的汇总
  - _Requirements: 5.4_

- [ ] 7. Checkpoint - 功能测试
  - 创建测试目录和测试文件
  - 测试基本重命名功能
  - 测试缺失变体检测
  - 测试边界情况（空目录、无图片文件）
  - 确保所有功能正常工作，如有问题请告知

- [*] 8. 编写自动化测试脚本
  - 创建 `test_icon_rename.sh` 测试脚本
  - 测试随机后缀格式（Property 1）
  - 测试 scale 后缀保留（Property 2）
  - 测试分组一致性（Property 3）
  - 测试缺失变体检测（Property 4）
  - 测试输出格式（Property 5）
  - _Requirements: 2.3, 2.4, 3.3, 3.4, 4.1, 4.2_

## Notes

- 任务标记 `*` 为可选任务，可跳过以快速完成核心功能
- 脚本使用纯 Bash 实现，无需外部依赖
- 所有任务按顺序执行，每个任务构建在前一个任务基础上
