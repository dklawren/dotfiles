export TMUX_PLUGIN_MANAGER_PATH="~/.tmux/plugins"
if [ -z "$TMUX" ] && [ -z "$VSCODE_IPC_HOOK_CLI" ]; then
    tmux attach -t default || tmux new -s default && exit
fi

eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)    

# Case-insensitive globbing (used in pathname expansion)
shopt -s nocaseglob

# Append to the Bash history file, rather than overwriting it
shopt -s histappend

# Autocorrect typos in path names when using `cd`
shopt -s cdspell

# Enable some Bash 4 features when possible:
# * `autocd`, e.g. `**/qux` will enter `./foo/bar/baz/qux`
# * Recursive globbing, e.g. `echo **/*.txt`
for option in autocd globstar; do
    shopt -s "$option" 2> /dev/null
done

# Add tab completion for SSH hostnames based on ~/.ssh/config, ignoring wildcards
[[ -e "$HOME/.ssh/config" ]] && complete -o "default" -o "nospace" -W "$(grep "^Host" ~/.ssh/config | grep -v "[?*]" | cut -d " " -f2 | tr ' ' '\n')" scp sftp ssh

# If possible, add tab completion for many more commands
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# Docker environment config for windows
# export DOCKER_HOST=tcp://localhost:2375

# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don’t want to commit.
for file in ~/.{aliases,functions,helpers,path,exports}; do
    [[ -r "$file" ]] && [[ -f "$file" ]] && source "$file"
done
unset file

# ssh-agent configuration
if [ -z "$(pgrep ssh-agent)"  ]; then
    rm -rf /tmp/ssh-*
    eval $(ssh-agent -s) > /dev/null
else
    export SSH_AGENT_PID=$(pgrep ssh-agent)
    export SSH_AUTH_SOCK=$(find /tmp/ssh-* -name "agent.*")
fi

if [ "$(ssh-add -l)" = "The agent has no identities."  ]; then
    ssh-add
fi

# kubectl bash completion
if [ -f `which kubectl` ]; then
    source <(kubectl completion bash)
fi

# User local::lib
# eval $(perl -I$HOME/perl5/lib/perl5 -Mlocal::lib)

# git bash completion
. /usr/share/bash-completion/completions/git

# Fix docker permissions
# sudo chown root.docker /var/run/docker.sock

# cd $HOME
. "$HOME/.cargo/env"
. "$HOME/.deno/env"
