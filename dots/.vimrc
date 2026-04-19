
set nocompatible            " disable vi compatibility mode
syntax enable               " syntax highlighting
set encoding=utf-8
set fileencoding=utf-8
set number                  " show line numbers
set relativenumber          " relative numbers for easy motion (n lines up/down)

augroup numbertoggle
    autocmd!
    autocmd BufEnter,FocusGained,InsertLeave * set relativenumber number
    autocmd BufLeave,FocusLost,InsertEnter   * set norelativenumber number
augroup END
set ruler                   " show cursor position in status bar
set showcmd                 " show incomplete commands in the bottom bar
set showmatch               " highlight matching brackets

set expandtab               " use spaces, not tabs
set tabstop=4               " tab = 4 spaces visually
set softtabstop=4           " tab = 4 spaces when editing
set shiftwidth=4            " indent by 4 spaces with >> and <<
set smartindent
set autoindent
filetype plugin indent on   " language-specific indentation

set hlsearch                " highlight search matches
set incsearch               " search as you type
set ignorecase              " case-insensitive by default
set smartcase               " case-sensitive if query contains uppercase

set laststatus=2            " always show status line
set wildmenu                " tab-completion for commands
set wildmode=list:longest   " complete to longest common match
set scrolloff=8             " keep 8 lines visible above/below cursor
set sidescrolloff=8
set splitbelow              " horizontal splits open below
set splitright              " vertical splits open to the right
set backspace=indent,eol,start  " sensible backspace behaviour

set autoread                " reload file if changed externally

" Store swapfiles in a central location, not in the project directory
let s:swapdir = expand('~/.vim/tmp/swap')
if !isdirectory(s:swapdir)
    call mkdir(s:swapdir, 'p')
endif
let &directory = s:swapdir . '//'

set nobackup
set nowritebackup

