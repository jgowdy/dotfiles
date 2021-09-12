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
    alias openssl="/opt/homebrew/opt/openssl/bin/openssl"

    # File encrypt and decrypt with -in infile -out outfile
    alias enc="/opt/homebrew/opt/openssl/bin/openssl enc -chacha20 -pbkdf2"
    alias dec="/opt/homebrew/opt/openssl/bin/openssl enc -chacha20 -pbkdf2 -d"

    # Use gnuls on macOS
    alias ls="gls -laFG --color=auto"

    # Use gnugrep on macOS
    alias grep="ggrep --color=auto"

    # Use arm64 override for Homebrew for M1
    alias brew="arch -arm64 brew"

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
alias vim="lvim"
alias nvim="lvim"

# Launch lunarvim
alias l="lvim"

# Get current IPv4 address
alias ip="curl https://checkip.amazonaws.com"

# Deal with gpg-agent being unreliable
alias reset-gpg='gpgconf --kill gpg-agent'
alias test-gpg='echo “Test” | gpg --clearsign -v'

alias mutt='neomutt'

alias git-flatten='git reset $(git commit-tree HEAD^{tree} --gpg-sign -m "Flatten")'

alias wget="curl -O --retry 999 --retry-max-time 0 "

bindkey '^[[1;5C' forward-word # [Ctrl-RightArrow] - move forward one word
bindkey '^[[1;5D' backward-word # [Ctrl-LeftArrow] - move backward one word

export LANG=en_US.UTF-8
export TERMINAL='kitty'
export EDITOR='lvim'
export GIT_EDITOR='lvim'
export GPG_TTY=$(tty)
export PS1='%n@%m %1~ %# '
