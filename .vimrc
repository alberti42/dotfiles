set tabstop=2 softtabstop=2 shiftwidth=2
set expandtab
set number ruler
set autoindent smartindent
set relativenumber
set number

" The following commands set the cursor shape
" depending on the vim-mode
let &t_ti.="\e[1 q"
let &t_SI.="\e[5 q"
let &t_EI.="\e[1 q"
let &t_te.="\e[0 q"

syntax enable
filetype plugin indent on
