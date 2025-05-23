function fish_prompt
    set_color green
    echo -n (whoami)'@'(hostname)':'(prompt_pwd)'$ '
    set_color normal
end 