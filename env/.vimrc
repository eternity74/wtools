set ic
set is
set nu
set ts=4 sw=4
set background=dark
set hlsearch
set laststatus=2
set et
set hidden
if &term == "xterm"
    set t_Co=256
endif
" Install vim-plug if we don't already have it
if empty(glob("~/.vim/autoload/plug.vim"))
    " Ensure all needed directories exist  (Thanks @kapadiamush)
    if empty(glob($HOME . "/.vim/plugged/"))
        echom $HOME . "/.vim/plugged"
        call mkdir($HOME . "/.vim/plugged","p")
    endif
    if empty(glob($HOME . "/.vim/autoload/"))
        call mkdir($HOME . "/.vim/autoload","p")
    endif
    " Download the actual plugin manager
    execute "!curl -fLo ~/.vim/autoload/plug.vim https://raw.github.com/junegunn/vim-plug/master/plug.vim"
endif
call plug#begin('~/.vim/plugged')
" My Plug {{{
"
" original repos on github
set rtp+=~/.fzf
Plug 'junegunn/fzf', { 'dir': '~/.fzf', 'do': './install --all' }
Plug 'junegunn/fzf.vim'
Plug 'easymotion/vim-easymotion'
Plug 'chazy/cscope_maps'
Plug 'vim-scripts/autoload_cscope.vim'
Plug 'vim-scripts/gtags.vim'
Plug 'vim-scripts/Mark--Karkat'
Plug 'vim-scripts/Tagbar'
Plug 'scrooloose/nerdtree'
Plug 'vim-scripts/Toggle-NERDTree-width'
Plug 'vim-scripts/fugitive.vim'
Plug 'junegunn/gv.vim'
Plug 'tpope/vim-unimpaired'
Plug 'vim-scripts/A.vim'
Plug 'vim-scripts/DirDiff.vim'
" Plug 'Shougo/neocomplcache.vim'
Plug 'lyuts/vim-rtags'
" Initialize plugin system
call plug#end()
" }}}
"
" Brief help
" :PlugInstall [name ...] [#threads]  Install plugins
" :PlugUpdate [name ...] [#threads]   Install or update plugins
" :PlugClean[!]   Remove unused directories (bang version will clean without prompt)
" :PlugUpgrade    Upgrade vim-plug itself
" :PlugStatus Check the status of plugins
" :PlugDiff   Examine changes from the previous update and the pending changes
" :PlugSnapshot[!] [output path]  Generate script for restoring the current snapshot of the plugins
" MyHelp {{{
let g:MyHelp="off"
fu! MyHelpToggle ()
    if g:MyHelp== "on"
        let g:MyHelp="off"
        bd "myhelp.txt"
    else
        let g:MyHelp="on"
        bo help myhelp
    endif
endfu
" }}}
" Key Mapping {{{
map <C-n> :NERDTreeToggle<CR>
nnoremap <silent> <F9> :TagbarToggle<CR>
nnoremap <silent> <F1> :call MyHelpToggle()<CR>
map <Leader>b :MiniBufExplorer<cr>
" }}}
" fzf configuration {{{
let g:fzf_colors =
\ { 'fg':      ['fg', 'Normal'],
  \ 'bg':      ['bg', 'Normal'],
  \ 'hl':      ['fg', 'Comment'],
  \ 'fg+':     ['fg', 'CursorLine', 'CursorColumn', 'Normal'],
  \ 'bg+':     ['bg', 'CursorLine', 'CursorColumn'],
  \ 'hl+':     ['fg', 'Statement'],
  \ 'info':    ['fg', 'PreProc'],
  \ 'prompt':  ['fg', 'Conditional'],
  \ 'pointer': ['fg', 'Exception'],
  \ 'marker':  ['fg', 'Keyword'],
  \ 'spinner': ['fg', 'Label'],
 \ 'header':  ['fg', 'Comment'] }
" }}}
" cscope configuration {{{
if has('cscope')
    if has('quickfix')
        set cscopequickfix=s-,c-,d-,i-,t-,e-,g-
        nnoremap <C-]>s :set cscopequickfix=s+<CR> :cs find s <C-R>=expand("<cword>")<CR><CR>
    endif
