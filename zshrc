# NOTE: We export all of our variables due to the WSL workaround of `exec zsh` from bash.exe
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTFILE=$HOME/.zsh_history

setopt extended_history # save timestamp
setopt inc_append_history # add history immediately after typing a command
setopt autopushd

if [[ -d "$HOME/.tmp/" ]]; then
	export TMPDIR=$HOME/.tmp/
	export TEMP=$HOME/.tmp/
	export TEMPDIR=$HOME/.tmp/
	export TMP=$HOME/.tmp/
fi

export CC=gcc
export LANG=en_US.UTF-8
export TERMINAL='xterm-256color'
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
# Setup EDITOR
# ***

# Prefer lunarvim if it exists
if [ -e "$HOME/.local/bin/lvim" ]; then
    export EDITOR="$HOME/.local/bin/lvim"
else
    # Prefer neovim if it exists
    nvim_path=$(command -v nvim 2>/dev/null)
    if [ -n "$nvim_path" ]; then
        export EDITOR="$nvim_path"
    else
        # Prefer vim if it exists
        vim_path=$(command -v vim 2>/dev/null)
        if [ -n "$vim_path" ]; then
            export EDITOR="$vim_path"
        else
            # Default to vi if nothing else exists
            export EDITOR="vi"
        fi
    fi
fi
alias vim="$EDITOR"
alias nvim="$EDITOR"
alias l="$EDITOR"
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

# If using Homebrew, setup Homebrew aliases
if [[ "$HOMEBREW_PREFIX" != "" && -e "$HOMEBREW_PREFIX" ]]; then
    
    # Homebrew setup
    export HOMEBREW_NO_ANALYTICS=1
    export HOMEBREW_TEMP=$HOME/.tmp

    # Use Homebrew GNU ls if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gls ] ; then
        alias ls="$HOMEBREW_PREFIX/bin/gls -lFG --color=auto"
    else
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # Darwin's built in BSD ls
            alias ls="ls -lFG"
        else
            # Linux built in gnuls
            alias ls="ls -lFG --color=auto"
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
        alias sort="$HOMEBREW_PREFIX/bin/gsort"
    fi

    # Use Homebrew version of GNU tar if it exists
    if [ -e $HOMEBREW_PREFIX/bin/gtar ] ; then
        alias tar="$HOMEBREW_PREFIX/bin/gtar"
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

    source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh
    autoload -U +X compinit && compinit
    autoload bashcompinit
    bashcompinit
    source $HOMEBREW_PREFIX/opt/asdf/etc/bash_completion.d/asdf.bash

    # Add Homebrew MySQL client to the PATH (prepended to prefer)
    if [[ -d $HOMEBREW_PREFIX/opt/mysql-client/bin ]]; then
        export PATH="$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH"
    fi

    export PATH="/usr/local/sbin:$PATH"

fi

# If we have Go, setup Go environment
if command -v go >/dev/null 2>&1; then
    export GOPATH=$(go env GOPATH)
    export GOROOT=$(go env GOROOT)
    export GOBIN=$(go env GOBIN)
    export PATH=$PATH:$GOPATH/bin
    export PATH=$PATH:$GOROOT/bin
    export PATH=$PATH:$GOBIN
fi

# ***
# Custom aliases / helpers (use alias to show list of aliases)
# ***

alias git-flatten='git reset $(git commit-tree HEAD^{tree} --gpg-sign -m "Flatten")'
alias fastping="ping -i 0.2"
alias ports="sudo netstat -ant -p TCP | grep LISTEN"

# Get current IPv4 address
alias checkip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

if [[ -d $HOME/.aws ]]; then
    alias aws-logout='aws sso logout ; rm -f $HOME/.aws/boto/*.json $HOME/.aws/boto/cache/*.json ; unset AWS_ACCESS_KEY_ID ; unset AWS_SECRET_ACCESS_KEY ; unset AWS_SESSION_TOKEN'
fi

# Setup for directory stack aliases
pushd()
{
  if [ $# -eq 0 ]; then
    DIR="${HOME}"
  else
    DIR="$1"
  fi

  builtin pushd "${DIR}" > /dev/null
  echo -n "DIRSTACK: "
  dirs
}
pushd_builtin()
{
  builtin pushd > /dev/null
  echo -n "DIRSTACK: "
  dirs
}
popd()
{
  builtin popd > /dev/null
  echo -n "DIRSTACK: "
  dirs
}
alias cd='pushd'
alias back='popd'
alias flip='pushd_builtin'

# Add Go binaries to the PATH
export PATH="$HOME/go/bin:$PATH"

# Add scripts to the PATH
export PATH="$HOME/scripts:$PATH"

export PATH="/usr/local/opt/llvm/bin:$PATH"

if [ -e "$HOME/.config/op/plugins.sh" ]; then
    source "$HOME/.config/op/plugins.sh"
fi

# Configure the GEM_HOME and PATH for Ruby gems
if [[ -d $HOME/.gems ]]; then
    export GEM_HOME="$HOME/.gems"
    export PATH="$HOME/.gems/bin:$PATH"
fi

# Add Homebrew OpenJDK to the PATH
export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# Load iTerm2 shell integration if installed
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# Set the TTY for GPG for password prompts
export GPG_TTY=$(tty)

# Load pyenv if it is installed
if [[ -d $HOME/.pyenv ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init --path)"
fi

# Ensure that Homebrew Cask apps are not quarantined
export HOMEBREW_CASK_OPTS=--no-quarantine

export XDG_CONFIG_HOME="$HOME/.config"
export XAUTHORITY=$HOME/.Xauthority
export DISPLAY=:0
