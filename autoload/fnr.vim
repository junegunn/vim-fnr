" Copyright (c) 2014 Junegunn Choi
"
" MIT License
"
" Permission is hereby granted, free of charge, to any person obtaining
" a copy of this software and associated documentation files (the
" "Software"), to deal in the Software without restriction, including
" without limitation the rights to use, copy, modify, merge, publish,
" distribute, sublicense, and/or sell copies of the Software, and to
" permit persons to whom the Software is furnished to do so, subject to
" the following conditions:
"
" The above copyright notice and this permission notice shall be
" included in all copies or substantial portions of the Software.
"
" THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
" EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
" MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
" NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
" LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
" OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
" WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

let s:cpo_save = &cpo
set cpo&vim

hi FNRCursor term=inverse cterm=inverse gui=inverse

let s:previous      = ''
let s:need_repeat   = 0
let s:repeat_entire = 0

function! s:hide_cursor()
  if !exists('s:t_ve')
    let s:t_ve = &t_ve
    set t_ve=
  endif
  " TODO: GVIM
endfunction

function! s:display_cursor()
  if exists('s:t_ve')
    let &t_ve = s:t_ve
    unlet s:t_ve
  endif
endfunction

function! s:echo_cursor(hl, str)
  execute 'echohl ' . a:hl
  try
    if s:cursor == len(a:str)
      echon a:str
      echohl FNRCursor
      echon ' '
      return 1
    else
      if s:cursor > 0
        echon strpart(a:str, 0, s:cursor)
      end
      echohl FNRCursor
      echon strpart(a:str, s:cursor, 1)

      execute 'echohl ' . a:hl
      echon strpart(a:str, s:cursor + 1)
      return 0
    endif
  finally
    echohl None
  endtry
endfunction

function! s:mode_string()
  let str = ''
  for m in ['i', 'w', 'g', 'c']
    let str .= s:mode =~ m ? m : '_'
  endfor
  return '('.str.')'
endfunction

function! s:toggle_mode(o)
  if s:mode =~ a:o | let s:mode  = substitute(s:mode, a:o, '', 'g')
  else             | let s:mode .= a:o
  endif
endfunction

function! s:input(prompt, default)
  try
    call s:display_cursor()
    return input(a:prompt, a:default)
  finally
    call s:hide_cursor()
  endtry
endfunction

