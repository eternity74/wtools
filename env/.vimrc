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

" To install vundle
" git clone https://github.com/gmarik/vundle.git  ~/.vim/bundle/vundle
" :BundleInstall
" Configuration for bundle itself {{{
set nocompatible
filetype off

set rtp+=~/.vim/bundle/vundle/
call vundle#rc()

" Let Vundle manage Vundle
" requried!
Bundle 'gmarik/vundle'

" }}}

" My Bundles {{{
"
" original repos on github
"Bundle 'minibufexpl.vim'
"Bundle 'fholgado/minibufexpl.vim'
Bundle 'EasyMotion'
Bundle 'chazy/cscope_maps'
Bundle 'autoload_cscope.vim'
Bundle 'gtags.vim'
Bundle 'Mark--Karkat'
"Bundle 'cscope_macros.vim'
Bundle 'Tagbar'
"Bundle 'ctrlp.vim'
Bundle 'ctrlpvim/ctrlp.vim'
Bundle 'scrooloose/nerdtree'
Bundle 'Toggle-NERDTree-width'

Bundle 'fugitive.vim'
Bundle 'unimpaired.vim'
Bundle 'A.vim'
Bundle 'Shougo/neocomplcache.vim'
"Bundle 'Shougo/unite.vim'
"Bundle 'Shougo/neomru.vim'
"Bundle 'bling/vim-airline'


" non github repos
"Bundle 'git://git.wincent.com/command-t.git'
"Bundle 'git://localhost/wvim.git'
" ...

" }}}

filetype plugin on "required!
"
" Brief help
" :BundleList          - list configured bundles
" :BundleInstall(!)    - install(update) bundles
" :BundleSearch(!) foo - search(or refresh cache first) for foo
" :BundleClean(!)      - confirm(or auto-approve) removal of unused bundles
"
" see :h vundle for more details or wiki for FAQ
" NOTE: comments after Bundle command are not allowed..

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

" cscope configuration {{{
if has('cscope')
    if has('quickfix')
        set cscopequickfix=s-,c-,d-,i-,t-,e-,g-
        nnoremap <C-]>s :set cscopequickfix=s+<CR> :cs find s <C-R>=expand("<cword>")<CR><CR>
    endif
endif
" }}}

" ctrlp configuration {{{

let g:ctrlp_by_filename = 1
let g:ctrlp_user_command = ['cscope.files', 'cd %s&& cat cscope.files']
let g:ctrlp_max_files = 0
let g:ctrlp_lazy_update = 1
let g:ctrlp_max_height = 20
let g:ctrlp_use_caching = 0
let g:ctrlp_match_window = 'results:100' " overcome limit imposed by max height

function! SetCtrlpPrjDir()
  if exists('g:ctrlp_prj_dir') | retu | en
  let cph = expand('%:p:h', 1)
  if cph =~ '^.\+://' | retu | en
  for mkr in ['cscope.files']
    let wd = call('find'.(mkr =~ '/$' ? 'dir' : 'file'), [mkr, cph.';'])
    if wd != '' | let &acd = 0 | brea | en
  endfo
  let g:ctrlp_prj_dir = fnameescape(wd == '' ? cph : substitute(wd, mkr.'$', '.', ''))
endfunction

call SetCtrlpPrjDir()
let g:ctrlp_cmd = 'CtrlP ' . g:ctrlp_prj_dir


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

" vim:ft=vim:fdm=marker:ff=unix:nowrap:tabstop=4:shiftwidth=4:softtabstop=4:smarttab:shiftround:expandtab
