
" █░█ █ █▀▄▀█ █░█░█ █ █▄▀ █ 
" ▀▄▀ █ █░▀░█ ▀▄▀▄▀ █ █░█ █ 

" Custom VimWiki setup

" Required VimWiki settings
set nocompatible
filetype plugin on
syntax on

" Vault settings
let vault = {}
let vault.path = '$HOME/Documents/Vault/content'
let vault.index = '_index'
let vault.ext = '.md'
let vault.syntax = 'markdown'

" Cozy wiki settings
let cozy = {}
let cozy = {}
let cozy.path = '$HOME/Documents/Cozy/content'
let cozy.index = '_index'
let cozy.ext = '.md'
let cozy.syntax = 'markdown'

let vault.conceal_pre = 1
let vault.vimwiki_toc_link_format = 1 " Brief

" Show wikilinks whose targets are not found
let vault.maxhi = 1

let vault.nested_syntaxes = { 'lua': 'lua', 'sh': 'bash', 'c': 'c', 'python': 'python' }

let g:vimwiki_list = [ vault, cozy ]
let g:vimwiki_toc_header = 'contents'

" Define custom header colors
let g:vimwiki_hl_headers = 1
hi VimwikiHeader1 guifg=#bf616a
hi VimwikiHeader2 guifg=#d08770
hi VimwikiHeader3 guifg=#ebcb8b
hi VimwikiHeader4 guifg=#a3be8c
hi VimwikiHeader5 guifg=#b48ead
hi VimwikiHeader6 guifg=#8fbcbb

" Source other files
let vimwiki_cfg_dir = '$HOME/.config/nvim/lua/plugins/config/vimwiki/'
let autoheader = vimwiki_cfg_dir . 'autoheader.vim'
let links = vimwiki_cfg_dir . 'links.vim'
let autocommit = vimwiki_cfg_dir . 'autocommit.vim'
let blankline = vimwiki_cfg_dir . 'blankline-toggle.vim'

exe 'source ' . autoheader
exe 'source ' . autocommit
exe 'source ' . blankline
exe 'source ' . links

