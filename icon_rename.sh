#!/bin/bash
#
# Icon Rename Tool
# 用于批量重命名 iOS 开发中的 icon 文件
#
# 使用方法:
#   ./icon_rename.sh [directory] [name]
#
# 参数:
#   directory - 包含 icon 文件的目录路径 (可选，未提供时交互式输入)
#   name      - icon 的基础名称 (可选，未提供时自动生成)
#
# 支持的文件格式: .png, .jpg, .jpeg
#

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# 全局变量 - 存储分组信息
# GROUP_NAMES: 所有基础名称，用换行符分隔
# GROUP_FILES_<index>: 每个分组的文件列表，用 | 分隔
GROUP_NAMES=""
GROUP_COUNT=0

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

# 生成6位随机后缀
# 字符集: a-z, A-Z, 0-9
generate_random_suffix() {
    cat /dev/urandom | LC_ALL=C tr -dc 'a-zA-Z0-9' | head -c 6
}

# 获取文件扩展名 (不含点号)
# 参数: $1 - 文件名
get_extension() {
    local filename="$1"
    echo "${filename##*.}"
}

# 获取 scale 后缀 (@2x, @3x, 或空字符串表示 @1x)
# 参数: $1 - 文件名
get_scale_suffix() {
    local filename="$1"
    # 移除扩展名
    local name="${filename%.*}"
    
    if [[ "$name" == *"@3x" ]]; then
        echo "@3x"
    elif [[ "$name" == *"@2x" ]]; then
        echo "@2x"
    else
        echo ""  # @1x 没有后缀
    fi
}

# 提取基础名称 (移除 @2x/@3x 后缀和扩展名)
# 参数: $1 - 文件名
get_base_name() {
    local filename="$1"
    # 移除扩展名
    local name="${filename%.*}"
    # 移除 @2x/@3x 后缀
    name="${name%@2x}"
    name="${name%@3x}"
    echo "$name"
}

# 验证目录是否存在
validate_directory() {
    local dir="$1"
    
    if [[ -z "$dir" ]]; then
        print_error "目录路径不能为空"
        return 1
    fi
    
    if [[ ! -d "$dir" ]]; then
        print_error "目录不存在 - $dir"
        return 1
    fi
    
    if [[ ! -r "$dir" ]]; then
        print_error "没有读取目录的权限 - $dir"
        return 1
    fi
    
    return 0
}

# 解析命令行参数
parse_arguments() {
    local dir="$1"
    
    # 如果未提供目录，交互式提示
    if [[ -z "$dir" ]]; then
        echo "Icon Rename Tool - iOS 图标批量重命名工具"
        echo ""
        read -p "请输入目录路径: " dir
    fi
    
    # 验证目录
    if ! validate_directory "$dir"; then
        exit 1
    fi
    
    # 将相对路径转换为绝对路径
    dir=$(cd "$dir" && pwd)
    
    # 导出变量供后续使用
    TARGET_DIR="$dir"
}

# 获取 Icon 名称
get_icon_name() {
    local name="$1"
    
    # 如果未提供名称，交互式提示
    if [[ -z "$name" ]]; then
        echo ""
        read -p "请输入 Icon 名称 (直接回车自动生成): " name
    fi
    
    # 如果名称为空，生成随机名称
    if [[ -z "$name" ]]; then
        name=$(generate_random_suffix)
        echo "自动生成名称: $name"
    fi
    
    # 导出变量供后续使用
    ICON_NAME="$name"
}

# 检查文件是否为支持的图片格式
# 参数: $1 - 文件名
is_image_file() {
    local filename="$1"
    local ext=$(get_extension "$filename" | tr '[:upper:]' '[:lower:]')
    
    case "$ext" in
        png|jpg|jpeg)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# 扫描目录中的图片文件并按基础名称分组
