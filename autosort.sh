#!/bin/bash

# Declare an associative array for file types and their corresponding folders
declare -A folders=(
  [Pictures]="jpg jpeg png gif bmp tiff svg webp"
  [Documents]="pdf doc docx xls xlsx ppt pptx txt odt rtf yml yaml csv json md drawio"
  [Archives]="zip tar gz bz2 7z rar"
  [Music]="mp3 wav ogg flac m4a aac"
  [Videos]="mp4 mkv avi flv mov wmv webm"
  [Scripts]="sh py pl rb bat c ino"
  [Web]="php js html css"
  [Packages]="deb rpm pkg tgz tar.xz"
  [ISOs]="iso img"
  [Executables]="msi exe out run AppImage bin"
  [E-Books]="epub"
  [3D-Models]="step stp stl curaprofile"
  [Fonts]="ttf otf woff woff2 eot"
  [Configs]="conf ini yaml yml"
  [Failed]="part"
  [Others]=""
)

# Construct O(1) lookup array for extensions
declare -A ext_map
for category in "${!folders[@]}"; do
  if [[ "$category" != "Others" ]]; then
    for ext in ${folders[$category]}; do
      ext_map[$ext]="$category"
    done
  fi
done

# List of protected directories
protected_dirs=("/etc" "/bin" "/sbin" "/usr" "/var" "/lib" "/lib64" "/dev" "/sys" "/proc" "/run" "/boot" "/opt" "/mnt" "/srv")

target_dir="$(pwd)"
log_file="$target_dir/sort_log.txt"
script_name=$(basename "$0")

# Initialize flags
verbose=false
force=false
sort_all=false
undo_flag=false
auto_confirm=false
dry_run=false
include_hidden=false
recursive=false

usage() {
  echo "Usage: $script_name [OPTIONS] [file1 file2 ...]"
  echo "Options:"
  echo "  -a    Sort all files and directories in the current directory"
  echo "  -R    Sort recursively (all files in subdirectories)"
  echo "  -H    Include hidden files and directories"
  echo "  -u    Undo last sorting operation"
  echo "  -y    Auto-confirm (skip prompt)"
  echo "  -d    Dry-run mode (do not actually move files)"
  echo "  -h    Display this help message"
  echo "  -v    Enable verbose output"
  echo "  -f    Force sorting even in protected directories"
  exit 1
}

# Check if a directory is protected (now checks subdirectories too)
is_protected_dir() {
  local dir
  dir="$(realpath -q "$1" 2>/dev/null || echo "$1")"
  
  # Protect the exact home directory and root to prevent moving important base folders
  local home_real
  home_real="$(realpath -q "$HOME" 2>/dev/null || echo "$HOME")"
  if [[ "$dir" == "$home_real" || "$dir" == "/" ]]; then
    return 0
  fi

  for p in "${protected_dirs[@]}"; do
    local p_real
    p_real="$(realpath -q "$p" 2>/dev/null || echo "$p")"
    if [[ "$dir" == "$p_real" || "$dir" == "$p_real/"* ]]; then
      return 0
    fi
  done
  return 1
}

# Check if a directory name is one of the defined category folders (or "Folders")
is_category_dir() {
  local dname="$(basename "$1")"
  if [[ -n "${folders[$dname]+isset}" || "$dname" == "Folders" ]]; then
    return 0
  fi
  return 1
}

