#!/bin/bash
#
# Icon Resize Tool
# 用于将 APP 图标等比缩放到指定尺寸
#
# 使用方法:
#   ./icon_resize.sh [icon_path] [target_size]
#
# 参数:
#   icon_path   - 图标文件路径 (可选，未提供时交互式输入)
#   target_size - 目标尺寸，格式: 宽x高 或 单一数值 (可选，未提供时交互式输入)
#
# 支持的文件格式: .png, .jpg, .jpeg, .gif, .bmp, .tiff
# 输出格式: PNG (保证最佳质量)
#

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 全局变量
INPUT_FILE=""
TARGET_SIZE=""
OUTPUT_FILE=""

# 打印错误信息
print_error() {
    echo -e "${RED}错误: $1${NC}" >&2
}

# 打印成功信息
print_success() {
    echo -e "${GREEN}$1${NC}"
}

# 打印警告信息
print_warning() {
    echo -e "${YELLOW}$1${NC}"
}

# 打印信息
print_info() {
    echo -e "${BLUE}$1${NC}"
}

# 检查依赖工具
check_dependencies() {
    local missing_tools=()
    
    # 检查 ImageMagick
    if ! command -v convert >/dev/null 2>&1; then
        missing_tools+=("ImageMagick (convert)")
    fi
    
    # 检查 identify (ImageMagick 的一部分)
    if ! command -v identify >/dev/null 2>&1; then
        missing_tools+=("ImageMagick (identify)")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_error "缺少必要的工具:"
        for tool in "${missing_tools[@]}"; do
            echo "  - $tool"
        done
        echo ""
        echo "请安装 ImageMagick:"
        echo "  macOS: brew install imagemagick"
        echo "  Ubuntu/Debian: sudo apt-get install imagemagick"
        echo "  CentOS/RHEL: sudo yum install ImageMagick"
        exit 1
    fi
}

# 检查文件是否为支持的图片格式
is_supported_image() {
    local file="$1"
    local ext="${file##*.}"
    ext=$(echo "$ext" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        png|jpg|jpeg|gif|bmp|tiff|tif)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 验证输入文件
validate_input_file() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        print_error "文件路径不能为空"
        return 1
    fi
    
    if [[ ! -f "$file" ]]; then
        print_error "文件不存在: $file"
        return 1
    fi
    
    if [[ ! -r "$file" ]]; then
        print_error "没有读取文件的权限: $file"
        return 1
    fi
    
    if ! is_supported_image "$file"; then
        print_error "不支持的文件格式: $file"
        echo "支持的格式: PNG, JPG, JPEG, GIF, BMP, TIFF"
        return 1
    fi
    
    return 0
}

# 解析尺寸参数
# 支持格式: "100x100", "100", "100x", "x100"
parse_size() {
    local size_str="$1"
    
    if [[ -z "$size_str" ]]; then
        print_error "尺寸不能为空"
        return 1
    fi
    
    # 移除空格
    size_str=$(echo "$size_str" | tr -d ' ')
    
    # 检查是否包含 x
    if [[ "$size_str" == *"x"* ]]; then
        # 格式: WIDTHxHEIGHT, WIDTHx, xHEIGHT
        local width="${size_str%x*}"
        local height="${size_str#*x}"
        
        # 验证数值
        if [[ -n "$width" ]] && ! [[ "$width" =~ ^[0-9]+$ ]]; then
            print_error "无效的宽度: $width"
            return 1
        fi
        
        if [[ -n "$height" ]] && ! [[ "$height" =~ ^[0-9]+$ ]]; then
            print_error "无效的高度: $height"
            return 1
        fi
        
        # 至少需要指定宽度或高度
        if [[ -z "$width" ]] && [[ -z "$height" ]]; then
            print_error "必须指定宽度或高度"
            return 1
        fi
        
        TARGET_WIDTH="$width"
        TARGET_HEIGHT="$height"
    else
        # 格式: 单一数值，作为正方形
        if ! [[ "$size_str" =~ ^[0-9]+$ ]]; then
            print_error "无效的尺寸: $size_str"
            return 1
        fi
        
        TARGET_WIDTH="$size_str"
        TARGET_HEIGHT="$size_str"
    fi
    
    return 0
}

# 获取图片信息
get_image_info() {
    local file="$1"
    
    # 使用 identify 获取图片信息
    local info=$(identify -format "%wx%h %m" "$file" 2>/dev/null)
    
    if [[ -z "$info" ]]; then
        print_error "无法读取图片信息: $file"
        return 1
    fi
    
    # 解析信息
    local dimensions="${info% *}"
    local format="${info##* }"
    
    ORIGINAL_WIDTH="${dimensions%x*}"
    ORIGINAL_HEIGHT="${dimensions#*x}"
    ORIGINAL_FORMAT="$format"
    
    return 0
}