# 使用临时文件存储分组信息 (兼容 Bash 3.2)
# 返回扫描到的文件数量
scan_and_group_files() {
    local dir="$1"
    
    # 计数器
    local file_count=0
    
    # 遍历目录中的文件
    for file in "$dir"/*; do
        # 跳过目录
        [[ -d "$file" ]] && continue
        
        # 获取文件名
        local filename=$(basename "$file")
        
        # 检查是否为图片文件
        if ! is_image_file "$filename"; then
            continue
        fi
        
        # 获取基础名称
        local base_name=$(get_base_name "$filename")
        
        # 写入临时文件: base_name|filename
        echo "${base_name}|${filename}" >> "$TEMP_GROUP_FILE"
        
        ((file_count++))
    done
    
    # 返回扫描到的文件数量
    echo "$file_count"
}

# 获取所有唯一的基础名称
get_unique_base_names() {
    if [[ -f "$TEMP_GROUP_FILE" ]]; then
        cut -d'|' -f1 "$TEMP_GROUP_FILE" | sort -u
    fi
}

# 获取指定基础名称的所有文件
get_files_for_base_name() {
    local base_name="$1"
    if [[ -f "$TEMP_GROUP_FILE" ]]; then
        grep "^${base_name}|" "$TEMP_GROUP_FILE" | cut -d'|' -f2
    fi
}

# 获取分组数量
get_group_count() {
    if [[ -f "$TEMP_GROUP_FILE" ]]; then
        cut -d'|' -f1 "$TEMP_GROUP_FILE" | sort -u | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# 显示分组信息 (调试用)
print_groups() {
    echo "发现的 Icon 分组:"
    echo "=================="
    
    local base_names=$(get_unique_base_names)
    
    while IFS= read -r base_name; do
        [[ -z "$base_name" ]] && continue
        
        echo ""
        echo "分组: $base_name"
        
        # 获取该分组的所有文件
        local files=$(get_files_for_base_name "$base_name")
        while IFS= read -r file; do
            [[ -z "$file" ]] && continue
            local scale=$(get_scale_suffix "$file")
            if [[ -z "$scale" ]]; then
                scale="@1x"
            fi
            echo "  - $file ($scale)"
        done <<< "$files"
    done <<< "$base_names"
}

# 重命名单个文件
# 参数: $1 - 目录路径, $2 - 原文件名, $3 - 新文件名
# 返回: 0 成功, 1 失败
rename_file() {
    local dir="$1"
    local old_name="$2"
    local new_name="$3"
    local old_path="$dir/$old_name"
    local new_path="$dir/$new_name"
    
    if mv "$old_path" "$new_path" 2>/dev/null; then
        print_success "  ✓ $old_name → $new_name"
        return 0
    else
        print_error "  ✗ 重命名失败: $old_name"
        return 1
    fi
}

# 重命名一个分组的所有文件
# 参数: $1 - 目录路径, $2 - 基础名称, $3 - 新名称前缀 (可选)
# 设置全局变量 RENAME_SUCCESS_COUNT 为成功重命名的文件数量
rename_group() {
    local dir="$1"
    local base_name="$2"
    local name_prefix="$3"
    
    # 生成该分组的随机后缀
    local suffix=$(generate_random_suffix)
    
    # 如果提供了名称前缀，使用它；否则使用随机后缀作为名称
    local new_base_name
    if [[ -n "$name_prefix" ]]; then
        new_base_name="${name_prefix}_${suffix}"
    else
        new_base_name="${suffix}"
    fi
    
    RENAME_SUCCESS_COUNT=0
    
    # 获取该分组的所有文件
    local files=$(get_files_for_base_name "$base_name")
    
    while IFS= read -r filename; do
        [[ -z "$filename" ]] && continue
        
        # 获取文件的 scale 后缀和扩展名
        local scale=$(get_scale_suffix "$filename")
        local ext=$(get_extension "$filename")
        
        # 构建新文件名: {name}_{suffix}{scale}.{ext}
        local new_filename="${new_base_name}${scale}.${ext}"
        
        # 执行重命名
        if rename_file "$dir" "$filename" "$new_filename"; then
            ((RENAME_SUCCESS_COUNT++))
        fi
    done <<< "$files"
}

# 检查单个分组的缺失变体
# 参数: $1 - 基础名称
# 返回: 缺失的变体列表 (空格分隔)，如果没有缺失则返回空字符串
check_missing_variants() {
    local base_name="$1"
    local missing=""
    
    # 获取该分组的所有文件
    local files=$(get_files_for_base_name "$base_name")
    
    # 标记各变体是否存在
    local has_1x=false
    local has_2x=false
    local has_3x=false
    
    while IFS= read -r filename; do
        [[ -z "$filename" ]] && continue
        
        local scale=$(get_scale_suffix "$filename")
        case "$scale" in
            "")
                has_1x=true
                ;;
            "@2x")
                has_2x=true
                ;;
            "@3x")
                has_3x=true
                ;;
        esac
    done <<< "$files"
    
    # 收集缺失的变体
    if [[ "$has_1x" == false ]]; then
        missing="@1x"
    fi
    if [[ "$has_2x" == false ]]; then
        if [[ -n "$missing" ]]; then
            missing="$missing @2x"
        else
            missing="@2x"
        fi
    fi
    if [[ "$has_3x" == false ]]; then
        if [[ -n "$missing" ]]; then
            missing="$missing @3x"
        else
            missing="@3x"
        fi
    fi
    
    echo "$missing"
}

# 检查所有分组的缺失变体
# 设置全局变量:
#   MISSING_VARIANTS_REPORT - 缺失变体报告 (每行格式: base_name|missing_variants)
#   GROUPS_WITH_MISSING_COUNT - 有缺失变体的分组数量
check_all_missing_variants() {
    MISSING_VARIANTS_REPORT=""
    GROUPS_WITH_MISSING_COUNT=0
    
    local base_names=$(get_unique_base_names)
    
    while IFS= read -r base_name; do
        [[ -z "$base_name" ]] && continue
        
        local missing=$(check_missing_variants "$base_name")
        
        if [[ -n "$missing" ]]; then
            ((GROUPS_WITH_MISSING_COUNT++))
            if [[ -n "$MISSING_VARIANTS_REPORT" ]]; then
                MISSING_VARIANTS_REPORT="${MISSING_VARIANTS_REPORT}
${base_name}|${missing}"
            else
                MISSING_VARIANTS_REPORT="${base_name}|${missing}"
            fi
        fi
    done <<< "$base_names"
}

# 显示缺失变体报告
print_missing_variants_report() {
    if [[ -z "$MISSING_VARIANTS_REPORT" ]]; then
        return
    fi
    
    echo ""
    print_warning "⚠ 发现 $GROUPS_WITH_MISSING_COUNT 个分组存在缺失变体:"
    echo ""
    
    while IFS='|' read -r base_name missing; do
        [[ -z "$base_name" ]] && continue
        echo "  • $base_name: 缺少 $missing"
    done <<< "$MISSING_VARIANTS_REPORT"
}

# 显示结果汇总
# 参数: $1 - 处理的文件总数, $2 - 重命名成功的文件数, $3 - 分组总数
print_summary() {
    local total_files="$1"
    local renamed_files="$2"
    local group_count="$3"
    
    echo ""
    echo "=================="
    echo "处理结果汇总"
    echo "=================="
    echo ""
    echo "📁 处理的文件总数: $total_files"
    echo "✅ 重命名成功: $renamed_files 个文件"
    echo "📦 Icon 分组数: $group_count"
    
    # 显示缺失变体汇总
    if [[ "$GROUPS_WITH_MISSING_COUNT" -gt 0 ]]; then
        echo ""
        print_warning "⚠ 缺失变体: $GROUPS_WITH_MISSING_COUNT 个分组存在缺失"
        echo ""
        while IFS='|' read -r base_name missing; do
            [[ -z "$base_name" ]] && continue
            echo "  • $base_name: 缺少 $missing"
        done <<< "$MISSING_VARIANTS_REPORT"
    else
        echo ""
        print_success "✓ 所有分组的变体完整 (@1x, @2x, @3x)"
    fi
    
    echo ""
    
    # 最终状态
    if [[ "$renamed_files" -eq "$total_files" ]]; then
        print_success "🎉 全部处理完成!"
    else
        local failed=$((total_files - renamed_files))
        print_warning "⚠ 有 $failed 个文件处理失败"
    fi
}

# 重命名所有分组
# 参数: $1 - 目录路径, $2 - 名称前缀 (可选)
# 设置全局变量 TOTAL_RENAMED_COUNT 为成功重命名的文件总数
rename_all_groups() {
    local dir="$1"
    local name_prefix="$2"
    
    TOTAL_RENAMED_COUNT=0
    local group_index=0
    local total_groups=$(get_group_count)
    
    echo "开始重命名..."
    echo ""
    
    local base_names=$(get_unique_base_names)
    
    while IFS= read -r base_name; do
        [[ -z "$base_name" ]] && continue
        
        ((group_index++))
        echo "[$group_index/$total_groups] 处理分组: $base_name"
        
        # 重命名该分组
        rename_group "$dir" "$base_name" "$name_prefix"
        TOTAL_RENAMED_COUNT=$((TOTAL_RENAMED_COUNT + RENAME_SUCCESS_COUNT))
        
        echo ""
    done <<< "$base_names"
}

# 清理临时文件
cleanup() {
    if [[ -f "$TEMP_GROUP_FILE" ]]; then
        rm -f "$TEMP_GROUP_FILE"
    fi
}

# 主函数
main() {
    # 创建临时文件存储分组信息
    TEMP_GROUP_FILE=$(mktemp)
    
    # 设置退出时清理临时文件
    trap cleanup EXIT
    
    # 分别处理目录和名称参数
    parse_arguments "$1"
    get_icon_name "$2"
    
    echo ""
    echo "目标目录: $TARGET_DIR"
    if [[ -n "$ICON_NAME" ]]; then
        echo "Icon 名称: $ICON_NAME"
    else
        echo "Icon 名称: (自动生成)"
    fi
    echo ""
    
    # 扫描并分组文件
    echo "正在扫描目录..."
    local file_count=$(scan_and_group_files "$TARGET_DIR")
    
    # 检查是否找到图片文件
    if [[ "$file_count" -eq 0 ]]; then
        print_warning "目录中没有找到图片文件 (.png, .jpg, .jpeg)"
        exit 0
    fi
    
    local group_count=$(get_group_count)
    echo "找到 $file_count 个图片文件，共 $group_count 个分组"
    echo ""
    
    # 检查缺失变体 (在重命名前检查，使用原始文件名)
    check_all_missing_variants
    
    # 执行重命名
    rename_all_groups "$TARGET_DIR" "$ICON_NAME"
    
    # 显示结果汇总
    print_summary "$file_count" "$TOTAL_RENAMED_COUNT" "$group_count"
}

# 执行主函数
main "$@"
