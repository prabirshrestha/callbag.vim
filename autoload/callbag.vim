" pipe() {{{
function! callbag#pipe(...) abort
    let l:Res = a:1
    let l:i = 1
    while l:i < a:0
        let l:Res = a:000[l:i](l:Res)
        let l:i = l:i + 1
    endwhile
    return l:Res
endfunction
" }}}

" vim:ts=4:sw=4:ai:foldmethod=marker:foldlevel=0:
