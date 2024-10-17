#!/bin/bash

# Declare an associative array for file types and their corresponding folders
declare -A folders=(
  [Pictures]="jpg jpeg png gif bmp tiff svg webp"
  [Documents]="pdf doc docx xls xlsx ppt pptx txt odt rtf yml yaml PDF csv json JPG md drawio"
  [Archives]="zip tar gz bz2 7z rar"
  [Music]="mp3 wav ogg flac m4a aac"
  [Videos]="mp4 mkv avi flv mov wmv webm MOV"
  [Scripts]="h c ino sh py pl rb bat"
  [Web]="php js html css"
  [Packages]="deb rpm pkg tgz tar.xz"
  [ISOs]="iso img"
  [Executables]="msi exe out run AppImage bin"
  [E-Books]="epub"
  [3D-Models]="step stp stl curaprofile"
  [Fonts]="ttf otf woff woff2 eot"
  [Configs]="conf ini yaml yml"
  [Failed]="part"
  [Others]=""  # Catch-all for unspecified file types
)

# Important top-level directories to avoid using this script in
protected_dirs=("/" "/etc" "/bin" "/sbin" "/usr" "/var" "/lib" "/lib64" "/dev" "/sys" "/proc" "/run" "/boot" "/opt" "/mnt" "/srv" "$HOME")

# Get the current directory
target_dir="$(pwd)"

# Check if the script is running in a protected top-level directory, but allow subdirectories
for dir in "${protected_dirs[@]}"; do
  if [[ "$target_dir" == "$dir" ]]; then
    echo "Warning: You are trying to run this script in a protected directory ($dir). Exiting."
    exit 1
  fi
done

script_name=$(basename "$0")  # Get the script's name to avoid moving it

# Function to sort files into subfolders based on their type
sort_files() {

  # Track if we need to create any folders based on file types present
  declare -A folder_created

  # Move files to corresponding subfolders based on their extension
  for folder in "${!folders[@]}"; do
    for ext in ${folders[$folder]}; do
      # Check if any file with the current extension exists
      if ls "$target_dir"/*.$ext 1> /dev/null 2>&1; then
        # Create the folder if not created already
        if [[ ! -d "$target_dir/$folder" && -z "${folder_created[$folder]}" ]]; then
          mkdir -p "$target_dir/$folder"
          folder_created[$folder]=1
        fi
        # Move matching files, but exclude the script itself
        for file in "$target_dir"/*.$ext; do
          if [[ "$(basename "$file")" != "$script_name" ]]; then
            mv "$file" "$target_dir/$folder" 2>/dev/null
          fi
        done
      fi
    done
  done

  # Move others (anything else left over that isn't a directory and isn't the script)
  for file in "$target_dir"/*; do
    if [[ -f "$file" && "$(basename "$file")" != "$script_name" ]]; then
      # Only create "Others" folder if needed
      if [[ ! -d "$target_dir/Others" ]]; then
        mkdir -p "$target_dir/Others"
      fi
      mv "$file" "$target_dir/Others" 2>/dev/null
    fi
  done

  # List of known folders created by this script to avoid moving them to 'Folders'
  known_folders=("${!folders[@]}" "Others" "Folders")

  # Move non-specified folders to 'Folders', but skip known folders
  for folder in "$target_dir"/*; do
    if [[ -d "$folder" && ! " ${known_folders[*]} " =~ " $(basename "$folder") " ]]; then
      # Create 'Folders' folder if needed
      if [[ ! -d "$target_dir/Folders" ]]; then
        mkdir -p "$target_dir/Folders"
      fi
      mv "$folder" "$target_dir/Folders" 2>/dev/null
    fi
  done
}

# Run the sorting function in the current directory
sort_files
