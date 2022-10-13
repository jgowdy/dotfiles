# NOTE: We export all of our variables due to the WSL workaround of `exec zsh` from bash.exe
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTFILE=$HOME/.zsh_history

setopt extended_history # save timestamp
setopt inc_append_history # add history immediately after typing a command
setopt autopushd

export CC=gcc
export LANG=en_US.UTF-8
export TERMINAL='kitty'
export GPG_TTY=$(tty)
export BROWSER='firefox'

# Load zsh functions if not already loaded
source $HOME/.zfunc

cached_source 'machine' "echo export MACHINE=$(uname -m)"
cached_source 'system' "echo export SYSTEM=$(uname -s)"
cached_source 'wsl' "echo export WSL_FLAG=$(grep -q -s -i microsoft /proc/version && echo 1 || echo 0)"

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word
bindkey '^R' history-incremental-search-backward

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
    # TODO: Use cached_source on this which statement?
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
    export SYSTEM='Linux/WSL'
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

if [ "$HOMEBREW_PREFIX" != "" ]; then

    # Use Homebrew GNU ls if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gls ] ; then
        alias ls="$HOMEBREW_PREFIX/bin/gls -laFG --color=auto"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Darwin's built in BSD ls
            alias ls="ls -laFG"
        else
            # Linux built in gnuls
            alias ls="ls -laFG --color=auto"
        fi
    fi

    # TODO: Make a function for preferring certain Homebrew coreutils over macOS/BSD

    # Use Homebrew version of GNU grep if it exists
    if [ -e $HOMEBREW_PREFIX/bin/ggrep ] ; then
        alias grep="$HOMEBREW_PREFIX/bin/ggrep --color=auto"
    fi

    # Use Homebrew version of GNU fgrep if it exists
    if [ -e $HOMEBREW_PREFIX/bin/fgrep ] ; then
        alias fgrep="$HOMEBREW_PREFIX/bin/gfgrep --color=auto"
    fi

    # Use Homebrew version of GNU egrep if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gegrep ] ; then
        alias egrep="$HOMEBREW_PREFIX/bin/gegrep --color=auto"
    fi

    # Use Homebrew version of GNU cut if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gcut ] ; then
        alias cut="$HOMEBREW_PREFIX/bin/gcut"
    fi

    # Use Homebrew version of GNU sort if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gsort ] ; then
        alias sort="$HOMEBREW_PREFIX/bin/gsort --color=auto"
    fi

    # Use Homebrew version of GNU tar if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gtar ] ; then
        alias tar="$HOMEBREW_PREFIX/bin/gtar --color=auto"
    fi

    # Alias Homebrew neomutt to mutt if it exists
    if [ -e $HOMEBREW_PREFIX/bin/neomutt ] ; then
        alias mutt='neomutt'
    fi

    # Use Homebrew version of openssl binary if it exists
    if [ -e $HOMEBREW_PREFIX/bin/openssl ]; then
        OPENSSL_BIN="$HOMEBREW_PREFIX/bin/openssl"
    elif [ -e $HOMEBREW_PREFIX/opt/openssl/bin/openssl ]; then
        OPENSSL_BIN="$HOMEBREW_PREFIX/opt/openssl/bin/openssl"
    fi

    if [ "$OPENSSL_BIN" != "" ]; then
        alias openssl="$OPENSSL_BIN"

        # File encrypt and decrypt with -in infile -out outfile
        alias enc="$OPENSSL_BIN enc -chacha20 -pbkdf2"
        alias dec="$OPENSSL_BIN enc -chacha20 -pbkdf2 -d"
    fi

    # For interactive shells, enable rbenv, pyenv, and jenv to set variables
    cached_source 'rbenv-init' "$HOMEBREW_PREFIX/bin/rbenv init -"
    cached_source 'pyenv-init' "$HOMEBREW_PREFIX/bin/pyenv init -"
    cached_source 'jenv-init' "$HOMEBREW_PREFIX/bin/jenv init -"

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

 export NVM_DIR="$HOME/.nvm"
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && . "/opt/homebrew/opt/nvm/nvm.sh"  # This loads nvm
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && . "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"  # This loads nvm bash_completion

export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"

export PATH="/usr/local/opt/llvm/bin:$PATH"
