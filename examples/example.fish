
set -g global_variable "global variable"
set -g global_variable2 "global variable2"

alias hahaha="echo hahaha"
alias hahaha2="echo hahaha2"
alias forloop="for i in (seq 10); echo $i; end"

abbr -a hahaha3 "echo hahaha3"
abbr -a hahaha4 "echo hahaha4"

function new_function
    echo "new function"
end

function new_function2
    echo "new function2"
end
