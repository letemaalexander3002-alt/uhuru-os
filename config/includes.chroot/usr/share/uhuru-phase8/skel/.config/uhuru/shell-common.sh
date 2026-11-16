# Uhuru OS: mipangilio ya pamoja ya shell (bash na zsh) - Uhuru Dev Edition.
# Faili hii inabadilishwa na masasisho; mabadiliko yako yaweke kwenye ~/.zshrc au ~/.bashrc.
case $- in *i*) ;; *) return 0 2>/dev/null || exit 0 ;; esac

export EDITOR="${EDITOR:-nvim}"
export VISUAL="$EDITOR"
export LESS="-FRX"
export HISTCONTROL=ignoreboth
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) PATH="$HOME/.local/bin:$HOME/.npm-global/bin:$PATH" ;; esac
export PATH

alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias l='ls -CF --color=auto'
if command -v exa >/dev/null 2>&1; then
    alias ls='exa --group-directories-first'
    alias ll='exa -lah --group-directories-first --git'
    alias tree='exa --tree --level=3'
fi
alias grep='grep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
command -v fdfind >/dev/null 2>&1 && alias fd='fdfind'
command -v batcat >/dev/null 2>&1 && alias bat='batcat'
command -v nvim >/dev/null 2>&1 && alias v='nvim'

alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gc='git commit'
alias gp='git push'
alias gl='git pull'
alias gd='git diff'
alias glog='git log --oneline --graph --decorate -20'
alias ports='ss -tulpn'

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
serve() { python3 -m http.server "${1:-8000}"; }
extract() {
    [ -f "$1" ] || { echo "extract: faili '$1' haipo"; return 1; }
    case "$1" in
        *.tar.gz|*.tgz)   tar xzf "$1" ;;
        *.tar.bz2|*.tbz2) tar xjf "$1" ;;
        *.tar.xz|*.txz)   tar xJf "$1" ;;
        *.tar)            tar xf "$1" ;;
        *.zip)            unzip "$1" ;;
        *.7z)             7z x "$1" ;;
        *.gz)             gunzip "$1" ;;
        *.xz)             unxz "$1" ;;
        *) echo "extract: aina ya faili haijulikani: $1"; return 1 ;;
    esac
}
