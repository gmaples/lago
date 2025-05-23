set fish_cursor_default block
set fish_cursor_insert line
set fish_cursor_replace_one underscore
set fish_cursor_visual block

function fish_prompt
    set_color green
    echo -n (whoami)'@'(hostname)':'(prompt_pwd)'$ '
    set_color normal
end 