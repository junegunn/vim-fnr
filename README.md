vim-fnr
=======

Find-N-Replace in Vim with live preview

Installation
------------

Use your favorite plugin manager.

- [vim-plug](https://github.com/junegunn/vim-plug)
  1. Add `Plug 'junegunn/vim-fnr'` to .vimrc
  2. Run `:PlugInstall`

Usage
-----

- Normal mode
    - `<Leader>s<Movement>`
          - Substitution in the range
    - `<Leader>S`
          - Substitution in the entire document
- Visual mode
    - `<Leader>s`
          - Substitution in the selected range
    - `<Leader>S`
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
nmap <Leader>s <Plug>(FNR)
vmap <Leader>s <Plug>(FNR)
nmap <Leader>S <Plug>(FNR%)
vmap <Leader>S <Plug>(FNR%)
```

License
-------

MIT

