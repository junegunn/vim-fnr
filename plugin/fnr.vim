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

nnoremap <silent> <Plug>(FNR)       :let [g:_fnr_cword, g:_fnr_entire] = [expand('<cword>'), 0]<CR>:set opfunc=fnr#fnr<CR>g@
vnoremap <silent> <Plug>(FNR)       :call fnr#fnr(visualmode(), 1)<CR>
nnoremap <silent> <Plug>(FNR%)      :let [g:_fnr_cword, g:_fnr_entire] = [expand('<cword>'), 1]<CR>:%FNR<CR>
vnoremap <silent> <Plug>(FNR%)      :call fnr#fnr(visualmode(), 2)<CR>
nnoremap <silent> <Plug>(FNRRepeat) :call fnr#fnr_repeat()<CR>

command! -range FNR call fnr#fnr('line', <line1>, <line2>)

for m in ['n', 'v']
  for [k, p] in items({'r': '<Plug>(FNR)', 'R': '<Plug>(FNR%)'})
    if !hasmapto(p, m) && empty(mapcheck(mapleader.k, m))
      execute m.printf('map <Leader>%s %s', k, p)
    endif
  endfor
endfor

