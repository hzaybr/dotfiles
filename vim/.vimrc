" Auto-install vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent execute '!curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" =============================================================================
" Plugins
" =============================================================================
" Disable polyglot's svelte in favor of vim-svelte
let g:polyglot_disabled = ['svelte']

call plug#begin('~/.vim/plugged')

" Theme
Plug 'fenetikm/falcon'

" Statusline
Plug 'vim-airline/vim-airline'
Plug 'vim-airline/vim-airline-themes'

" Fuzzy finder
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" File explorer
Plug 'preservim/nerdtree'

" Git
Plug 'tpope/vim-fugitive'
Plug 'airblade/vim-gitgutter'

" LSP / completion / linting / formatting
Plug 'neoclide/coc.nvim', { 'branch': 'release' }

" Auto pairs
Plug 'jiangmiao/auto-pairs'

" Copilot
Plug 'github/copilot.vim'

" Surround
Plug 'tpope/vim-surround'

" Comment
Plug 'tpope/vim-commentary'

" Syntax highlighting (vim has no treesitter)
Plug 'sheerun/vim-polyglot'
Plug 'evanleck/vim-svelte', { 'branch': 'main' }

" Markdown
Plug 'preservim/vim-markdown'

call plug#end()

" =============================================================================
" General Settings
" =============================================================================
set nocompatible
filetype plugin indent on
syntax on

" Encoding
set encoding=utf-8
set fileencoding=utf-8

" UI
set number
set norelativenumber
set cursorline
set showmatch
set signcolumn=yes
set laststatus=2
set showcmd
set wildmenu
set wildmode=longest:full,full
set scrolloff=8
set sidescrolloff=8
set termguicolors

" Cursor styles (terminal)
let &t_SI = "\e[6 q"  " insert: bar
let &t_EI = "\e[2 q"  " normal: block
let &t_SR = "\e[4 q"  " replace: underline

" Indentation
set tabstop=2
set shiftwidth=2
set softtabstop=2
set expandtab
set smartindent
set autoindent

" Search
set hlsearch
set incsearch
set ignorecase
set smartcase

" Performance
set updatetime=250
set timeoutlen=400
set lazyredraw
set ttyfast

" Files
set noswapfile
set nobackup
set nowritebackup
set undofile
set undodir=~/.vim/undodir
set autoread
set hidden

" Splits
set splitright
set splitbelow

" Backspace
set backspace=indent,eol,start

" Mouse
set mouse=a

" Clipboard
set clipboard=unnamedplus

" Theme
silent! colorscheme falcon

" Search highlight: bright background block instead of underline
highlight Search guibg=#ff8700 guifg=#000000 gui=NONE
highlight IncSearch guibg=#ffcc00 guifg=#000000 gui=NONE

" =============================================================================
" Key Mappings
" =============================================================================
let mapleader = " "

" Quick command mode
nnoremap ; :

" Quick escape
inoremap jj <ESC>

" Clear search highlight
nnoremap <ESC> :nohlsearch<CR>

" Better window navigation
nnoremap <C-h> <C-w>h
nnoremap <C-j> <C-w>j
nnoremap <C-k> <C-w>k
nnoremap <C-l> <C-w>l

" Resize splits
nnoremap <leader>= :resize +2<CR>
nnoremap <leader>- :resize -2<CR>
nnoremap <leader>, :vertical resize +2<CR>
nnoremap <leader>. :vertical resize -2<CR>

" Buffer navigation
nnoremap <Tab> :bnext<CR>
nnoremap <S-Tab> :bprevious<CR>
nnoremap <leader>bd :bdelete<CR>

" Move lines up/down
vnoremap J :m '>+1<CR>gv=gv
vnoremap K :m '<-2<CR>gv=gv

" Stay centered when scrolling
nnoremap <C-d> <C-d>zz
nnoremap <C-u> <C-u>zz

" =============================================================================
" Plugin Settings
" =============================================================================

" --- Markdown ---
let g:vim_markdown_folding_disabled = 1
let g:vim_markdown_conceal = 1
let g:vim_markdown_conceal_code_blocks = 0
let g:vim_markdown_frontmatter = 1
let g:vim_markdown_strikethrough = 1
let g:vim_markdown_no_extensions_in_markdown = 1
set conceallevel=2

" --- Svelte ---
let g:vim_svelte_plugin_use_typescript = 1

" --- Airline ---
let g:airline_powerline_fonts = 1
let g:airline#extensions#tabline#enabled = 1
let g:airline#extensions#tabline#formatter = 'unique_tail'

