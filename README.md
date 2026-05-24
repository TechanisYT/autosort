# 📂 autosort

A powerful and fast Bash script to automatically organize cluttered directories. `autosort` scans your files and intelligently groups them into categorized folders (Pictures, Documents, Videos, etc.) based on their file extensions.

## ✨ Features

- **🚀 Fast O(1) Lookups**: Instantly categorizes thousands of files using an optimized associative array map.
- **↩️ Safe Undo**: Made a mistake? Use the `-u` flag to flawlessly reverse the last sort operation.
- **🛡️ Collision Avoidance**: Automatically protects existing files by intelligently renaming duplicates with nanosecond timestamps instead of silently overwriting them.
- **🦺 Protected Directories**: Built-in safeguards prevent you from accidentally sorting system-critical directories (like `/etc`, `/usr/bin`, `/sys`).
- **🔍 Dry-Run Mode**: Use the `-d` flag to see exactly what the script *would* do without actually moving any files.
- **📂 Recursive Sorting**: Use the `-R` flag to sort files deep within subdirectories.

## 🛠️ Installation

1. Clone the repository anywhere on your system and make it executable:
   ```bash
   git clone https://github.com/TechanisYT/autosort.git ~/Programs/Scripts/autosort
   cd ~/Programs/Scripts/autosort
   chmod +x autosort.sh
   ```

2. (Optional but Recommended) Create an alias in your `~/.bashrc` or `~/.zshrc` so you can run it from any folder:
   ```bash
   alias autosort="~/Programs/Scripts/autosort/autosort.sh"
   ```
   *Don't forget to run `source ~/.bashrc` or restart your terminal after adding the alias.*

## 🚀 Usage

Navigate to any messy folder and run:

```bash
autosort -a
```

### Options

```text
  -a    Sort all files and directories in the current directory
  -R    Sort recursively (all files in subdirectories)
  -H    Include hidden files and directories
  -u    Undo the last sorting operation
  -y    Auto-confirm (skip the prompt, great for cron jobs)
  -d    Dry-run mode (do not actually move files, just simulate)
  -h    Display help message
  -v    Enable verbose output (see exactly what is being moved)
  -f    Force sorting even in protected directories (use with caution!)
```

## ⚙️ Configuration

At the top of the `autosort.sh` script, you will find a `folders` associative array. You can easily customize this to add new file extensions or change the folder names where files get sorted. 

```bash
declare -A folders=(
  [Pictures]="jpg jpeg png gif bmp tiff svg webp"
  [Documents]="pdf doc docx xls xlsx txt json md"
  # ... add or modify categories here
)
```

## ⚠️ Disclaimer

While this script has been updated with several safety checks (dry-run, undo, and collision avoidance), I do not guarantee that it works 100% flawlessly in every edge case. **Using it is at your own risk.** 
Please test the script using the `-d` (dry-run) flag before running it in critical directories. I take no responsibility for any deleted, lost, or misplaced files.
