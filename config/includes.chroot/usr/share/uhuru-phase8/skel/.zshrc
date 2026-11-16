# Uhuru OS - zsh ya msanidi: mapendekezo, rangi, historia bora na prompt yenye git.
# Hariri faili hii upendavyo; haitabadilishwa na masasisho.
[[ -o interactive ]] || return 0

mkdir -p "$HOME/.cache" 2>/dev/null

# --- historia
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt AUTO_CD HIST_IGNORE_ALL_DUPS HIST_IGNORE_SPACE HIST_REDUCE_BLANKS SHARE_HISTORY INC_APPEND_HISTORY
setopt EXTENDED_GLOB INTERACTIVE_COMMENTS PROMPT_SUBST NO_BEEP

# --- ukamilishaji (Tab)
autoload -Uz compinit
compinit -u -d "$HOME/.cache/zcompdump"
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh-comp"

# --- funguo
bindkey -e
autoload -Uz up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search 2>/dev/null
zle -N down-line-or-beginning-search 2>/dev/null
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search
bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[3~' delete-char
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word

# --- aliases na kazi za pamoja
[ -f "$HOME/.config/uhuru/shell-common.sh" ] && . "$HOME/.config/uhuru/shell-common.sh"

# --- fzf (Ctrl+R, Ctrl+T, Alt+C) na zoxide (z)
for f in /usr/share/doc/fzf/examples/key-bindings.zsh /usr/share/doc/fzf/examples/completion.zsh; do
    [ -f "$f" ] && . "$f"
done
command -v zoxide >/dev/null 2>&1 && eval "$(zoxide init zsh)"

# --- prompt: mtumiaji@kompyuta  folda  (tawi-la-git)
autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' formats ' (%b)'
zstyle ':vcs_info:git:*' actionformats ' (%b|%a)'
precmd() { vcs_info }
PROMPT='%B%F{214}%n%f%b%F{244}@%f%F{45}%m%f %F{114}%~%f%F{176}${vcs_info_msg_0_}%f
%(?.%F{214}.%F{196})❯%f '

# --- salamu
print -P "%B%F{214}Uhuru OS 1.0%f%b  -  Letema Group Tech   %F{244}(andika %Bmsaada%b%F{244} kupata mwongozo)%f"

# --- plugins (syntax-highlighting lazima iwe ya mwisho)
[ -f /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && . /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh
[ -f /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && . /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
