#!/bin/bash
#
# Icon Rename Tool
# 用于批量重命名 iOS 开发中的 icon 文件
#
# 使用方法:
#   ./icon_rename.sh [directory] [options]
#
# 参数:
#   directory          - 包含 icon 文件/文件夹的目录路径 (可选，未提供时交互式输入)
#   -n, --name <name>  - icon 的基础名称 (可选，未提供时自动生成)
#   -r, --rename-dir   - 同时重命名子文件夹 (默认: 不重命名)
#   -f, --flatten      - 扁平化：将子文件夹中的文件移到父目录，删除空文件夹
#   -d, --direct       - 直接处理指定目录下的文件，不递归子文件夹
#
# 支持的文件格式: .png, .jpg, .jpeg
#
# 示例:
#   ./icon_rename.sh ./icons                    # 处理 icons 下所有子文件夹
#   ./icon_rename.sh ./icons -n MyIcon          # 使用指定名称前缀
#   ./icon_rename.sh ./icons -r                 # 同时重命名子文件夹
#   ./icon_rename.sh ./icons -f                 # 扁平化：移动文件到父目录
#   ./icon_rename.sh ./icons/iconA -d           # 只处理 iconA 目录本身
#

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 全局变量
ICON_NAME=""
RENAME_DIR=false
FLATTEN_MODE=false
DIRECT_MODE=false
TARGET_DIR=""

# 统计变量
TOTAL_FOLDERS_PROCESSED=0
TOTAL_FILES_PROCESSED=0
TOTAL_FILES_RENAMED=0
TOTAL_FOLDERS_RENAMED=0
TOTAL_FOLDERS_DELETED=0

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

# 打印标题
print_header() {
    echo -e "${CYAN}$1${NC}"
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

# 显示帮助信息
show_help() {
    cat << EOF
Icon Rename Tool - iOS 图标批量重命名工具

使用方法:
  ./icon_rename.sh [directory] [options]

参数:
  directory          - 包含 icon 文件/文件夹的目录路径 (可选，未提供时交互式输入)

选项:
  -n, --name <name>  - icon 的基础名称 (可选，未提供时自动生成)
  -r, --rename-dir   - 同时重命名子文件夹 (默认: 不重命名)
  -f, --flatten      - 扁平化：将子文件夹中的文件移到父目录，删除空文件夹
  -d, --direct       - 直接处理指定目录下的文件，不递归子文件夹
  -h, --help         - 显示帮助信息

示例:
  ./icon_rename.sh ./icons                    # 处理 icons 下所有子文件夹
  ./icon_rename.sh ./icons -n MyIcon          # 使用指定名称前缀
  ./icon_rename.sh ./icons -r                 # 同时重命名子文件夹
  ./icon_rename.sh ./icons -f                 # 扁平化：移动文件到父目录
  ./icon_rename.sh ./icons -n Icon -f         # 指定名称并扁平化
  ./icon_rename.sh ./icons/iconA -d           # 只处理 iconA 目录本身

注意: -r 和 -f 选项互斥，不能同时使用

支持的文件格式: .png, .jpg, .jpeg
EOF
}

# 解析命令行参数
parse_arguments() {
    local dir=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -n|--name)
                if [[ -z "$2" ]] || [[ "$2" == -* ]]; then
                    print_error "选项 -n/--name 需要一个参数"
                    exit 1
                fi
                ICON_NAME="$2"
                shift 2
                ;;
            -r|--rename-dir)
                RENAME_DIR=true
                shift
                ;;
            -f|--flatten)
                FLATTEN_MODE=true
                shift
                ;;
            -d|--direct)
                DIRECT_MODE=true
                shift
                ;;
            -*)
                print_error "未知选项: $1"
                echo "使用 -h 或 --help 查看帮助信息"
                exit 1
                ;;
            *)
                if [[ -z "$dir" ]]; then
                    dir="$1"
                else
                    print_error "只能指定一个目录"
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # 如果未提供目录，交互式提示
    if [[ -z "$dir" ]]; then
        echo "Icon Rename Tool - iOS 图标批量重命名工具"
        echo ""
        read -p "请输入目录路径: " dir
    fi

    # 检查 -r 和 -f 选项互斥
    if [[ "$RENAME_DIR" == true ]] && [[ "$FLATTEN_MODE" == true ]]; then
        print_error "-r (--rename-dir) 和 -f (--flatten) 选项不能同时使用"
        echo "  -r: 重命名子文件夹（保留文件夹结构）"
        echo "  -f: 扁平化（移动文件到父目录并删除子文件夹）"
        exit 1
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
# 参数: $1 - 目录路径
# 返回扫描到的文件数量
scan_and_group_files() {
    local dir="$1"
    local temp_file="$2"

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
        echo "${base_name}|${filename}" >> "$temp_file"

        ((file_count++))
    done

    # 返回扫描到的文件数量
    echo "$file_count"
}

# 获取所有唯一的基础名称
get_unique_base_names() {
    local temp_file="$1"
    if [[ -f "$temp_file" ]]; then
        cut -d'|' -f1 "$temp_file" | sort -u
    fi
}