" --- NERDTree ---
nnoremap <leader>e :NERDTreeToggle<CR>
nnoremap <leader>fe :NERDTreeFind<CR>
let g:NERDTreeShowHidden = 1
let g:NERDTreeIgnore = ['\.git$', 'node_modules', '__pycache__', '\.pyc$']

" --- FZF ---
nnoremap <leader>ff :Files<CR>
nnoremap <leader>fg :Rg<CR>
nnoremap <leader>fb :Buffers<CR>
nnoremap <leader>fh :Helptags<CR>
nnoremap <leader>fo :History<CR>

" --- GitGutter ---
nnoremap ]c :GitGutterNextHunk<CR>
nnoremap [c :GitGutterPrevHunk<CR>
nnoremap <leader>hs :GitGutterStageHunk<CR>
nnoremap <leader>hr :GitGutterUndoHunk<CR>
nnoremap <leader>hp :GitGutterPreviewHunk<CR>

" --- coc.nvim ---
" Use Tab/S-Tab for completion navigation
inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm() : "\<CR>"
inoremap <silent><expr> <C-n> coc#pum#visible() ? coc#pum#next(1) : "\<C-n>"
inoremap <silent><expr> <C-p> coc#pum#visible() ? coc#pum#prev(1) : "\<C-p>"

" Trigger completion
inoremap <silent><expr> <C-Space> coc#refresh()

" Diagnostics navigation
nmap <silent> [d <Plug>(coc-diagnostic-prev)
nmap <silent> ]d <Plug>(coc-diagnostic-next)

" LSP navigation
nmap <silent> gd <Plug>(coc-definition)
nmap <silent> gy <Plug>(coc-type-definition)
nmap <silent> gi <Plug>(coc-implementation)
nmap <silent> gr <Plug>(coc-references)

" Hover documentation
nnoremap <silent> K :call ShowDocumentation()<CR>
function! ShowDocumentation()
  if CocAction('hasProvider', 'hover')
    call CocActionAsync('doHover')
  else
    call feedkeys('K', 'in')
  endif
endfunction

" Refactoring
nmap <leader>rn <Plug>(coc-rename)
nmap <leader>ca <Plug>(coc-codeaction-cursor)
nmap <leader>cf <Plug>(coc-fix-current)

" Format
nmap <leader>fm <Plug>(coc-format)
xmap <leader>fm <Plug>(coc-format-selected)

" Format on save (Python: black + isort)
autocmd BufWritePost *.py call s:FormatPython()
function! s:FormatPython()
  let l:file = expand('%:p')
  let l:modified = 0
  if executable('black')
    call system('black --quiet ' . shellescape(l:file) . ' 2>&1')
    if v:shell_error == 0 | let l:modified = 1 | endif
  endif
  if executable('isort')
    call system('isort --quiet ' . shellescape(l:file) . ' 2>&1')
    if v:shell_error == 0 | let l:modified = 1 | endif
  endif
  if l:modified | silent edit! | endif
endfunction
autocmd BufWritePre * if exists('g:coc_service_initialized') && expand('%:e') !~# '^\(py\|pyw\)$' | silent! call CocAction('format') | endif

" Show diagnostics list
nnoremap <leader>cd :CocDiagnostics<CR>

" Symbol search
nnoremap <leader>fs :CocList symbols<CR>

" --- Copilot ---
let g:copilot_no_tab_map = v:true
inoremap <C-v> <Plug>(copilot-accept)
inoremap <C-c> <Plug>(copilot-accept-word)
inoremap <C-g> <Plug>(copilot-accept-line)
inoremap <C-]> <Plug>(copilot-next)
inoremap <C-[> <Plug>(copilot-previous)
inoremap <C-x> <Plug>(copilot-dismiss)

" --- Fugitive ---
nnoremap <leader>gs :Git<CR>
nnoremap <leader>gb :Git blame<CR>
nnoremap <leader>gd :Gdiffsplit<CR>

" =============================================================================
" Autocommands
" =============================================================================
augroup vimrc
  autocmd!
  " Auto-reload files changed outside vim
  autocmd FocusGained,BufEnter * checktime
  " Remove trailing whitespace on save
  autocmd BufWritePre * %s/\s\+$//e
  " Return to last edit position
  autocmd BufReadPost * if line("'\"") > 1 && line("'\"") <= line("$") | exe "normal! g'\"" | endif
augroup END

" Create undo directory if missing
if !isdirectory($HOME . '/.vim/undodir')
  call mkdir($HOME . '/.vim/undodir', 'p')
endif