# Combined preview for files and directories
preview_sort() {
  local -A count
  local total_files=0
  local total_dirs=${#dirs[@]}

  # Count files by category
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      local ext="${file##*.}"
      if [[ "$file" == *.* && -n "${ext_map[${ext,,}]}" ]]; then
        ((count[${ext_map[${ext,,}]}]++))
      else
        ((count[Others]++))
      fi
    fi
  done

  echo "Files detected for sorting:"
  for category in "${!count[@]}"; do
    echo "  $category: ${count[$category]} file(s)"
    total_files=$((total_files + count[$category]))
  done
  echo "Total files: $total_files"
  echo ""

  echo "Directories detected for sorting:"
  if [[ $total_dirs -gt 0 ]]; then
    for d in "${dirs[@]}"; do
      echo "  $d"
    done
  else
    echo "  None"
  fi
  echo "Total directories: $total_dirs"
  echo ""

  if $dry_run; then
    echo "*** DRY RUN MODE - No files will be moved ***"
  fi

  if ! $auto_confirm; then
    echo "Proceed with sorting? (y/n)"
    read -r response
    if [[ "$response" != "y" ]]; then
      echo "Sorting cancelled."
      exit 0
    fi
  fi
}

sort_files() {
  if ! $dry_run; then
    echo "$(date): File sorting started" >> "$log_file"
  fi
  
  for file in "${files[@]}"; do
    if [[ -f "$file" && "$(basename "$file")" != "$script_name" ]]; then
      local ext="${file##*.}"
      local category_found="Others"
      
      if [[ "$file" == *.* && -n "${ext_map[${ext,,}]}" ]]; then
        category_found="${ext_map[${ext,,}]}"
      fi

      local dest_dir="$target_dir/$category_found"
      
      if $dry_run; then
        [[ "$verbose" == true ]] && echo "[DRY-RUN] Would create folder: $dest_dir"
      else
        if [[ ! -d "$dest_dir" ]]; then
          mkdir -p "$dest_dir"
          [[ "$verbose" == true ]] && echo "Created folder: $dest_dir"
        fi
      fi

      local base_name="$(basename "$file")"
      local dest_file="$dest_dir/$base_name"
      
      # Collision avoidance
      if [[ -e "$dest_file" ]]; then
        local base="${base_name%.*}"
        local timestamp="$(date +%s%N)"
        if [[ "$base_name" == *.* ]]; then
          dest_file="$dest_dir/${base}_${timestamp}.${ext}"
        else
          dest_file="$dest_dir/${base_name}_${timestamp}"
        fi
      fi

      if $dry_run; then
        [[ "$verbose" == true ]] && echo "[DRY-RUN] Would move: $file -> $dest_file"
      else
        if mv "$file" "$dest_file" 2>/dev/null; then
          printf "%s|%s\n" "$file" "$dest_file" >> "$log_file"
          [[ "$verbose" == true ]] && echo "Moved: $file -> $dest_file"
        else
          echo "Error: Failed to move $file" >&2
        fi
      fi
    fi
  done
  
  if ! $dry_run; then
    echo "$(date): File sorting completed" >> "$log_file"
  fi
}

sort_dirs() {
  if ! $dry_run; then
    echo "$(date): Directory sorting started" >> "$log_file"
  fi
  
  local dest_dir="$target_dir/Folders"
  
  if $dry_run; then
    [[ "$verbose" == true ]] && echo "[DRY-RUN] Would create folder: $dest_dir"
  else
    if [[ ! -d "$dest_dir" ]]; then
      mkdir -p "$dest_dir"
      [[ "$verbose" == true ]] && echo "Created folder: $dest_dir"
    fi
  fi
  
  for d in "${dirs[@]}"; do
    local base_name="$(basename "$d")"
    local dest_dir_target="$dest_dir/$base_name"
    
    # Collision avoidance
    if [[ -e "$dest_dir_target" ]]; then
      dest_dir_target="${dest_dir_target}_$(date +%s%N)"
    fi

    if $dry_run; then
      [[ "$verbose" == true ]] && echo "[DRY-RUN] Would move directory: $d -> $dest_dir_target"
    else
      if mv "$d" "$dest_dir_target" 2>/dev/null; then
        printf "%s|%s\n" "$d" "$dest_dir_target" >> "$log_file"
        [[ "$verbose" == true ]] && echo "Moved directory: $d -> $dest_dir_target"
      else
        echo "Error: Failed to move directory $d" >&2
      fi
    fi
  done
  
  if ! $dry_run; then
    echo "$(date): Directory sorting completed" >> "$log_file"
  fi
}

undo_sort() {
  if [[ ! -f "$log_file" ]]; then
    echo "No log file found. Nothing to undo."
    exit 1
  fi

  if $dry_run; then
    echo "*** DRY RUN MODE - No files will be moved ***"
  fi

  # Reverse the log file lines to undo moves in reverse order
  tac "$log_file" | while IFS='|' read -r src_file dest_file; do
    if [[ -n "$src_file" && -n "$dest_file" ]]; then
      if [[ -e "$dest_file" ]]; then
        if $dry_run; then
          [[ "$verbose" == true ]] && echo "[DRY-RUN] Would undo: Move $dest_file back to $src_file"
        else
          # Ensure original directory exists before moving back
          mkdir -p "$(dirname "$src_file")" 2>/dev/null
          if mv "$dest_file" "$src_file" 2>/dev/null; then
            [[ "$verbose" == true ]] && echo "Undo: Moved $dest_file back to $src_file"
          else
            echo "Error: Failed to undo move for $dest_file" >&2
          fi
        fi
      fi
    fi
  done
  
  if ! $dry_run; then
    rm -f "$log_file"
    echo "Undo completed."
  fi
}

# Parse options using getopts
while getopts "aRHyudhvf" opt; do
  case $opt in
    a) sort_all=true ;;
    R) recursive=true ;;
    H) include_hidden=true ;;
    y) auto_confirm=true ;;
    d) dry_run=true ;;
    u) undo_flag=true ;;
    h) usage ;;
    v) verbose=true ;;
    f) force=true ;;
    *) usage ;;
  esac
