function source.d --description 'Source all *.fish files in a directory'
    functions --query source.f; or return 1
    set -l options (fish_opt --short=h --long=help)
    set -a options (fish_opt --short=q --long=quiet)
    if not argparse $options -- $argv
        return 2
    end

    if set --query _flag_help
        set -l usage "$(set_color --bold)Source all *.fish files in a directory$(set_color normal)

$(set_color yellow)Usage:$(set_color normal) $(set_color blue)$(status current-command)$(set_color normal) [options] [DIR ...]

$(set_color yellow)Arguments:$(set_color normal)
	$(set_color green)DIR$(set_color normal)  Directory to source *.fish files from. Defaults to current directory.

$(set_color yellow)Options:$(set_color normal)
	$(set_color green)-h$(set_color normal), $(set_color green)--help$(set_color normal)      Show this help message and exit
	$(set_color green)-q$(set_color normal), $(set_color green)--quiet$(set_color normal)     Do not print sourced files"

        echo $usage
        return 0
    end

    set -l argc (count $argv)
    set -l dir $PWD
    if test $argc -gt 0
        set dir $argv[1]
    else
        echo "No directory specified. Using current directory '$dir'"
    end

    if not test -d $dir
        echo "Directory '$dir' does not exist"
        printf "see: %s --help\n" (status current-function)
        return 1
    end
    set -l N (count $dir/*.fish)

    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l yellow (set_color yellow)

    if test $N -eq 0
        echo "No *.fish files found in '$dir'"
        printf "see: %s --help\n" (status current-function)
        return 1
    end

    set -l success_emojies 🎉 🎊 😎 👍 👌
    set -l error_emojies 😥 😭 😱 😨 😰 😓
    set -l i 1
    for file in $dir/*.fish
        test -r $file; or continue
        set -l line (printf "[%d/%d] sourcing %s%s%s ..." $i $N $blue $file $reset)
        if not set --query _flag_quiet
            printf "%s" $line
        end
        source.f $file
        set -l status_of_sourcing_file $status

        if not set --query _flag_quiet
            set -l color $blue
            # set -l emoji "✅"
            set emoji (random choice $success_emojies)
            if test $status_of_sourcing_file -ne 0
                set color $red
                # set emoji "❌"
                set emoji (random choice $error_emojies)
            end
            printf "\r%s" (string repeat --count (string length $line) " ") # clear line
            printf "\r[%d/%d] sourced %s%s%s %s\n" $i $N $color $file $reset $emoji
        end

        set i (math $i + 1)
    end
end
