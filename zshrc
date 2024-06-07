# ****************************************************************************************************
# Attempt to handle errors during .zshrc via exit 0
# ****************************************************************************************************
error_handler() {
    echo "An error occurred in .zshrc"
    exit 0
}
trap error_handler ERR

# ****************************************************************************************************
# Setup environment
# ****************************************************************************************************

# NOTE: We export all of our variables due to the WSL workaround of `exec zsh` from bash.exe
export CC=gcc
export LANG=en_US.UTF-8
export TERMINAL='xterm-256color'
export GPG_TTY=$TTY
export HISTSIZE=1000000000
export SAVEHIST=1000000000
export HISTFILE=$HOME/.zsh_history
export XDG_CONFIG_HOME="$HOME/.config"
export XAUTHORITY="$HOME/.Xauthority"
export DISPLAY=:0
export TZ='America/Los_Angeles'

# ****************************************************************************************************
# Set telemetry opt-outs
# ****************************************************************************************************

export HOMEBREW_NO_ANALYTICS=1
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export POWERSHELL_TELEMETRY_OPTOUT=1
export NPM_CONFIG_TELEMETRY=0
export DISABLE_NPM_USAGE_METRICS=1
export VSCODE_TELEMETRY_OPTOUT=true
export GOOGLE_ANALYTICS_DISABLED=true
export SENTRY_DISABLED=true
export AWS_TELEMETRY_OPT_OUT=true
export JEKYLL_NO_USAGE=true
export SKIP_TELEMETRY=true
export NO_UPDATE_NOTIFIER=true
export TELEMETRY_DISABLED=true

# ****************************************************************************************************
# Set zsh options
# ****************************************************************************************************

setopt extended_history # save timestamp
setopt inc_append_history # add history immediately after typing a command
setopt autopushd

# ****************************************************************************************************
# Load zsh functions (e.g., cached_source)
# ****************************************************************************************************

if [ -e $HOME/.zfunc ]; then
    source $HOME/.zfunc
fi

# ****************************************************************************************************
# Configure temporary directory
# ****************************************************************************************************

# Optimize for $HOME/.tmp already exists
if [[ -d "$HOME/.tmp/" ]]; then
    export TMPDIR=$HOME/.tmp/
    export TEMP=$HOME/.tmp/
    export TEMPDIR=$HOME/.tmp/
    export TMP=$HOME/.tmp/
else
    if mkdir -p -m 600 $HOME/.tmp/; then
        export TMPDIR=$HOME/.tmp/
        export TEMP=$HOME/.tmp/
        export TEMPDIR=$HOME/.tmp/
        export TMP=$HOME/.tmp/
    fi
fi

# ****************************************************************************************************
# Configure terminal keys
# ****************************************************************************************************

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word
bindkey '^R' history-incremental-search-backward

# ****************************************************************************************************
# Setup for directory stack aliases (pushd/popd/cd/back/flip)
# ****************************************************************************************************

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

# ****************************************************************************************************
# Setup prompt / PS1
# ****************************************************************************************************

# Use cached_source function to cache machine type flags for prompt / PS1
cached_source 'machine' "echo export MACHINE=\$(uname -m)"
cached_source 'system' "echo export SYSTEM=\$(uname -s)"
cached_source 'wsl' "echo export WSL_FLAG=\$(grep -q -s -i microsoft /proc/version && echo 1 || echo 0)"

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

# ****************************************************************************************************
# Setup Homebrew and GNU utilities
# ****************************************************************************************************

