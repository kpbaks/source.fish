function source.d --description 'Source all *.fish files in a directory'
    functions --query source.f; or return 1

    set -l options h/help q/quiet
    if not argparse $options -- $argv
        eval (status function) --help
        return 2
    end

    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l yellow (set_color yellow)
    set -l cyan (set_color cyan)
    set -l bold (set_color --bold)

    if set --query _flag_help
        set -l option_color $green
        set -l section_title_color $yellow
        # Overall description of the command
        printf "%sSource all *.fish files in a directory%s\n" $bold $reset >&2
        printf "\n" >&2
        # Usage
        printf "%sUSAGE:%s %s%s%s [options] [DIR ...]\n" $section_title_color $reset (set_color $fish_color_command) (status current-command) $reset >&2
        printf "\n" >&2
        # Description of the options and flags
        printf "%sOPTIONS:%s\n" $section_title_color $reset >&2
        printf "\t%s-h%s, %s--help%s      Show this help message and exit\n" $option_color $reset $option_color $reset >&2
        printf "\t%s-q%s, %s--quiet%s     Do not print sourced files\n" $option_color $reset $option_color $reset >&2

        printf "\n" >&2
        __source.fish::help_footer >&2
        return 0
    end

    set -l dir $PWD
    if test (count $argv) -gt 0
        set dir $argv[1]
    else
        printf "No directory specified. Using current directory %s$dir%s\n" (set_color --italic blue) $reset >&2
    end

    if not test -d $dir
        printf "%serror%s%s directory '$dir' does not exist" $red $reset >&2
        printf "try: %s%s\n" (printf (echo "$(status current-function) --help" | fish_indent --ansi))
        return 2
    end

    set -l N (count $dir/{,functions/,conf.d/,completions/}*.fish)

    if test $N -eq 0
        printf "%serror%s: no *.fish files found in %s$dir%s\n" $red $reset (set_color --italic blue) $reset >&2
        printf "try: %s%s\n" (printf (echo "$(status current-function) --help" | fish_indent --ansi))
        return 1
    end

    set -l success_emojies 🎉 🎊 😎 👍 👌
    set -l error_emojies 😥 😭 😱 😨 😰 😓
    set -l i 1
    set -l t_total 0.0
    for file in $dir/*.fish $dir/{functions,conf.d,completions}/*.fish
        test -r $file; or continue
        set -l line (printf "[%d/%d] sourcing %s%s%s ..." $i $N $blue $file $reset)
        if not set --query _flag_quiet
            printf "%s" $line
        end
        set -l t_start (date +%s.%N)
        set -l update (source.f $file)
        set -l status_of_sourcing_file $status
        set -l t_end (date +%s.%N)
        set -l t_diff (math $t_end - $t_start)
        # Accumelate into a total, that is displayed at the end
        set t_total (math "$t_total + $t_diff")
        # set -l t $CMD_DURATION

        if not set --query _flag_quiet
            set -l color
            # set -l emoji "✅"
            set -l emoji
            if test $status_of_sourcing_file -ne 0
                set color $red
                # set emoji "❌"
                set emoji (random choice $error_emojies)
            else
                set color $green
                set emoji (random choice $success_emojies)
            end
            printf "\r%s" (string repeat --count (string length $line) " ") # clear line
            printf "\r[%d/%d] sourced %s%s%s %s in %s seconds\n" $i $N $color $file $reset $emoji $t_diff

            if string length -- $update >/dev/null
                printf "%s\n" $update
            end
        end

        set i (math $i + 1)
    end

    if not set --query _flag_quiet
        printf "Took %s%s%s seconds in total\n" $cyan $t_total $reset
    end
end
