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

        # TODO: <kpbaks 2023-08-05 23:12:47> maybe test if global variables changes?
        # use set --global --long
        set global_variables_before (set --global | string split --fields 1 " ")
    end
    # echo "aliases before:"
    # printf " - %s\n" $aliases_before
    # echo "functions before:"
    # printf " - %s\n" $functions_before
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
            echo "removed functions:"
            for func in $functions_removed
                printf "  %s%s%s\n" $red $func $reset
            end
        end

        if test (count $functions_added) -gt 0
            echo "new functions:"
            for func in $functions_added
                printf "  %s%s%s\n" (set_color "#$fish_color_keyword") $func $reset
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
			echo "new abbreviations:"
		end
        for abbr in $abbrs_added
            printf "  %s%s%s\n" $blue $abbr $reset
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
            echo "removed aliases:"
            for alias in $aliases_removed
                printf "  %s%s%s\n" $red $alias $reset
            end
        end

        if test (count $aliases_added) -gt 0
            echo "new aliases:"

            for alias_added in $aliases_added
                alias \
                    | while read keyword alias expansion
                    test $alias = $alias_added; or continue
                    printf "  %s%s%s -> " (set_color "#$fish_color_keyword") $alias $reset
                    echo $expansion \
					| fish_indent --ansi
					# | string replace --regex "^'(.*)'\$" '$1' \
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
            echo "removed global variables:"
            for var in $global_variables_removed
                printf "  %s%s%s\n" $red $var $reset
            end
        end

        if test (count $global_variables_added) -gt 0
            echo "new global variables:"

            for var in $global_variables_added
                printf "  %s%s%s\n" $blue $var $reset
            end
        end

        if test (count $global_variables_changed) -gt 0
            echo "changed global variables:"

            for var in $global_variables_changed
                printf "  %s%s%s\n" $yellow $var $reset
            end
        end
    end
end
