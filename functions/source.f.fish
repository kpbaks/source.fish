function source.f \
    --description 'Source a .fish file, and report what changes it made'
    # --argument-names file \

    set -l options (fish_opt --short=h --long=help)
    set -a options (fish_opt --short=q --long=quiet)
    if not argparse $options -- $argv
        return 2
    end

    if set --query _flag_help
        printf "Usage: source.f [options] file\n"
        printf "Source a .fish file, and report what changes it made\n"
        printf "\n"
        printf "Options:\n"
        printf "  -h, --help    Show this help message and exit\n"
        printf "  -q, --quiet   Don't print anything\n"
        return 0
    end

    set -l argc (count $argv)
    if test $argc -eq 0
        printf "source.f: missing file operand\n" >&2
        printf "Try 'source.f --help' for more information.\n" >&2
        return 2

    end

    set -l file $argv[1]
    if not test -f $file
        echo "$file is not a file" >&2
        return 1
    end

    set -l blue (set_color blue)
    set -l green (set_color green)
    set -l reset (set_color normal)
    set -l red (set_color red)
    set -l yellow (set_color yellow)

    set -l functions_before
    set -l abbrs_before
    set -l aliases_before
    set -l global_variables_before

    set -l indent "    "

    if not set --query _flag_quiet
        set abbrs_before (abbr --list)
        set aliases_before (alias | string split --fields 2 " ")
        set functions_before (functions)
        for alias in $aliases_before
            set -l idx (contains --index -- $alias $functions_before)
            if test -n $idx
                set -e functions_before[$idx]
            end
        end

        set global_variables_before (set --global | string split --fields 1 " ")
    end

    source $file
    set -l status_of_sourcing_file $status

    set -l functions_after
    set -l abbrs_after
    set -l aliases_after
    set -l global_variables_after
    if not set --query _flag_quiet
        set abbrs_after (abbr --list)
        set aliases_after (alias | string split --fields 2 " ")
        set functions_after (functions)
        for alias in $aliases_after
            set -l idx (contains --index -- $alias $functions_after)
            if test -n $idx
                set -e functions_after[$idx]
            end
        end

        set global_variables_after (set --global | string split --fields 1 " ")
    end

    # The rest of the function will print the changes made by the sourced file.
    # If the user passed the --quiet flag, we'll skip this.
    set --query _flag_quiet; and return 0

    set -l color $green
    if test $status_of_sourcing_file -ne 0
        set color $red
    end

    # Check if any functions were added or removed
    if test (count $functions_after) -ne (count $functions_before)
        set -l functions_added
        set -l functions_removed
        for func in $functions_before
            if not contains -- $func $functions_after
                set -a functions_removed $func
            end
        end
        for func in $functions_after
            if not contains -- $func $functions_before
                set -a functions_added $func
            end
        end

        if test (count $functions_removed) -gt 0
            printf "%s%d%s function%s removed:\n" \
                $color (count $functions_removed) $reset \
                (test (count $functions_removed) -eq 1; and echo ""; or echo "s")
            for func in $functions_removed
                printf "%s%s%s%s\n" $indent $red $func $reset
            end
        end

        if test (count $functions_added) -gt 0
            printf "%s%d%s new function%s:\n" \
                $color (count $functions_added) $reset \
                (test (count $functions_added) -eq 1; and echo ""; or echo "s")
            for func in $functions_added
                printf "%s%s%s%s\n" $indent (set_color "#$fish_color_keyword") $func $reset
            end
        end
    end

    # Check if any abbreviations were added, removed, or changed
    if test (count $abbrs_after) -ne (count $abbrs_before)
        set -l abbrs_added
        for abbr in $abbrs_after
            if not contains -- $abbr $abbrs_before
                set -a abbrs_added $abbr
            end
        end

        # TODO: <kpbaks 2023-08-05 23:16:59> show what the abbreviation expands to

        if test (count $abbrs_added) -gt 0
            printf "%s%d%s new abbreviation%s:\n" \
                $color (count $abbrs_added) $reset \
                (test (count $abbrs_added) -eq 1; and echo ""; or echo "s")
            for abbr in $abbrs_added
                printf "%s%s%s%s\n" $indent $blue $abbr $reset
            end
        end
    end

    # Check if any aliases were added or removed
    if test (count $aliases_after) -ne (count $aliases_before)
        set -l aliases_added
        set -l aliases_removed

        for alias in $aliases_before
            if not contains -- $alias $aliases_after
                set -a aliases_removed $alias
            end
        end
        for alias in $aliases_after
            if not contains -- $alias $aliases_before
                set -a aliases_added $alias
            end
        end

        if test (count $aliases_removed) -gt 0
            printf "%s%d%s alias%s removed:\n" \
                $color (count $aliases_removed) $reset \
                (test (count $aliases_removed) -eq 1; and echo ""; or echo "s")
            for alias in $aliases_removed
                printf "%s%s%s%s\n" $indent $red $alias $reset
            end
        end

        if test (count $aliases_added) -gt 0
            printf "%s%d%s new alias%s:\n" \
                $color (count $aliases_added) $reset \
                (test (count $aliases_added) -eq 1; and echo ""; or echo "s")

            for alias_added in $aliases_added
                alias \
                    | while read keyword alias expansion
                    test $alias = $alias_added; or continue
                    printf "%s%s%s%s -> " $indent (set_color "#$fish_color_keyword") $alias $reset
                    echo $expansion \
                        | string replace --regex "^'(.*)'\$" '$1' \
                        | fish_indent --ansi
                end
            end
        end
    end

    # TODO: <kpbaks 2023-08-05 23:16:11> show new global variables, global variables that changed, and global variables that were removed
    if test (count $global_variables_after) -ne (count $global_variables_before)
        set -l global_variables_added
        set -l global_variables_removed
        set -l global_variables_changed

        for var in $global_variables_before
            if not contains -- $var $global_variables_after
                set -a global_variables_removed $var
            else
                set -a global_variables_changed $var
            end
        end

        for var in $global_variables_after
            if not contains -- $var $global_variables_before
                set -a global_variables_added $var
            end
        end

        if test (count $global_variables_removed) -gt 0
            printf "%s%d%s global variable%s removed:\n" \
                $color (count $global_variables_removed) $reset \
                (test (count $global_variables_removed) -eq 1; and echo ""; or echo "s")


            for var in $global_variables_removed
                printf "%s%s%s%s\n" $indent $red $var $reset
            end
        end

        if test (count $global_variables_added) -gt 0
            printf "%s%d%s new global variable%s:\n" \
                $color (count $global_variables_added) $reset \
                (test (count $global_variables_added) -eq 1; and echo ""; or echo "s")

            for var in $global_variables_added
                printf "%s%s%s%s = %s\n" $indent $blue $var $reset $$var
            end
        end

        # if test (count $global_variables_changed) -gt 0
        #     echo "changed global variables:"
        #
        #     for var in $global_variables_changed
        #         printf "  %s%s%s\n" $yellow $var $reset
        #     end
        # end
    end
end
