# DevScriptTools

iOS 开发工具集合，包含图标处理相关的实用脚本。

## 环境要求
- macOS
- Bash shell

## 工具列表

### 1. Icon Rename Tool (图标重命名工具)
自动批量处理 iOS 开发中的 icon 命名规范化，支持单个文件夹或递归处理多个子文件夹。

**功能特性:**
- ✅ 递归处理多个子文件夹（默认模式）
- ✅ 支持单个文件夹直接处理模式
- ✅ 自动检测 @1x/@2x/@3x 变体并分组
- ✅ 校验缺失的变体（@2x/@3x）并提示
- ✅ 可选的文件夹重命名功能
- ✅ 自动生成随机名称或使用指定前缀
- ✅ 支持 PNG、JPG、JPEG 格式

**命令格式:**
```bash
./sh/icon_rename.sh [directory] [options]
```

**选项说明:**
- `-n, --name <name>` - 指定 icon 名称前缀（可选，默认自动生成）
- `-r, --rename-dir` - 同时重命名子文件夹（默认：否）
- `-d, --direct` - 直接处理指定目录，不递归子文件夹
- `-h, --help` - 显示帮助信息

**使用示例:**

```bash
# 1. 交互式使用（会提示输入目录）
./sh/icon_rename.sh

# 2. 处理单个文件夹下所有子目录（递归模式）
./sh/icon_rename.sh /path/to/icons

# 3. 使用指定名称前缀
./sh/icon_rename.sh /path/to/icons -n MyIcon

# 4. 同时重命名子文件夹
./sh/icon_rename.sh /path/to/icons -r

# 5. 指定名称并重命名文件夹
./sh/icon_rename.sh /path/to/icons -n AppIcon -r

# 6. 只处理单个文件夹（不递归子文件夹）
./sh/icon_rename.sh /path/to/icons/iconA -d

# 7. 使用波浪号代表用户目录
./sh/icon_rename.sh ~/Downloads/icons -n Icon
```

**处理场景示例:**

**场景1：单个文件夹**
```
输入目录结构:
icons/
├── 编组 6.png
├── 编组 6@2x.png
└── 编组 6@3x.png

执行命令: ./sh/icon_rename.sh icons -n icon -d

输出结果:
icons/
├── icon_khj9o2.png
├── icon_khj9o2@2x.png
└── icon_khj9o2@3x.png
```

**场景2：多个子文件夹（递归模式）**
```
输入目录结构:
icons/
├── iconA/
│   ├── logo.png
│   ├── logo@2x.png
│   └── logo@3x.png
├── iconB/
│   ├── image.png
│   └── image@2x.png
└── iconC/
    └── pic.png

执行命令: ./sh/icon_rename.sh icons -n MyIcon

输出结果:
icons/
├── iconA/
│   ├── MyIcon_abc123.png
│   ├── MyIcon_abc123@2x.png
│   └── MyIcon_abc123@3x.png
├── iconB/
│   ├── MyIcon_def456.png      (⚠ 缺少 @3x)
│   └── MyIcon_def456@2x.png
└── iconC/
    └── MyIcon_ghi789.png       (⚠ 缺少 @2x @3x)
```

**场景3：重命名文件夹（文件夹名与文件名统一）**
```
输入目录结构:
icons/
├── 图标A/
│   ├── icon.png
│   └── icon@2x.png
└── 图标B/
    └── logo.png

执行命令: ./sh/icon_rename.sh icons -n Icon -r

输出结果:
icons/
├── Icon_abc123/                    ← 文件夹名与文件名保持一致
│   ├── Icon_abc123.png
│   └── Icon_abc123@2x.png
└── Icon_def456/                    ← 文件夹名与文件名保持一致
    └── Icon_def456.png
```

**注意：** 使用 `-r` 选项时，文件夹会自动使用与内部文件相同的基础名称，确保命名统一。

**输出信息说明:**
- ✅ 绿色 - 成功完成
- ⚠️ 黄色 - 警告信息（如缺失变体）
- ❌ 红色 - 错误信息
- 📁 显示处理的文件夹数
- 📄 显示处理的文件总数
- 显示每个分组缺失的变体（@1x/@2x/@3x）

### 2. Icon Resize Tool (图标缩放工具)
将 APP 图标等比缩放到指定尺寸，保证最佳图片质量。

**功能特性:**
- 支持多种图片格式输入 (PNG, JPG, JPEG, GIF, BMP, TIFF)
- 等比缩放，保持图片比例
- 高质量输出 (PNG 格式)
- 支持多种尺寸指定方式

**依赖要求:**
```bash
# 安装 ImageMagick
brew install imagemagick
```

**使用示例:**
```bash
# 交互式使用
./sh/icon_resize.sh

# 缩放为正方形
./sh/icon_resize.sh icon.png 512

# 指定宽高
./sh/icon_resize.sh icon.jpg 1024x1024

# 只指定宽度，高度等比缩放
./sh/icon_resize.sh icon.png 300x

# 只指定高度，宽度等比缩放
./sh/icon_resize.sh icon.png x500

# 查看帮助
./sh/icon_resize.sh --help
```

**尺寸格式说明:**
- `100` : 缩放为 100x100 (正方形)
- `100x200` : 缩放为 100x200
- `100x` : 宽度 100，高度等比缩放
- `x200` : 高度 200，宽度等比缩放

## 快速开始

1. 克隆项目
```bash
git clone <repository-url>
cd DevScriptTools
```

2. 给脚本添加执行权限
```bash
chmod +x sh/*.sh
chmod +x test_*.sh
```

3. 运行测试脚本
```bash
# 测试图标重命名工具
./test_icon_rename.sh

# 测试图标缩放工具
./test_icon_resize.sh
```

## 文件结构
```
DevScriptTools/
├── README.md
├── sh/
│   ├── icon_rename.sh    # 图标重命名工具
│   └── icon_resize.sh    # 图标缩放工具
├── test_icon_rename.sh   # 重命名工具测试脚本
└── test_icon_resize.sh   # 缩放工具测试脚本
```

