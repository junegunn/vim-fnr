vim-fnr
=======

Find-N-Replace in Vim with live preview (experimental)

Installation
------------

Use your favorite plugin manager.

- [vim-plug](https://github.com/junegunn/vim-plug)
  1. Add `Plug 'junegunn/vim-fnr'` to .vimrc
  2. Run `:PlugInstall`

Usage
-----

- Normal mode
    - `<Leader>r<Movement>`
          - Substitution in the range
    - `<Leader>R`
          - Substitution in the entire document
- Visual mode
    - `<Leader>r`
          - Substitution in the selected range
    - `<Leader>R`
          - Substitution of the selected string in the entire document
- Command line
    - `:<Range>FNR`

The command is repeatable with `.` key if you have installed
[repeat.vim](http://github.com/tpope/vim-repeat).

### Special keys

- `Tab`
    - `i` - case-insensitive match
    - `w` - word-boundary match (`\<STRING\>`)
    - `g` - substitute all occurrences
    - `c` - confirm each substitution
    - `Tab` or `Enter` to return
- `CTRL-N` or `CTRL-P`
    - Auto-completion

Options
-------

```vim
" Defaults
let g:fnr_flags   = 'gc'
let g:fnr_hl_from = 'Todo'
let g:fnr_hl_to   = 'IncSearch'
```

Custom mappings
---------------

```vim
nmap <Leader>r <Plug>(FNR)
vmap <Leader>r <Plug>(FNR)
nmap <Leader>R <Plug>(FNR%)
vmap <Leader>R <Plug>(FNR%)
```

License
-------

MIT