done
shift $((OPTIND-1))

# Process undo flag immediately if set
if $undo_flag; then
  undo_sort
  exit 0
fi

# Check if target directory is protected
if is_protected_dir "$target_dir"; then
  if ! $force; then
    echo "Warning: Sorting in protected directory '$target_dir' is not allowed. Use -f flag to force."
    exit 1
  else
    echo "Warning: You are sorting in a protected directory '$target_dir' (force enabled)."
  fi
fi

# Collect files and directories to sort
files=()
dirs=()

collect_items() {
  local search_dir="$1"
  local item
  
  # Ensure we iterate correctly using find if recursive
  if $recursive; then
    local find_cmd=(find "$search_dir" -mindepth 1)
    
    # Exclude category directories and Folders
    for key in "${!folders[@]}"; do
      find_cmd+=(-path "$target_dir/$key" -prune -o)
    done
    find_cmd+=(-path "$target_dir/Folders" -prune -o)
    
    # Exclude hidden if not requested
    if ! $include_hidden; then
      find_cmd+=(-name ".*" -prune -o)
    fi
    
    # Print everything else
    find_cmd+=(-print0)
    
    while IFS= read -r -d '' item; do
      if [[ "$(basename "$item")" == "$script_name" || "$(basename "$item")" == "$(basename "$log_file")" ]]; then
        continue
      fi
      if [[ -f "$item" ]]; then
        files+=("$item")
      elif [[ -d "$item" ]]; then
        if ! is_category_dir "$item"; then
          dirs+=("$item")
        fi
      fi
    done < <("${find_cmd[@]}")
  else
    # Non-recursive (current directory only)
    for item in "$search_dir"/* "$search_dir"/.*; do
      # Skip if it doesn't exist (e.g. .* matches nothing but . and ..)
      [[ -e "$item" ]] || continue
      
      local base_item="$(basename "$item")"
      
      # Skip . and ..
      [[ "$base_item" == "." || "$base_item" == ".." ]] && continue
      
      # Skip hidden items if not requested
      if ! $include_hidden && [[ "$base_item" == .* ]]; then
        continue
      fi
      
      if [[ "$base_item" == "$script_name" || "$base_item" == "$(basename "$log_file")" ]]; then
        continue
      fi
      
      if [[ -f "$item" ]]; then
        files+=("$item")
      elif [[ -d "$item" ]]; then
        if ! is_category_dir "$item"; then
          dirs+=("$item")
        fi
      fi
    done
  fi
}

if $sort_all; then
  collect_items "$target_dir"
fi

# Append any additional file/directory arguments provided
if [ $# -gt 0 ]; then
  for arg in "$@"; do
    if [[ -f "$arg" ]]; then
      files+=("$arg")
    elif [[ -d "$arg" ]]; then
      if ! is_category_dir "$arg"; then
        dirs+=("$arg")
      fi
    fi
  done
fi

# If nothing eligible is found, notify
if [[ ${#files[@]} -eq 0 && ${#dirs[@]} -eq 0 ]]; then
  echo "No files or directories to sort."
  exit 0
fi

# Display a preview and ask for confirmation
preview_sort

# Sort files and directories
if [[ ${#files[@]} -gt 0 ]]; then
  sort_files
fi

if [[ ${#dirs[@]} -gt 0 ]]; then
  sort_dirs
fi

