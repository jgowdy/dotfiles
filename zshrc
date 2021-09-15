HISTSIZE=1000000000
SAVEHIST=1000000000
HISTFILE=~/.zsh_history

# OS specific aliases
if [[ "$OSTYPE" == "darwin"* ]]; then

    # Attempt to force the use of arm64 binaries
    #ARCHPREFERENCE="arm64e;arm64;x86_64;i486"
    #if [ `machine` != arm64e ]; then
    #    exec arch -arm64e zsh
    #fi

    # Use Homebrew version of openssl binary
    if [ -f /opt/homebrew/opt/openssl/bin/openssl ]; then
	alias openssl="/opt/homebrew/opt/openssl/bin/openssl"
    fi

    # File encrypt and decrypt with -in infile -out outfile
    alias enc="/opt/homebrew/opt/openssl/bin/openssl enc -chacha20 -pbkdf2"
    alias dec="/opt/homebrew/opt/openssl/bin/openssl enc -chacha20 -pbkdf2 -d"

    # Use gnuls on macOS if it exists
    if which gls 2>&1 >/dev/null; then
        alias ls="gls -laFG --color=auto"
    else
        alias ls="ls -laFG"
    fi

    # Use gnugrep on macOS
    if which ggrep 2>&1 >/dev/null; then
        alias grep="ggrep --color=auto"
    fi

    # Use arch -64 override to fix Homebrew for M1
    alias brew="arch -64 brew"

    # Image-cat for kitty
    alias icat="kitty +kitten icat"

    # SSH with kitty termcap
    alias kssh="kitty +kitten ssh"

    alias d="kitty +kitten diff"

    # Launch browsers
    alias brave="\"/Applications/Brave Browser.app/Contents/MacOS/Brave Browser\""
    alias safari="/Applications/Safari.app/Contents/MacOS/Safari"

    export BROWSER='brave'

    export JAVA_HOME=$(/usr/libexec/java_home -v11)
else
    alias ls="ls -laFG --color=auto"

    # File encrypt and decrypt with -in infile -out outfile
    alias enc="/home/linuxbrew/.linuxbrew/bin/openssl enc -chacha20 -pbkdf2"
    alias dec="/home/linuxbrew/.linuxbrew/bin/openssl enc -chacha20 -pbkdf2 -d"

    export BROWSER='firefox'
fi

# Universal aliases

# We always use podman
alias docker=podman

# Vim is always lunarvim
alias vim="nvim"

# Launch lunarvim
lias l="lvim"

# Get current IPv4 address
alias ip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

alias mutt='neomutt'

alias git-flatten='git reset $(git commit-tree HEAD^{tree} --gpg-sign -m "Flatten")'

alias fastping="ping -i 0.2"

alias ports="sudo netstat -ant -p TCP | grep LISTEN"

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word

export LANG=en_US.UTF-8
export TERMINAL='kitty'
export EDITOR='lvim'
export GIT_EDITOR='lvim'
export GPG_TTY=$(tty)
export PS1='%n@%m %1~ %# '