# 获取指定基础名称的所有文件
get_files_for_base_name() {
    local base_name="$1"
    local temp_file="$2"
    if [[ -f "$temp_file" ]]; then
        grep "^${base_name}|" "$temp_file" | cut -d'|' -f2
    fi
}

# 获取分组数量
get_group_count() {
    local temp_file="$1"
    if [[ -f "$temp_file" ]]; then
        cut -d'|' -f1 "$temp_file" | sort -u | wc -l | tr -d ' '
    else
        echo "0"
    fi
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
        echo "    ✓ $old_name → $new_name" >&2
        return 0
    else
        print_error "    ✗ 重命名失败: $old_name" >&2
        return 1
    fi
}

# 重命名一个分组的所有文件
# 参数: $1 - 目录路径, $2 - 基础名称, $3 - 新名称前缀, $4 - 临时文件
# 返回格式: "成功数量|新基础名称"
rename_group() {
    local dir="$1"
    local base_name="$2"
    local name_prefix="$3"
    local temp_file="$4"

    # 生成该分组的随机后缀
    local suffix=$(generate_random_suffix)

    # 如果提供了名称前缀，使用它；否则使用随机后缀作为名称
    local new_base_name
    if [[ -n "$name_prefix" ]]; then
        new_base_name="${name_prefix}_${suffix}"
    else
        new_base_name="${suffix}"
    fi

    local success_count=0

    # 获取该分组的所有文件
    local files=$(get_files_for_base_name "$base_name" "$temp_file")

    while IFS= read -r filename; do
        [[ -z "$filename" ]] && continue

        # 获取文件的 scale 后缀和扩展名
        local scale=$(get_scale_suffix "$filename")
        local ext=$(get_extension "$filename")

        # 构建新文件名: {name}_{suffix}{scale}.{ext}
        local new_filename="${new_base_name}${scale}.${ext}"

        # 执行重命名
        if rename_file "$dir" "$filename" "$new_filename"; then
            ((success_count++))
        fi
    done <<< "$files"

    # 返回成功数量和新基础名称
    echo "${success_count}|${new_base_name}"
}

# 检查单个分组的缺失变体
# 参数: $1 - 基础名称, $2 - 临时文件
# 返回: 缺失的变体列表 (空格分隔)
check_missing_variants() {
    local base_name="$1"
    local temp_file="$2"
    local missing=""

    # 获取该分组的所有文件
    local files=$(get_files_for_base_name "$base_name" "$temp_file")

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
    [[ "$has_1x" == false ]] && missing="@1x"
    [[ "$has_2x" == false ]] && missing="$missing @2x"
    [[ "$has_3x" == false ]] && missing="$missing @3x"

    echo "$missing" | sed 's/^ *//'
}

