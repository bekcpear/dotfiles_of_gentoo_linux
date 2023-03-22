nnoremap Y Y
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8

set backupdir=~/.cache/nvim/backup

set ts=2
set sw=2
set smarttab
set expandtab
set autoindent
set smartindent

"set lbr
set nu
set foldlevel=100
set foldmethod=syntax

set pastetoggle=<F7>

set cursorline
set autoread
set noerrorbells
set novisualbell
set hlsearch
set backspace=start,indent,eol

set mouse=

map <M-l> :tabnext<CR>
map <M-h> :tabprevious<CR>
map <M-j> :bnext<CR>
map <M-k> :bprevious<CR>
map <M-S-l> :tabm +1<CR>
map <M-S-h> :tabm -1<CR>

syntax on
colorscheme molokai

"lua require('plugins')
"lua require('coc') "strange problem when Tab, a <80> string inserted and stuck
call plug#begin()

" coc.nvim default release branch
Plug 'neoclide/coc.nvim', { 'branch': 'release' }
source ~/.config/nvim/coc.vim

" airline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'
let g:airline_theme = 'lessnoise'
let g:airline#extensions#searchcount#enabled = 0
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#branch#enabled = 1

" vim-go ======= START ====
Plug 'fatih/vim-go', { 'do': ':GoUpdateBinaries' }
"let g:go_def_mode = 'godef' " be very fast on resolving queries
let g:go_def_mode = 'gopls'
let g:go_decls_includes = "func,type"
let g:go_info_mode = 'gopls'
set ttimeoutlen=0
set autowrite
map <C-j> :cnext<CR>
map <C-k> :cprevious<CR>
autocmd FileType go nmap <leader>c :cclose<CR>

"map <M-j> :lnext<CR>
"map <M-k> :lprevious<CR>
"autocmd FileType go nmap <leader>l :lclose<CR>
" run :GoBuild or :GoTestCompile based on the go file
function! s:build_go_files()
  let l:file = expand('%')
  if l:file =~# '^\f\+_test\.go$'
    call go#test#Test(0, 1)
  elseif l:file =~# '^\f\+\.go$'
    call go#cmd#Build(0)
  endif
endfunction
":let mapleader = ","
autocmd FileType go nmap <leader>b :<C-u>call <SID>build_go_files()<CR>
autocmd FileType go nmap <leader>t  <Plug>(go-test)
autocmd FileType go nmap <leader>r  <Plug>(go-run)
autocmd FileType go nmap <Leader>i <Plug>(go-info)
"let g:go_auto_type_info = 1
"set updatetime=100
":GoSameIds / :GoSameIdsClear highlight same identifiers
"let g:go_auto_sameids = 1
let g:go_highlight_fields = 1
let g:go_highlight_functions = 1
"let g:go_highlight_function_calls = 1
let g:go_highlight_operators = 1
let g:go_highlight_types = 1
let g:go_highlight_extra_types = 1
let g:go_highlight_build_constraints = 1
let g:go_highlight_generate_tags = 1
"let g:go_metalinter_autosave = 1
"let g:go_metalinter_autosave_enabled = ['vet', 'golint']
"let g:go_metalinter_deadline = "5s"
let g:go_fmt_command = "goimports"
autocmd Filetype go command! -bang A call go#alternate#Switch(<bang>0, 'edit')
autocmd Filetype go command! -bang AV call go#alternate#Switch(<bang>0, 'vsplit')
autocmd Filetype go command! -bang AS call go#alternate#Switch(<bang>0, 'split')
autocmd Filetype go command! -bang AT call go#alternate#Switch(<bang>0, 'tabe')
" vim-go ======= END ====

call plug#end()

lua require('plugins')

set sessionoptions+=winpos,terminal,folds

" restore last position
if has("autocmd")
  augroup vimStartup
    au!
    autocmd BufReadPost *
      \ if line("'\"") >= 1 && line("'\"") <= line("$") |
      \   exe "normal! g`\"" |
      \ endif
  augroup END
endif

" python project root
autocmd FileType python let b:coc_root_patterns = ['.git', '.env']

" fcitx
"let g:fcitx5_rime = 1

set tw=0
