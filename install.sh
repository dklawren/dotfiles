#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

DOT_FOLDERS="bash bin git helix hg misc nvim onedrive sway tmux zsh"

for folder in $(echo $DOT_FOLDERS); do
    echo "[+] Folder :: $folder"
    stow --ignore=README.md --ignore install.sh -t $HOME -D $folder
    stow -v -t $HOME $folder
done

# Reload shell once installed
echo "[+] Reloading shell..."
exec $SHELL -l
