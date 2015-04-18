vim-fnr
=======

Find-N-Replace in Vim with live preview (experimental)

Installation
------------

Use your favorite plugin manager. vim-fnr requires
[vim-pseudocl](https://github.com/junegunn/vim-pseudocl).

With [vim-plug](https://github.com/junegunn/vim-plug):

```vim
Plug 'junegunn/vim-pseudocl'
Plug 'junegunn/vim-fnr'
```

Usage
-----

- Normal mode
    - `<Leader>r<Movement>`
          - Substitution in the range
    - `<Leader>R`
          - Substitution of the word under the cursor in the entire document
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
xmap <Leader>r <Plug>(FNR)
nmap <Leader>R <Plug>(FNR%)
xmap <Leader>R <Plug>(FNR%)
```

License
-------

MIT

