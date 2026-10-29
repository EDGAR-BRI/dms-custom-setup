source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end

# opencode
fish_add_path /home/edgar/.opencode/bin

# SSH agent
set -x SSH_AUTH_SOCK /run/user/1000/ssh-agent.socket
#alias ant='antigravity-ide'


# Added by Antigravity CLI installer
set -gx PATH "/home/edgar/.local/bin" $PATH

# >>> railway initialize >>>
set -gx PATH '/tmp/opencode/railway-bin' $PATH
# <<< railway initialize <<<
alias obsidian-sync="/home/edgar/.local/bin/obsidian-drive-sync.sh"
alias hotspot-on  "sudo systemctl start hotspot"
alias hotspot-off "sudo systemctl stop hotspot"
alias hotspot-status "sudo systemctl status hotspot"
fnm env --use-on-cd --shell fish | source

# FAAA: suena cuando un comando falla en una terminal del sistema.
# En las terminales del IDE (TERM_PROGRAM=vscode) lo hace la extensión avisharma.faaa.
set -q FAAA_SOUND; or set -gx FAAA_SOUND "$HOME/.local/share/faaa/faaa.mp3"
function __faaa_fail_sound --on-event fish_postexec
    set -l st $status
    test $st -eq 0; and return
    test $st -eq 130; and return
    test "$TERM_PROGRAM" = vscode; and return
    test -f "$FAAA_SOUND"; or return
    if type -q mpg123
        command mpg123 -q "$FAAA_SOUND" </dev/null >/dev/null 2>&1 &
        disown $last_pid
    else if type -q ffplay
        command ffplay -nodisp -autoexit -loglevel quiet "$FAAA_SOUND" </dev/null >/dev/null 2>&1 &
        disown $last_pid
    end
end
