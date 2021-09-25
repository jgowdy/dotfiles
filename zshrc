export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTFILE=$HOME/.zsh_history

setopt extended_history # save timestamp
setopt inc_append_history # add history immediately after typing a command

export CC=gcc
export LANG=en_US.UTF-8
export TERMINAL='kitty'
export GPG_TTY=$(tty)
export BROWSER='firefox'

source $HOME/.zfunc

cached_source 'machine' "echo export MACHINE=$(uname -m)"
cached_source 'system' "echo export SYSTEM=$(uname -s)"
cached_source 'wsl' "echo export WSL_FLAG=$(grep -q -s -i microsoft /proc/version && echo 1 || echo 0)"

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word

# ***
# Setup EDITOR - Prefer lunarvim
# ***

if [ -e "$HOME/.local/bin/lvim" ]; then
    export EDITOR="$HOME/.local/bin/lvim"
    alias vim="$EDITOR"
    alias nvim="$EDITOR"
    alias l="$EDITOR"
else
    # If lunarvim isn't installed, prefer neovim (use which in case we don't have Homebrew)
    if which nvim 2>&1 >/dev/null; then
        export EDITOR="$(which nvim)"
        alias vim="$EDITOR"
        alias nvim="$EDITOR"
    else
        export EDITOR="$(which vim)"
    fi
fi
export GIT_EDITOR="$EDITOR"

# ***
# Setup prompt / PS1
# ***

if [[ "$OSTYPE" == "darwin"* ]]; then
    # Make macOS prompt blue
    OS_COLOR='%F{33}'
elif [[ "$WSL_FLAG" == "1" ]]; then
    # Make WSL prompt fuchsia
    OS_COLOR='%F{13}'
else
    # Make Ubuntu prompt green
    OS_COLOR='%F{82}'
fi
export PS1="${OS_COLOR}%n%F{255}@${OS_COLOR}%m (%F{226}${MACHINE}%F{255}/%F{226}${SYSTEM}${OS_COLOR}) %1~ %f %# "

# If using kitty, setup kitten aliases
if [[ "$TERM" == "xterm-kitty" ]]; then
    # Image-cat for kitty
    alias icat="kitty +kitten icat"

    # SSH with kitty termcap
    alias kssh="kitty +kitten ssh"

    # kitty diff
    alias d="kitty +kitten diff"
fi

# Use Homebrew gnuls if it exists
if [ -e $HOMEBREW_PREFIX/bin/gls ] ; then
    alias ls="$HOMEBREW_PREFIX/bin/gls -laFG --color=auto"
else
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # Darwin built in gnuls
        alias ls="ls -laFG"
    else
        # Linux built in gnuls
        alias ls="ls -laFG --color=auto"
    fi
fi

# Use Homebrew version of gnugrep if it exists
if [ -e $HOMEBREW_PREFIX/bin/ggrep ] ; then
    alias grep="$HOMEBREW_PREFIX/bin/ggrep --color=auto"
fi

# Alias Homebrew neomutt to mutt if it exists
if [ -e $HOMEBREW_PREFIX/bin/neomutt ] ; then
    alias mutt='neomutt'
fi


# Use Homebrew version of openssl binary if it exists
if [ -e $HOMEBREW_PREFIX/bin/openssl ]; then
    alias openssl="$HOMEBREW_PREFIX/bin/openssl"

    # File encrypt and decrypt with -in infile -out outfile
    alias enc="$HOMEBREW_PREFIX/bin/openssl enc -chacha20 -pbkdf2"
    alias dec="$HOMEBREW_PREFIX/bin/openssl enc -chacha20 -pbkdf2 -d"
fi


# TODO: If we have podman, BUT we don't have docker, alias podman to docker

# We always use podman if it exists
#if which podman 2>&1 >/dev/null; then
#    alias docker=podman
#fi


# ***
# Custom aliases / helpers (use alias to show list of aliases)
# ***

alias git-flatten='git reset $(git commit-tree HEAD^{tree} --gpg-sign -m "Flatten")'
alias fastping="ping -i 0.2"
alias ports="sudo netstat -ant -p TCP | grep LISTEN"

alias reset-podman="podman machine stop ; sleep 1; podman machine rm ; podman machine init ; podman machine start"
alias nuke-podman="podman system prune --all --force && podman rmi --all && podman system reset && sudo rm -rf ~/.local/share/containers"

# Get current IPv4 address
alias checkip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

alias clear-zsh-cache='rm ~/.cache/*.zsh'


# For interactive shells, enable rbenv, pyenv, and jenv to set variables
cached_source 'rbenv-init' "$HOMEBREW_PREFIX/bin/rbenv init -"
cached_source 'pyenv-init' "$HOMEBREW_PREFIX/bin/pyenv init -"
cached_source 'jenv-init' "$HOMEBREW_PREFIX/bin/jenv init -"