function! g:_fnr_on_unknown_key(key, str, cursor)
  if a:key == "\<tab>"
    let ophase = s:phase
    let s:phase = s:phase.'m'
    while 1
      call g:_fnr_render('', '', '')
      let ch = nr2char(getchar())
      if ch == 'g'          | call s:toggle_mode('g')
      elseif ch == 'c'      | call s:toggle_mode('c')
      elseif ch == 'i'      | call s:toggle_mode('i')
      elseif ch == 'w'      | call s:toggle_mode('w')
      elseif ch == "\<C-C>" | throw 'exit'
      elseif ch == "\<Tab>" || ch == "\<Enter>"
        let s:phase = ophase
        break
      endif
      call g:_fnr_on_change(a:str, '', '')
    endwhile
  endif
  return [g:pseudocl#CONTINUE, a:str, a:cursor]
endfunction

function! g:_fnr_on_change(new, old, _cursor)
  if a:new != a:old
    let [ic, wb, we] = s:parse_mode(s:mode)
    if s:phase =~ 'f'
      let s:from = a:new
      call s:matchdelete()
      if !empty(a:new)
        call add(s:mids, matchadd(s:hl1, s:prefix.ic.wb.s:escape(a:new).we))
      endif
    elseif s:phase =~ 't'
      " Preview
      if s:taint
        silent! undo
      endif

      let s:to = a:new
      let range =
        \ s:type == "\<C-V>" ? "'<,'>"
        \ : (line('w0') > line("'<") ? line('w0') : "'<")
        \ . ','
        \ . (line('w$') < line("'>") ? line('w$') : "'>")
      let s:command = "s#".s:prefix.ic.wb.escape(s:escape(s:from), '#').we.'#'.s:escape_nl_cr(escape(s:to, '#&~\')).'#'
      silent! execute range.s:command.substitute(s:mode, '[^g]', '', 'g')
      let s:taint = 1

      " Update highlights
      call s:matchdelete()
      if !empty(s:to)
        let line = 0
        let nocc = 0
        let diff = len(s:to) - len(s:from)

        for [l, c] in s:matches
          if l == line
            let nocc += 1
          else
            let line = l
            let nocc = 0
          endif

          let col = c + nocc * diff
          call add(s:mids, matchadd(s:hl2, '\%'.l.'l\%'.col.'c\V'.ic.wb.escape(s:to, '\').we))
        endfor
      endif
      call winrestview(s:view)
    endif
    redraw
  endif
endfunction

function! g:_fnr_render(_prompt, line, cursor)
  call pseudocl#render#clear()
  echohl None
  echon ':FNR '
  if s:phase =~ 'm' | echohl Label | endif
  echon s:mode_string()
  echohl None
  echon ' { '
  if s:phase == 'f' | echohl Label | endif
  echon 'find'
  echohl None
  echon ': '
  if s:phase == 'f'
    call pseudocl#render#echo_line(a:line, a:cursor, 35)
  else
    echon s:from
    echon ' '
  endif
  echohl None
  echon ', '
  if s:phase == 't' | echohl Label | endif
  echon 'replace'
  echohl None
  echon ': '
  if s:phase == 't'
    " TODO: trimming of overly lengthy s:from
    call pseudocl#render#echo_line(a:line, a:cursor, 35 + len(s:from))
  else
    echon s:to
    echon ' '
  endif
  echohl None
  echon '}'
endfunction

function! s:message(msg)
  echohl WarningMsg
  echon "\r"
  echon "\r".a:msg
  echohl None
endfunction

function! s:matchdelete()
  if !empty(s:mids)
    for mid in s:mids
      if mid > 0
        silent! call matchdelete(mid)
      endif
    endfor
    call remove(s:mids, 0, -1)
  endif
endfunction

function! s:sort(i1, i2)
  let [l1, l2] = [a:i1[0], a:i2[0]]
  let [c1, c2] = [a:i1[1], a:i2[1]]

  if l1 > l2
    return 1
  elseif l1 < l2
    return -1
  elseif c1 > c2
    return 1
  elseif c1 < c2
    return -1
  endif
  return 0
endfunction

function! s:parse_mode(mode)
  let ic       = (a:mode =~# 'i' ? '\c' : '\C')
  let [wb, we] = (a:mode =~# 'w' ? ['\<', '\>'] : ['', ''])
  return [ic, wb, we]
endfunction

function! s:escape(pattern)
  return s:escape_nl(escape(a:pattern, '\'))
endfunction

function! s:escape_nl(pattern)
  return substitute(a:pattern, "\n", '\\n', 'g')
endfunction

function! s:escape_nl_cr(pattern)
  return substitute(a:pattern, "\n", '\\r', 'g')
endfunction

function! s:find_matches(pattern)
  let found = []
  let matches = []
  let first_occurence = {}
  while 1
    if empty(first_occurence)
      normal! 0
      let flag = 'wc'
    else
      let flag = 'w'
    endif

    let [l, c] = searchpos(a:pattern, flag)
    if l == 0 && c == 0 || index(found, [l, c]) >= 0
      break
    elseif empty(first_occurence)
      let first_occurence = winsaveview()
    endif
    call add(found, [l, c])
    if l <= line('w$') && l >= line('w0')
      call add(matches, [l, c])
    endif
  endwhile
  call sort(matches, 's:sort')

  if !empty(first_occurence)
    call winrestview(first_occurence)
  endif
  return [found, matches]
endfunction

function! s:save_undo()
  let &undolevels = &undolevels
  if exists(':wundo')
    let s:undofile = tempname()
    silent execute 'wundo! '.s:undofile
  endif
endfunction

function! s:restore_undo()
  if exists(':wundo') && filereadable(s:undofile)
    silent execute 'rundo '.s:undofile
    call delete(s:undofile)
  endif
endfunction

function! s:save_visual()
  let s:visual = [visualmode(), getpos("'<")[1:-1], getpos("'>")[1:-1]]
endfunction

function! s:restore_visual()
  let [mode, p1, p2] = s:visual
  let [l0, c0]       = [line('.'), col('.')]
  let [l1, c1, o1]   = p1
  let [l2, c2, o2]   = p2
  if l1 == 0 || l2 == 0
    return
  endif
  let ve_save = &virtualedit
  try
    if mode == "\<C-V>"
      set virtualedit=all
    endif
    execute printf("normal! %dG%d|%s%dG%d|\<C-C>%dG%d|", l1, c1 + o1, mode, l2, c2 + o2, l0, c0)
  finally
    let &virtualedit = ve_save
  endtry
endfunction

function! fnr#fnr(type, ...) range
  let s:type    = a:type
  let s:mids    = []
  let s:prefix  = '\%V\V'
  let s:hl1     = get(g:, 'fnr_hl_from', 'Todo')
  let s:hl2     = get(g:, 'fnr_hl_to', 'IncSearch')
  let s:from    = get(g:, '_fnr_cword', '')
  let s:to      = '?'
  let s:mode    = get(g:, 'fnr_flags', 'gc')
  let s:phase   = 'f'
  let s:matches = []
  let s:taint   = 0

  call s:save_visual()
  let save_yank = @"
  let view      = winsaveview()
  if a:0 > 0
    if a:0 == 1
      normal! gvy
      if a:1 == 2
        let s:from = @"
        normal! ggVGy
      endif
    else
      silent execute printf("normal! %dGV%dGy", a:1, a:2)
    endif
  else
    if s:type == 'line'
      silent execute "normal! '[V']y"
    elseif s:type == 'block'
      silent execute "normal! `[\<C-V>`]y"
    else
      silent execute "normal! `[v`]y"
    endif
  endif
  let content = @"
  let s:words = pseudocl#complete#extract_words(content)
  let @" = save_yank
  call winrestview(view)

  if s:need_repeat
    silent! execute "'<,'>". s:previous
    return
  endif

  let [ic, wb, we] = s:parse_mode(s:mode)

  let cl_save = &cursorline
  call s:hide_cursor()

  let opts = {
  \ 'renderer':       function('g:_fnr_render'),
  \ 'words':          s:words,
  \ 'map':            0,
  \ 'remap':          { "\<Tab>": "\<C-N>", "\<S-Tab>": "\<C-P>" },
  \ 'on_change':      function('g:_fnr_on_change'),
  \ 'on_unknown_key': function('g:_fnr_on_unknown_key') }

  try
    " Find
    call g:_fnr_on_change(s:from, '', '')
    let s:from = pseudocl#start(extend(opts, { 'input': s:from, 'highlight': s:hl1 }))
    if empty(s:from)
      return s:message("Empty query")
    endif

    " Found
    let [ic, wb, we]     = s:parse_mode(s:mode)
    let [found, s:matches] = s:find_matches(s:prefix.ic.wb.s:escape(s:from).we)
    if empty(found)
      return s:message("No matches")
    endif

    " Replace
    let s:phase = 't'
    let s:to = s:from
    let s:view = winsaveview()
    set cursorline
    call s:save_undo()
    call g:_fnr_on_change(s:to, '', '')
    let s:to = pseudocl#start(extend(opts, { 'input': s:to, 'highlight': s:hl2 }))

    silent! undo
    call s:restore_undo()
    execute "'<,'>".s:command.substitute(s:mode, '[^gc]', '', 'g')
    " vim-repeat does not seem to support substitution confirmation
    let s:previous = s:command.substitute(s:mode, '[^g]', '', 'g')
    let s:repeat_entire = get(g:, '_fnr_entire', 0)
    silent! call repeat#set("\<Plug>(FNRRepeat)")
  catch /Pattern not found/
    return s:message("No matches")
  catch 'exit'
    if s:taint
      silent! undo
      call s:restore_undo()
    endif
    call s:message("Cancelled")
  finally
    call s:matchdelete()
    call s:display_cursor()
    call s:restore_visual()
    unlet! g:_fnr_cword g:_fnr_entire s:in_getmode
    let &cursorline = cl_save
  endtry
endfunction

function! fnr#fnr_repeat()
  if s:repeat_entire
    silent! execute '%'.s:previous
  else
    try
      let s:need_repeat = 1
      normal! .
    finally
      let s:need_repeat = 0
    endtry
  endif
  silent! call repeat#set("\<Plug>(FNRRepeat)")
endfunction

let &cpo = s:cpo_save
unlet s:cpo_save

