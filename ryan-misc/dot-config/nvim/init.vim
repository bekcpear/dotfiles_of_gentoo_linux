nnoremap Y Y
set encoding=utf-8
set termencoding=utf-8
set fileencoding=utf-8

set backupdir=~/.cache/nvim/backup

set noexpandtab
"set expandtab
"set sts=0
set ts=4
set sw=4
set autoindent
set smarttab
set smartindent

"set lbr
set nu
set foldlevel=100
set foldmethod=syntax

set pastetoggle=<F7>

set cursorline
set cursorcolumn
set autoread
set noerrorbells
set novisualbell
set hlsearch
set backspace=start,indent,eol

"set list lcs+=trail:␣
set mouse=
set textwidth=80
set colorcolumn=+1,+2,+3,+4,+5,+6,+7,+8,+9,+10,+11,+12,+13,+14,+15,+16

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
" patch coc diagnostic to unset the linehl for sign every time updated
" !sed -i 's/ linehl=Coc\${i}Line//' ~/.local/share/nvim/plugged/coc.nvim/build/index.js
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

Plug 'Thyrum/vim-stabs'
let g:stabs_maps = ''

Plug 'easymotion/vim-easymotion'

"Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}

Plug 'mg979/vim-visual-multi', {'branch': 'master'}

Plug 'gentoo/gentoo-syntax'
"Plug 'dense-analysis/ale'

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

	augroup autoSaveSession
		au!
		au BufWritePost,TabEnter,ExitPre * SaveSession
	augroup END
endif

" python project root
autocmd FileType python let b:coc_root_patterns = ['.git', '.env']

" fcitx
"let g:fcitx5_rime = 1

lua require('init')

" for nvim-tree
noremap <C-p> :NvimTreeToggle<CR>

function! SwitchSpaces2Tabs(sz)
	exe '%s/^ \{'.a:sz.'\}/\t/'
	while search('^\t\+ \{'.a:sz.'\}') > 0
		exe '%s/^\(\t\+\) \{'.a:sz.'\}/\1\t/'
	endwhile
endfunction
command -nargs=1 Ss2tab call SwitchSpaces2Tabs(<args>)

" workaround to set high priority of cursor line
" https://github.com/neovim/neovim/issues/9019#issuecomment-714806259
function! s:CustomizeColors()
	if has('gui_running') || &termguicolors || exists('g:gonvim_running')
		hi CursorLine ctermfg=white
	else
		hi CursorLine guifg=white
	endif
endfunction

augroup OnColorScheme
	autocmd!
	autocmd ColorScheme,BufEnter,BufWinEnter * call s:CustomizeColors()
augroup END

" for indent_blankline
"let g:indent_blankline_char_list = ['│', '┆', '┊']
"let g:indent_blankline_char = '┊'
"hi IndentBlanklineChar guifg=#323334 gui=nocombine

" for ale
"let g:ale_disable_lsp = 1