# 计算缩放后的尺寸 (等比缩放)
calculate_resize_dimensions() {
    local orig_w="$ORIGINAL_WIDTH"
    local orig_h="$ORIGINAL_HEIGHT"
    local target_w="$TARGET_WIDTH"
    local target_h="$TARGET_HEIGHT"
    
    # 如果只指定了一个维度，计算另一个维度
    if [[ -z "$target_w" ]]; then
        # 只指定了高度
        target_w=$((orig_w * target_h / orig_h))
    elif [[ -z "$target_h" ]]; then
        # 只指定了宽度
        target_h=$((orig_h * target_w / orig_w))
    else
        # 指定了宽度和高度
        # 检查是否为正方形到正方形的缩放
        if [[ "$orig_w" -eq "$orig_h" ]] && [[ "$target_w" -eq "$target_h" ]]; then
            # 正方形到正方形，直接使用目标尺寸
            target_w="$TARGET_WIDTH"
            target_h="$TARGET_HEIGHT"
        else
            # 需要等比缩放到适合的尺寸
            local scale_w=$(echo "scale=10; $target_w / $orig_w" | bc -l)
            local scale_h=$(echo "scale=10; $target_h / $orig_h" | bc -l)
            
            # 选择较小的缩放比例以确保图片完全适合目标尺寸
            local scale
            if (( $(echo "$scale_w < $scale_h" | bc -l) )); then
                scale="$scale_w"
            else
                scale="$scale_h"
            fi
            
            # 使用四舍五入而不是截断
            target_w=$(echo "$orig_w * $scale + 0.5" | bc -l | cut -d. -f1)
            target_h=$(echo "$orig_h * $scale + 0.5" | bc -l | cut -d. -f1)
        fi
    fi
    
    FINAL_WIDTH="$target_w"
    FINAL_HEIGHT="$target_h"
    
    return 0
}

# 检查 bc 命令是否可用，如果不可用则使用 awk
calculate_resize_dimensions_fallback() {
    local orig_w="$ORIGINAL_WIDTH"
    local orig_h="$ORIGINAL_HEIGHT"
    local target_w="$TARGET_WIDTH"
    local target_h="$TARGET_HEIGHT"
    
    # 如果只指定了一个维度，计算另一个维度
    if [[ -z "$target_w" ]]; then
        # 只指定了高度
        target_w=$((orig_w * target_h / orig_h))
    elif [[ -z "$target_h" ]]; then
        # 只指定了宽度
        target_h=$((orig_h * target_w / orig_w))
    else
        # 指定了宽度和高度
        # 检查是否为正方形到正方形的缩放
        if [[ "$orig_w" -eq "$orig_h" ]] && [[ "$target_w" -eq "$target_h" ]]; then
            # 正方形到正方形，直接使用目标尺寸
            target_w="$TARGET_WIDTH"
            target_h="$TARGET_HEIGHT"
        else
            # 需要等比缩放到适合的尺寸
            # 使用 awk 进行浮点数计算
            local scale_w=$(awk "BEGIN {printf \"%.10f\", $target_w / $orig_w}")
            local scale_h=$(awk "BEGIN {printf \"%.10f\", $target_h / $orig_h}")
            
            # 选择较小的缩放比例
            local scale
            if (( $(awk "BEGIN {print ($scale_w < $scale_h)}") )); then
                scale="$scale_w"
            else
                scale="$scale_h"
            fi
            
            # 使用四舍五入
            target_w=$(awk "BEGIN {printf \"%.0f\", $orig_w * $scale}")
            target_h=$(awk "BEGIN {printf \"%.0f\", $orig_h * $scale}")
        fi
    fi
    
    FINAL_WIDTH="$target_w"
    FINAL_HEIGHT="$target_h"
    
    return 0
}

# 生成输出文件名
generate_output_filename() {
    local input="$1"
    local dir=$(dirname "$input")
    local filename=$(basename "$input")
    local name="${filename%.*}"
    
    # 生成输出文件名: 原名_WxH.png
    OUTPUT_FILE="${dir}/${name}_${FINAL_WIDTH}x${FINAL_HEIGHT}.png"
    
    # 如果文件已存在，添加数字后缀
    local counter=1
    while [[ -f "$OUTPUT_FILE" ]]; do
        OUTPUT_FILE="${dir}/${name}_${FINAL_WIDTH}x${FINAL_HEIGHT}_${counter}.png"
        ((counter++))
    done
}

# 执行图片缩放
resize_image() {
    local input="$1"
    local output="$2"
    local width="$FINAL_WIDTH"
    local height="$FINAL_HEIGHT"
    
    print_info "正在缩放图片..."
    
    # 使用 ImageMagick 进行高质量缩放
    # -quality 95: 高质量输出
    # -filter Lanczos: 使用 Lanczos 滤镜获得更好的缩放质量
    # -unsharp 0x0.75+0.75+0.008: 轻微锐化以补偿缩放造成的模糊
    if convert "$input" \
        -filter Lanczos \
        -resize "${width}x${height}" \
        -quality 95 \
        -unsharp 0x0.75+0.75+0.008 \
        "$output" 2>/dev/null; then
        
        return 0
    else
        print_error "图片缩放失败"
        return 1
    fi
}

