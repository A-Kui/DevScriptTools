# Requirements Document

## Introduction

DevScriptTools 是一个 macOS Shell 脚本工具，用于批量重命名 iOS 开发中的 icon 文件。设计师提供的 icon 命名通常不规范，该工具可以将文件批量重命名为统一格式，并自动处理 @2x/@3x 后缀的图片组。

**技术方案：Shell 脚本 (Bash/Zsh)**
- macOS 原生支持，无需安装任何依赖
- 脚本可放置在任意位置执行
- 通过输入目标目录路径来处理文件

## Glossary

- **Icon_Renamer**: 核心重命名脚本，负责处理文件重命名逻辑
- **Icon_Group**: 一组相关的 icon 文件，包含 @1x、@2x、@3x 三种分辨率
- **Random_Suffix**: 6位随机字符串，由大小写英文字母和数字组成
- **Scale_Suffix**: iOS 图片的分辨率后缀，如 @2x、@3x

## Requirements

### Requirement 1: 目录输入与验证

**User Story:** As a iOS developer, I want to specify a directory containing icon files from anywhere, so that I can batch process icons without moving the script.

#### Acceptance Criteria

1. THE Icon_Renamer SHALL be executable from any location, accepting an absolute or relative path to the target directory
2. WHEN the user provides a directory path, THE Icon_Renamer SHALL validate that the directory exists
3. IF the directory does not exist, THEN THE Icon_Renamer SHALL display an error message and exit gracefully
4. WHEN no directory is specified, THE Icon_Renamer SHALL prompt the user to enter a directory path
5. THE Icon_Renamer SHALL only process image files with extensions: .png, .jpg, .jpeg

### Requirement 2: Icon 名称输入

**User Story:** As a iOS developer, I want to specify a custom icon name or use auto-generated names, so that I can have consistent naming across my project.

#### Acceptance Criteria

1. WHEN the user provides an icon name, THE Icon_Renamer SHALL use that name as the base for all renamed files
2. WHEN no icon name is provided, THE Icon_Renamer SHALL generate a Random_Suffix as the base name
3. THE Random_Suffix SHALL consist of exactly 6 characters from [a-z, A-Z, 0-9]
4. WHEN renaming files, THE Icon_Renamer SHALL format output as: {name}_{random_suffix}{scale_suffix}.{extension}

### Requirement 3: Icon 分组识别

**User Story:** As a iOS developer, I want the tool to recognize icon groups by their base name, so that related @1x/@2x/@3x files are renamed together.

#### Acceptance Criteria

1. THE Icon_Renamer SHALL identify Icon_Groups by extracting the base name (removing @2x/@3x suffixes)
2. WHEN processing files, THE Icon_Renamer SHALL group files with the same base name together
3. WHEN renaming an Icon_Group, THE Icon_Renamer SHALL apply the same Random_Suffix to all files in the group
4. THE Icon_Renamer SHALL preserve the original Scale_Suffix (@2x, @3x) during renaming

### Requirement 4: 缺失文件校验

**User Story:** As a iOS developer, I want to know if any @2x or @3x variants are missing, so that I can request the missing assets from designers.

#### Acceptance Criteria

1. WHEN processing an Icon_Group, THE Icon_Renamer SHALL check for the presence of @1x, @2x, and @3x variants
2. IF any variant is missing from an Icon_Group, THEN THE Icon_Renamer SHALL report the missing variants
3. THE Icon_Renamer SHALL display a summary of all missing variants after processing
4. THE Icon_Renamer SHALL continue processing even when variants are missing

### Requirement 5: 简单命令行界面

**User Story:** As a iOS developer, I want a simple script interface, so that I can quickly rename icons from the terminal.

#### Acceptance Criteria

1. THE Icon_Renamer SHALL accept positional arguments: `./icon_rename.sh [directory] [name]`
2. WHEN both arguments are omitted, THE Icon_Renamer SHALL interactively prompt for directory path
3. THE Icon_Renamer SHALL provide clear progress output during processing
4. THE Icon_Renamer SHALL display a summary of renamed files and any missing variants