# If using Homebrew, setup Homebrew aliases
if [[ "$HOMEBREW_PREFIX" != "" && -e "$HOMEBREW_PREFIX" ]]; then
    # Homebrew setup
    export HOMEBREW_NO_ANALYTICS=1

    # Ensure that Homebrew uses the selected TMPDIR
    export HOMEBREW_TEMP=$TMPDIR

    # Ensure that Homebrew Cask apps are not quarantined
    export HOMEBREW_CASK_OPTS=--no-quarantine

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

    # All GNU utilities get prepended to the path
    cached_source "gnubins" "RESULT=''; for p in \$(find ${HOMEBREW_PREFIX}/Cellar/*/*/libexec -maxdepth 1 -type d -name gnubin); do RESULT=\"\${p}:\${RESULT}\"; done; echo export GNUBINS=\$RESULT"

    # GNUBINS has a trailing colon
    export PATH="$GNUBINS$PATH"

    # If using Homebrew asdf, install bash completion via zsh compatibility
    if [ -e $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh ]; then
        source $HOMEBREW_PREFIX/opt/asdf/libexec/asdf.sh
        #if [ -e $HOMEBREW_PREFIX/opt/asdf/etc/bash_completion.d/asdf.bash ]; then
        #    autoload -U +X compinit && compinit
        #    autoload bashcompinit
        #    bashcompinit
        #    source $HOMEBREW_PREFIX/opt/asdf/etc/bash_completion.d/asdf.bash
        #fi
    fi

    # Add Homebrew MySQL client to the PATH (prepended to prefer)
    if [[ -d $HOMEBREW_PREFIX/opt/mysql-client/bin ]]; then
        export PATH="$HOMEBREW_PREFIX/opt/mysql-client/bin:$PATH"
    fi

    # Add Homebrew OpenJDK to the PATH
    if [[ -d $HOMEBREW_PREFIX/opt/openjdk/bin ]]; then
        export PATH="$HOMEBREW_PREFIX/opt/openjdk/bin:$PATH"
    fi
fi

# ****************************************************************************************************
# Setup EDITOR
# ****************************************************************************************************

# Optimize for neovim Homebrew existing
if [ -e /opt/homebrew/bin/nvim ]; then
    export EDITOR="/opt/homebrew/bin/nvim"
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
alias neovim="$EDITOR"
alias nano="$EDITOR"
export GIT_EDITOR="$EDITOR"

# ****************************************************************************************************
# Setup Go
# ****************************************************************************************************

# Add Go binaries to the PATH
if [[ -d $HOME/go/bin ]]; then
    export PATH="$HOME/go/bin:$PATH"
fi

# ****************************************************************************************************
# Setup Ruby GEM_HOME and PATH for gems
# ****************************************************************************************************

if [[ -d $HOME/.gems ]]; then
    export GEM_HOME="$HOME/.gems"
    export PATH="$HOME/.gems/bin:$PATH"
fi

# Load iTerm2 shell integration if installed
#if [ -e "${HOME}/.iterm2_shell_integration.zsh" ]; then
#    source "${HOME}/.iterm2_shell_integration.zsh"
#fi

# ****************************************************************************************************
# Setup Python pyenv
# ****************************************************************************************************

# Load pyenv if it is installed
if [[ -d $HOME/.pyenv ]]; then
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    cached_source "pyenv" "pyenv init --path"
    #eval "$(pyenv init --path)"
fi

# ****************************************************************************************************
# Add custom scripts to the PATH
# ****************************************************************************************************

export PATH="$HOME/.scripts:$PATH"

# ****************************************************************************************************
# Custom aliases / helpers (use alias to show list of aliases)
# ****************************************************************************************************

# Always use neomutt
alias mutt='neomutt'

alias path="echo $PATH | cut -f 2 -d '=' | sed 's/:/\n/g'"

# Flatten a git repo
alias git-flatten='git reset $(git commit-tree HEAD^{tree} -m "Flatten")'

# Ping rapidly
alias fastping="ping -i 0.2"

# Show all open ports that aren't localhost
alias ports="sudo lsof -iTCP -sTCP:LISTEN -nP -b -M 2>/dev/null | grep -v -e 127.0.0 -e ::1]"

# Get current IPv4 address
alias checkip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

if [[ -d $HOME/.aws ]]; then
    alias aws-logout='aws sso logout ; rm -f $HOME/.aws/boto/*.json $HOME/.aws/boto/cache/*.json ; unset AWS_ACCESS_KEY_ID ; unset AWS_SECRET_ACCESS_KEY ; unset AWS_SESSION_TOKEN'
fi

# ****************************************************************************************************
# Neofetch
# ****************************************************************************************************

# If we have a neofetch output to display, display it
if [ -e "$HOME/.config/neofetch.txt" ]; then
    echo "$( <$HOME/.config/neofetch.txt)"
fi

# ****************************************************************************************************
# Disable error handling so it doesn't apply to scripts run in the shell
# ****************************************************************************************************

trap - ERR
