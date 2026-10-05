_images_manager_completion() {
    local IFS=$'
'
    COMPREPLY=( $( env COMP_WORDS="${COMP_WORDS[*]}" \
                   COMP_CWORD=$COMP_CWORD \
                   _IMAGES_MANAGER_COMPLETE=complete_bash $1 ) )
    return 0
}

complete -o default -F _images_manager_completion images_manager