# 处理单个目录
# 参数: $1 - 目录路径, $2 - 名称前缀 (可选), $3 - 是否重命名目录, $4 - 父目录路径（用于扁平化模式）
process_directory() {
    local dir="$1"
    local name_prefix="$2"
    local rename_dir="$3"
    local flatten_target="$4"  # 扁平化模式下的目标父目录

    local dir_name=$(basename "$dir")
    local parent_dir=$(dirname "$dir")

    # 创建临时文件
    local temp_file=$(mktemp)

    # 扫描并分组文件
    local file_count=$(scan_and_group_files "$dir" "$temp_file")

    # 如果没有找到图片文件，跳过
    if [[ "$file_count" -eq 0 ]]; then
        rm -f "$temp_file"
        return
    fi

    local group_count=$(get_group_count "$temp_file")

    echo "  📂 $dir_name"
    echo "     找到 $file_count 个图片文件，共 $group_count 个分组"

    # 重命名文件
    local renamed_count=0
    local group_index=0
    local base_names=$(get_unique_base_names "$temp_file")
    local first_new_base_name=""  # 保存第一个分组的新基础名称，用于重命名文件夹

    while IFS= read -r base_name; do
        [[ -z "$base_name" ]] && continue

        ((group_index++))
        echo "     [$group_index/$group_count] 处理分组: $base_name"

        # 检查缺失变体
        local missing=$(check_missing_variants "$base_name" "$temp_file")
        if [[ -n "$missing" ]]; then
            print_warning "     ⚠ 缺少变体: $missing"
        fi

        # 重命名该分组，返回格式: "成功数量|新基础名称"
        local result=$(rename_group "$dir" "$base_name" "$name_prefix" "$temp_file")
        local success=$(echo "$result" | cut -d'|' -f1)
        local new_base=$(echo "$result" | cut -d'|' -f2)

        # 保存第一个分组的新基础名称
        if [[ -z "$first_new_base_name" ]]; then
            first_new_base_name="$new_base"
        fi

        renamed_count=$((renamed_count + success))
    done <<< "$base_names"

    # 更新统计
    TOTAL_FILES_PROCESSED=$((TOTAL_FILES_PROCESSED + file_count))
    TOTAL_FILES_RENAMED=$((TOTAL_FILES_RENAMED + renamed_count))
    TOTAL_FOLDERS_PROCESSED=$((TOTAL_FOLDERS_PROCESSED + 1))

    # 扁平化模式：移动文件到父目录
    if [[ -n "$flatten_target" ]]; then
        echo "     📦 移动文件到父目录..."
        local move_success=0

        # 移动所有图片文件到父目录
        shopt -s nullglob  # 如果没有匹配文件，通配符扩展为空
        for file in "$dir"/*.png "$dir"/*.jpg "$dir"/*.jpeg "$dir"/*.PNG "$dir"/*.JPG "$dir"/*.JPEG; do
            [[ -e "$file" ]] || continue
            local filename=$(basename "$file")

            if mv "$file" "$flatten_target/$filename" 2>/dev/null; then
                ((move_success++))
            else
                print_error "     ✗ 移动失败: $filename" >&2
            fi
        done
        shopt -u nullglob  # 恢复默认设置

        # 删除空文件夹
        if rmdir "$dir" 2>/dev/null; then
            print_success "     ✓ 已删除空文件夹: $dir_name"
            TOTAL_FOLDERS_DELETED=$((TOTAL_FOLDERS_DELETED + 1))
        else
            print_warning "     ⚠ 文件夹不为空，无法删除: $dir_name"
        fi
    # 重命名目录模式
    elif [[ "$rename_dir" == true ]] && [[ -n "$first_new_base_name" ]]; then
        local new_dir_name="$first_new_base_name"
        local new_dir_path="$parent_dir/$new_dir_name"

        if mv "$dir" "$new_dir_path" 2>/dev/null; then
            print_success "     ✓ 文件夹重命名: $dir_name → $new_dir_name"
            TOTAL_FOLDERS_RENAMED=$((TOTAL_FOLDERS_RENAMED + 1))
        else
            print_error "     ✗ 文件夹重命名失败: $dir_name"
        fi
    fi

    echo ""

    # 清理临时文件
    rm -f "$temp_file"
}

# 递归处理目录树
# 参数: $1 - 根目录路径
process_directory_tree() {
    local root_dir="$1"

    print_header "开始处理目录..."
    echo ""

    # 获取所有子目录
    local subdirs=()
    while IFS= read -r -d '' subdir; do
        subdirs+=("$subdir")
    done < <(find "$root_dir" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)

    # 如果没有子目录，说明这是一个直接包含图片的目录
    if [[ ${#subdirs[@]} -eq 0 ]]; then
        print_warning "未找到子文件夹，将直接处理该目录"
        echo ""
        process_directory "$root_dir" "$ICON_NAME" false ""
        return
    fi

    # 处理每个子目录
    for subdir in "${subdirs[@]}"; do
        if [[ "$FLATTEN_MODE" == true ]]; then
            # 扁平化模式：传入父目录路径
            process_directory "$subdir" "$ICON_NAME" false "$root_dir"
        else
            # 正常模式或重命名模式
            process_directory "$subdir" "$ICON_NAME" "$RENAME_DIR" ""
        fi
    done
}

# 显示最终汇总
print_final_summary() {
    echo ""
    print_header "===================="
    print_header "处理结果汇总"
    print_header "===================="
    echo ""
    echo "📁 处理的文件夹数: $TOTAL_FOLDERS_PROCESSED"
    echo "📄 处理的文件总数: $TOTAL_FILES_PROCESSED"
    echo "✅ 重命名成功文件: $TOTAL_FILES_RENAMED"

    if [[ "$RENAME_DIR" == true ]]; then
        echo "📦 重命名的文件夹: $TOTAL_FOLDERS_RENAMED"
    fi

    if [[ "$FLATTEN_MODE" == true ]]; then
        echo "🗑️  删除的文件夹数: $TOTAL_FOLDERS_DELETED"
    fi

    echo ""

    # 最终状态
    if [[ "$TOTAL_FILES_RENAMED" -eq "$TOTAL_FILES_PROCESSED" ]]; then
        print_success "🎉 全部处理完成!"
    else
        local failed=$((TOTAL_FILES_PROCESSED - TOTAL_FILES_RENAMED))
        print_warning "⚠ 有 $failed 个文件处理失败"
    fi

    echo ""
}

# 主函数
main() {
    # 解析命令行参数
    parse_arguments "$@"

    echo ""
    print_header "===================="
    print_header "Icon Rename Tool"
    print_header "===================="
    echo ""
    echo "目标目录: $TARGET_DIR"
    echo "处理模式: $([ "$DIRECT_MODE" == true ] && echo "直接模式" || echo "递归模式")"
    if [[ -n "$ICON_NAME" ]]; then
        echo "Icon 名称: $ICON_NAME"
    else
        echo "Icon 名称: (自动生成)"
    fi
    echo "重命名文件夹: $([ "$RENAME_DIR" == true ] && echo "是" || echo "否")"
    echo ""

    # 根据模式处理
    if [[ "$DIRECT_MODE" == true ]]; then
        # 直接模式：只处理指定目录
        print_header "开始处理目录..."
        echo ""
        process_directory "$TARGET_DIR" "$ICON_NAME" false
    else
        # 递归模式：处理子目录
        process_directory_tree "$TARGET_DIR"
    fi

    # 显示最终汇总
    print_final_summary
}

# 执行主函数
main "$@"
