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

function! s:mode_string(mode)
  let str = ''
  for m in ['i', 'w', 'g', 'c']
    let str .= a:mode =~ m ? m : '_'
  endfor
  return '('.str.')'
endfunction

function! s:echon(from, to, mode, phase)
  let from = substitute(a:from, "\n", ' ', 'g') " FIXME
  let to   = substitute(a:to,   "\n", ' ', 'g') " FIXME
  if get(s:, 'in_getmode', 0)
    echon "\r:FNR "
    echohl Label
    echon s:mode_string(a:mode)
    echohl None
    echon printf(" { find: %s , replace: %s }", from, to)
  elseif a:phase == 0
    echon printf("\r:FNR %s { ", s:mode_string(a:mode))
    echohl Label
    echon 'find'
    echohl None
    echon ': '
    let pad = s:echo_cursor(s:hl1, from)
    if !pad | echon ' ' | endif
    echon ', replace: ? }'
  elseif a:phase == 1
    echon printf("\r:FNR %s { ", s:mode_string(a:mode))
    echon 'find: '
    execute 'echohl ' . s:hl1
    echon from
    echohl None
    echon ' , '
    echohl Label
    echon 'replace'
    echohl None
    echon ': '
    let pad = s:echo_cursor(s:hl2, to)
    if !pad | echon ' ' | endif
    echon '}'
  endif
endfunction

function! s:toggle_mode(m, o)
  if a:m =~ a:o | return substitute(a:m, a:o, '', 'g')
  else          | return a:m . a:o
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

function! s:getchar(q, mode, phase, from, to)
  let q  = a:q
  let m  = a:mode

  if get(s:, 'in_getmode', 0)
    let ch = nr2char(getchar())
    if ch == 'g'
      let m = s:toggle_mode(m, 'g')
    elseif ch == 'c'
      let m = s:toggle_mode(m, 'c')
    elseif ch == 'i'
      let m = s:toggle_mode(m, 'i')
    elseif ch == 'w'
      let m = s:toggle_mode(m, 'w')
    elseif ch == "\<C-C>"
      return [-1, q, m]
    elseif ch == "\<Tab>" || ch == "\<Enter>"
      unlet s:in_getmode
    endif
    return [0, q, m]
  endif

  let c  = getchar()
  let ch = nr2char(c)
  let complete = []

  try
    if ch == "\<C-C>"
      return [-1, q, m]
    elseif ch == "\<Tab>"
      let s:in_getmode = 1
      call s:echon(a:from, a:to, m, a:phase)
      redraw
      return s:getchar(q, m, a:phase, a:from, a:to)
    elseif ch == "\<C-a>"
      let s:cursor = 0
    elseif ch == "\<C-e>"
      let s:cursor = len(q)
    elseif ch == "\<Return>"
      return [1, q, m]
    elseif ch == "\<C-U>"
      let q = strpart(q, s:cursor)
      let s:cursor = 0
    elseif ch == "\<C-W>"
      let prefix = substitute(substitute(strpart(q, 0, s:cursor), '\s*$', '', ''), '\s*\S*$', '', '')
      let q = prefix . strpart(q, s:cursor)
      let s:cursor = len(prefix)
    elseif ch == "\<C-K>"
      let q = strpart(q, 0, s:cursor)
    elseif ch == "\<C-H>" || c  == "\<bs>"
      let q = strpart(q, 0, s:cursor - 1) . strpart(q, s:cursor)
      let s:cursor = max([0, s:cursor - 1])
    elseif ch == "\<C-B>" || c == "\<Left>"
      let s:cursor = max([0, s:cursor - 1])
    elseif ch == "\<C-F>" || c == "\<Right>"
      let s:cursor = min([len(q), s:cursor + 1])
    elseif ch == "\<C-N>" || ch == "\<C-P>"
      let before  = strpart(q, 0, s:cursor)
      let matches = get(s:, 'complete', s:find_candidates(before, s:words))

      if !empty(matches)
        if ch == "\<C-N>"
          let matches = extend(copy(matches[1:-1]), matches[0:0])
        else
          let matches = extend(copy(matches[-1:-1]), matches[0:-2])
        endif
        let item     = matches[0]
        let q        = item . strpart(q, s:cursor)
        let s:cursor = len(item)
        let complete = matches
      endif
    elseif ch == "\<C-R>"
      let reg = nr2char(getchar())

      let text = ''
      if reg == "\<C-W>"
        let text = expand('<cword>')
      elseif reg == "\<C-A>"
        let text = expand('<cWORD>')
      elseif reg == "="
        let text = eval(s:input('=', ''))
      elseif reg =~ '[a-zA-Z0-9"]'
        let text = getreg(reg)
      end
      if !empty(text)
        let q = strpart(q, 0, s:cursor) . text . strpart(q, s:cursor)
        let s:cursor += len(text)
      endif
    elseif ch =~ '[[:print:]]'
      let q = strpart(q, 0, s:cursor) . ch . strpart(q, s:cursor)
      let s:cursor += 1
    endif
    return [0, q, m]
  finally
    if empty(complete)
      unlet! s:complete
    else
      let s:complete = complete
    endif
  endtry