# 显示处理结果
show_result() {
    local input="$1"
    local output="$2"
    
    echo ""
    echo "=================="
    echo "处理结果"
    echo "=================="
    echo ""
    echo "📁 输入文件: $(basename "$input")"
    echo "📐 原始尺寸: ${ORIGINAL_WIDTH}x${ORIGINAL_HEIGHT} ($ORIGINAL_FORMAT)"
    echo "🎯 目标尺寸: ${TARGET_WIDTH:-auto}x${TARGET_HEIGHT:-auto}"
    echo "📏 实际尺寸: ${FINAL_WIDTH}x${FINAL_HEIGHT}"
    echo "💾 输出文件: $(basename "$output")"
    
    # 显示文件大小
    if [[ -f "$output" ]]; then
        local input_size=$(ls -lh "$input" | awk '{print $5}')
        local output_size=$(ls -lh "$output" | awk '{print $5}')
        echo "📊 文件大小: $input_size → $output_size"
    fi
    
    echo ""
    print_success "🎉 图片缩放完成!"
    echo ""
    echo "输出路径: $output"
}

# 交互式获取输入文件
get_input_file() {
    local file="$1"
    
    if [[ -z "$file" ]]; then
        echo "Icon Resize Tool - APP 图标缩放工具"
        echo ""
        read -p "请输入图标文件路径: " file
    fi
    
    # 展开波浪号
    file="${file/#\~/$HOME}"
    
    if ! validate_input_file "$file"; then
        exit 1
    fi
    
    INPUT_FILE="$file"
}

# 交互式获取目标尺寸
get_target_size() {
    local size="$1"
    
    if [[ -z "$size" ]]; then
        echo ""
        echo "尺寸格式说明:"
        echo "  - 100      : 缩放为 100x100 (正方形)"
        echo "  - 100x200  : 缩放为 100x200"
        echo "  - 100x     : 宽度 100，高度等比缩放"
        echo "  - x200     : 高度 200，宽度等比缩放"
        echo ""
        read -p "请输入目标尺寸: " size
    fi
    
    if ! parse_size "$size"; then
        exit 1
    fi
    
    TARGET_SIZE="$size"
}

# 主函数
main() {
    # 检查依赖
    check_dependencies
    
    # 获取输入参数
    get_input_file "$1"
    get_target_size "$2"
    
    echo ""
    print_info "正在分析图片..."
    
    # 获取原始图片信息
    if ! get_image_info "$INPUT_FILE"; then
        exit 1
    fi
    
    # 计算缩放尺寸
    if command -v bc >/dev/null 2>&1; then
        calculate_resize_dimensions
    else
        calculate_resize_dimensions_fallback
    fi
    
    # 生成输出文件名
    generate_output_filename "$INPUT_FILE"
    
    # 显示处理信息
    echo ""
    echo "处理信息:"
    echo "  输入: $(basename "$INPUT_FILE") (${ORIGINAL_WIDTH}x${ORIGINAL_HEIGHT})"
    echo "  输出: $(basename "$OUTPUT_FILE") (${FINAL_WIDTH}x${FINAL_HEIGHT})"
    echo ""
    
    # 确认处理
    read -p "是否继续处理? [Y/n]: " confirm
    if [[ "$confirm" =~ ^[Nn]$ ]]; then
        echo "操作已取消"
        exit 0
    fi
    
    # 执行缩放
    if resize_image "$INPUT_FILE" "$OUTPUT_FILE"; then
        show_result "$INPUT_FILE" "$OUTPUT_FILE"
    else
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Icon Resize Tool - APP 图标缩放工具"
    echo ""
    echo "用法:"
    echo "  $0 [图标路径] [目标尺寸]"
    echo ""
    echo "参数:"
    echo "  图标路径    图标文件的路径"
    echo "  目标尺寸    目标尺寸，支持以下格式:"
    echo "              - 100      : 缩放为 100x100 (正方形)"
    echo "              - 100x200  : 缩放为 100x200"
    echo "              - 100x     : 宽度 100，高度等比缩放"
    echo "              - x200     : 高度 200，宽度等比缩放"
    echo ""
    echo "支持的格式:"
    echo "  输入: PNG, JPG, JPEG, GIF, BMP, TIFF"
    echo "  输出: PNG (保证最佳质量)"
    echo ""
    echo "示例:"
    echo "  $0 icon.png 512"
    echo "  $0 /path/to/icon.jpg 1024x1024"
    echo "  $0 icon.png x500"
    echo ""
    echo "依赖:"
    echo "  - ImageMagick (convert, identify)"
    echo "  - bc (可选，用于精确计算)"
}

# 检查是否请求帮助
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# 执行主函数
main "$@"