endif
" }}}
" ctrlp configuration {{{
command! ProjectFiles call s:myfzf()
" fzf sink function
function s:mysink(file)
    execute "e " .g:ctrlp_prj_dir.a:file
endfunction
" calling fzf with cscope.files
function s:myfzf()
    echom g:ctrlp_prj_dir . "/cscope.files"
    if filereadable(g:ctrlp_prj_dir . "/cscope.files")
        call fzf#run( fzf#wrap({
        \                        "source": "cat " . g:ctrlp_prj_dir . "/cscope.files",
        \                        "sink": function("s:mysink"),
        \                        "options":"--border --delimiter / --nth -1,..",
        \                        "down":"~40%"}))
    else
        call fzf#run( fzf#wrap({
        \                        "sink":"e",
        \                        "options":"--border --delimiter / --nth -1,..",
        \                        "down":"~40%"}))
    endif
endfunction
" setting prject root
function! SetCtrlpPrjDir()
  if exists('g:ctrlp_prj_dir') | retu | en
  let cph = expand('%:p:h', 1)
  if cph =~ '^.\+://' | retu | en
  for mkr in ['cscope.files']
    let wd = call('find'.(mkr =~ '/$' ? 'dir' : 'file'), [mkr, cph.';'])
    if wd != '' | let &acd = 0 | brea | en
  endfo
  let wd = fnamemodify(wd,":p")
  let g:ctrlp_prj_dir = fnameescape(wd == '' ? cph."/" : substitute(wd, mkr.'$', '', ''))
  if g:ctrlp_prj_dir == '' | let g:ctrlp_prj_dir = cph."/" | en
endfunction
call SetCtrlpPrjDir()
nnoremap <C-p> :ProjectFiles<CR>
" add path from .prjdirs
function s:myprjdirs(root)
    let prjdirs_file = a:root . ".prjdirs"
    if filereadable(prjdirs_file)
        let dirs = join(map(filter(readfile(prjdirs_file), 'v:val !~ "#"'),'a:root.v:val'),",")
        execute "set path+=".a:root.",".dirs
    endif
endfunction
call s:myprjdirs(g:ctrlp_prj_dir)
" }}}
" miniBufExplorer configuration {{{
    let g:miniBufExplShowBufNumbers = 10
" }}}
" NeoComplCacheEnable {{{
let g:neocomplcache_enable_at_startup = 1
" }}}
" Whitespace & EndingSpace Highlight {{{
highlight ExtraWhitespace ctermbg=red guibg=red
match ExtraWhitespace /\s\+$/
set list listchars=tab:›∙,trail:∙,extends:$,nbsp:= 
" }}}
" seperate viminfo/ctrlp session for screen window {{{
if filereadable("./.prjdirs") && 0
set viminfo+=n./.viminfo
let g:ctrlp_cache_dir = "./.ctrlp_cache"
elseif $STY != ''
set viminfo+=n~/.vim/.viminfo_${STY}.${WINDOW}
let g:ctrlp_cache_dir = "~/.cache/ctrlp_$STY.$WINDOW"
elseif $TMUX != ''
set viminfo+=n~/.vim/.viminfo_${TMUX_UNIQUE}
let g:ctrlp_cache_dir = "~/.cache/ctrlp_$TMUX_UNIQUE"
endif
" }}}
"
" mouse configuration {{{
"set mouse=a
"nmap <F3> :set nonu<CR> :set mouse=r<CR>
"nmap <F4> :set nu<CR> :set mouse=a<CR>
"map <ScrollWheelUp> <C-Y>
"map <ScrollWheelDown> <C-E>
" }}}
" vimcolor configuration {{{
hi DiffText   cterm=none ctermfg=Black ctermbg=Red gui=none guifg=Black guibg=Red
hi DiffChange cterm=none ctermfg=Black ctermbg=LightMagenta gui=none guifg=Black guibg=LightMagenta
" }}}
" vim:ft=vim:fdm=marker:ff=unix:nowrap:tabstop=4:shiftwidth=4:softtabstop=4:smarttab:shiftround:expandtab