endfunction

function! s:message(msg)
  echohl WarningMsg
  echon "\r"
  echon "\r".a:msg
  echohl None
endfunction

function! s:matchdelete(mids)
  if !empty(a:mids)
    for mid in a:mids
      if mid > 0
        silent! call matchdelete(mid)
      endif
    endfor
    call remove(a:mids, 0, -1)
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

function! s:extract_words(content)
  let dict = {}
  for word in split(a:content, '\W\+')
    let dict[word] = 1
  endfor
  return sort(keys(dict))
endfunction

function! s:find_candidates(prefix, words)
  let started = 0
  let matches = [a:prefix]
  let tokens = matchlist(a:prefix, '^\(.\{-}\)\(\w*\)$')
  let [prefix, suffix] = tokens[1 : 2]
  for word in a:words
    if stridx(word, suffix) == 0 && len(word) > len(suffix)
      call add(matches, prefix . word)
      let started = 1
    elseif started
      break
    end
  endfor
  return matches
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
    normal! 0
    let [l, c] = searchpos(a:pattern, 'wc')
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

function! fnr#fnr(type, ...) range
  let mids        = []
  let prefix      = '\%V\V'
  let s:hl1       = get(g:, 'fnr_hl_from', 'Todo')
  let s:hl2       = get(g:, 'fnr_hl_to', 'IncSearch')
  let from        = get(g:, '_fnr_cword', '')
  let save_yank   = @"
  let view        = winsaveview()

  if a:0 > 0
    if a:0 == 1
      normal! gvy
      if a:1 == 2
        let from = @"
        normal! ggVGy
      endif
    else
      silent execute printf("normal! %dGV%dGy", a:1, a:2)
    endif
  else
    if a:type == 'line'
      silent execute "normal! '[V']y"
    elseif a:type == 'block'
      silent execute "normal! `[\<C-V>`]y"
    else
      silent execute "normal! `[v`]y"
    endif
  endif
  let content = @"
  let @" = save_yank
  call winrestview(view)

  if s:need_repeat
    silent! execute "'<,'>". s:previous
    return
  endif

  let s:words = s:extract_words(content)

  let mode = get(g:, 'fnr_flags', 'gc')
  let [ic, wb, we] = s:parse_mode(mode)

  let cl_save = &cursorline
  call s:hide_cursor()
  try
    " Find
    let s:cursor = len(from)
    while 1
      call s:matchdelete(mids)
      if !empty(from)
        call add(mids, matchadd(s:hl1, prefix.ic.wb.s:escape(from).we))
      endif
      call s:echon(from, '?', mode, 0)
      redraw

      let [r, from, mode] = s:getchar(from, mode, 0, from, '?')
      let [ic, wb, we]    = s:parse_mode(mode)
      if r == 1
        if empty(from)
          call s:message("Empty query")
          return
        endif
        break
      elseif r == -1
        call s:message("Cancelled")
        return
      endif
    endwhile

    " Found
    let [found, matches] = s:find_matches(prefix.ic.wb.s:escape(from).we)
    if empty(found)
      call s:message("No matches")
      return
    endif

    " Replace
    let to = from
    let s:cursor = len(to)
    set cursorline
    redraw
    let view = winsaveview()
    while 1
      call s:echon(from, to, mode, 1) " Should not redraw yet

      " Preview
      let &undolevels = &undolevels
      let range =
        \ a:type == "\<C-V>" ? "'<,'>"
        \ : (line('w0') > line("'<") ? line('w0') : "'<")
        \ . ','
        \ . (line('w$') < line("'>") ? line('w$') : "'>")
      let command = "s#".prefix.ic.wb.s:escape(escape(from, '#')).we.'#'.s:escape_nl_cr(escape(to, '#&~\')).'#'
      silent execute range.command.substitute(mode, '[^g]', '', 'g')

      " Update highlights
      call s:matchdelete(mids)
      if !empty(to)
        let line = 0
        let nocc = 0
        let diff = len(to) - len(from)

        for [l, c] in matches
          if l == line
            let nocc += 1
          else
            let line = l
            let nocc = 0
          endif

          let col = c + nocc * diff
          call add(mids, matchadd(s:hl2, '\%'.l.'l\%'.col.'c\V'.ic.wb.escape(to, '\').we))
        endfor
      endif
      call winrestview(view)
      redraw

      let pmode         = mode
      let [r, to, mode] = s:getchar(to, mode, 1, from, to)

      silent! undo
      if pmode !=# mode
        let [ic, wb, we]     = s:parse_mode(mode)
        let [found, matches] = s:find_matches(prefix.ic.wb.from.we)
      endif

      if r == 1
        execute "'<,'>".command.substitute(mode, '[^gc]', '', 'g')
        " vim-repeat does not seem to support substitution confirmation
        let s:previous = command.substitute(mode, '[^g]', '', 'g')
        let s:repeat_entire = get(g:, '_fnr_entire', 0)
        silent! call repeat#set("\<Plug>(FNRRepeat)")
        break
      elseif r == -1
        call s:message("Cancelled")
        return
      endif
    endwhile
  finally
    call s:matchdelete(mids)
    call s:display_cursor()
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

