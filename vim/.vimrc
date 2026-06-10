" ~/.vimrc — legible defaults for the lightweight scratch/diff `vim` column of the
" coding command center (com.slicedlabs.coding-edit, `zj vim`) and any plain `vim`
" pane (e.g. research `vim NOTES.md`). The dense deck editor is Neovim/LazyVim with
" its own config; plain vim shipped with NO user config (only /etc/vimrc's one-line
" archlinux.vim) → the 16-colour default scheme is illegible on the cockpit's
" charcoal background. This makes plain vim readable and consistent. Neovim ignores
" this file. Keep it minimal — this is a scratch/diff surface, not a second IDE.

set nocompatible
if has('termguicolors')
  set termguicolors            " 24-bit colour so the scheme matches the themed pane
endif
syntax on
filetype plugin indent on
set background=dark
" SlicedLabs Liquid Retina scheme (rendered from tokens.toml via render-templates
" into ~/.vim/colors/slicedlabs.vim); habamax = the no-render fallback.
silent! colorscheme slicedlabs
if !exists('g:colors_name') || g:colors_name !=# 'slicedlabs'
  silent! colorscheme habamax  " dark, legible, ships with vim >= 8.2 (no plugins)
endif

set number
set cursorline
set ruler
set showcmd
set laststatus=2
set scrolloff=4

set incsearch
set hlsearch
set ignorecase
set smartcase

set mouse=a
set clipboard=unnamedplus      " share the Wayland clipboard (wl-clipboard)
set expandtab
set shiftwidth=4
set softtabstop=4
set splitright
set splitbelow                 " :vert diffsplit opens to the right — the diff use case
set diffopt+=iwhite,vertical
set hidden
set wildmenu
set backspace=indent,eol,start
