HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILE=~/.zsh_history

export CC=gcc
export LANG=en_US.UTF-8
export TERMINAL='kitty'
export GPG_TTY=$(tty)
#export PS1='%n@%m %1~ %# '
export BROWSER='firefox'

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word

# macOS specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then

    # Attempt to force the use of arm64 binaries
    #ARCHPREFERENCE="arm64e;arm64;x86_64;i486"
    #if [ `machine` != arm64e ]; then
    #    exec arch -arm64e zsh
    #fi

    # Use arch -64 override to fix Homebrew for M1
    alias brew="arch -64 brew"

    if [[ "$TERM" == "xterm-kitty" ]]; then
        # Image-cat for kitty
        alias icat="kitty +kitten icat"

        # SSH with kitty termcap
        alias kssh="kitty +kitten ssh"

        # kitty diff
        alias d="kitty +kitten diff"
    fi
    export PS1=$'\e[0;94m%n@%m %1~ %# \e[0m'
else
    export PS1=$'\e[0;91m%n@%m %1~ %# \e[0m'
fi

# Universal aliases / variables

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

# Use Homebrew version of openssl binary if it exists
if [ -e $HOMEBREW_PREFIX/bin/openssl ]; then
    alias openssl="$HOMEBREW_PREFIX/bin/openssl"

    # File encrypt and decrypt with -in infile -out outfile
    alias enc="$HOMEBREW_PREFIX/bin/openssl enc -chacha20 -pbkdf2"
    alias dec="$HOMEBREW_PREFIX/bin/openssl enc -chacha20 -pbkdf2 -d"
fi

# Prefer lunarvim
if [ -e "$HOME/.local/bin/lvim" ]; then
    export EDITOR="$HOME/.local/bin/lvim"
    alias vim="$EDITOR"
    alias nvim="$EDITOR"
    alias l="$EDITOR"
else
    # If lunarvim isn't installed, prefer neovim
    if which nvim 2>&1 >/dev/null; then
        export EDITOR="$(which nvim)"
        alias vim="$EDITOR"
        alias nvim="$EDITOR"
    else
        export EDITOR="$(which vim)"
    fi
fi
export GIT_EDITOR="$EDITOR"

# We always use podman if it exists
if which podman 2>&1 >/dev/null; then
    alias docker=podman
fi

alias mutt='neomutt'

# Launch lunarvim
alias l="lvim"

# Get current IPv4 address
alias checkip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

# Custom helpers
alias git-flatten='git reset $(git commit-tree HEAD^{tree} --gpg-sign -m "Flatten")'
alias fastping="ping -i 0.2"
alias ports="sudo netstat -ant -p TCP | grep LISTEN"
alias reset-podman="podman machine stop ; sleep 1; podman machine rm ; podman machine init ; podman machine start"
alias nuke-podman="podman system prune --all --force && podman rmi --all && podman system reset && sudo rm -rf ~/.local/share/containers"



if ! source .cache/rbenv-init.zsh ; then
    echo "Building rbenv init cache file"
    rbenv init - > .cache/rbenv-init.zsh
    source .cache/rbenv-init.zsh
fi

if ! source .cache/pyenv-init.zsh ; then
    echo "Building pyenv init cache file"
    pyenv init - > .cache/pyenv-init.zsh
    source .cache/pyenv-init.zsh
fi

if ! source .cache/jenv-init.zsh ; then
    echo "Building jenv init cache file"
    jenv init - > .cache/jenv-init.zsh
    source .cache/jenv-init.zsh
fi


