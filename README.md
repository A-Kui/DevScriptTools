# DevScriptTools

iOS 开发工具集合，包含图标处理相关的实用脚本。

## 环境要求
- macOS
- Bash shell

## 工具列表

### 1. Icon Rename Tool (图标重命名工具)
自动批量处理 Xcode 开发中的 icon 命名规范化。

**功能特性:**
- 输入指定目录
- 输入 icon 名字，如果不输入名字默认随机生成 6 位字符串（数字或英文大小写随机）
- 校验是否缺失 @2x/@3x，如果没有则打印缺失的部分列出来

**使用示例:**
```bash
# 交互式使用
./sh/icon_rename.sh

# 指定目录和名称
./sh/icon_rename.sh /path/to/icons icon
```

**处理效果:**
```
编组 6.png       →  icon_khj9o2.png
编组 6@2x.png    →  icon_khj9o2@2x.png
编组 6@3x.png    →  icon_khj9o2@3x.png
```

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

