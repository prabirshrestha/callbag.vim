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

" forEach() {{{
function! callbag#forEach(operation) abort
    let l:data = { 'operation': a:operation }
    return function('s:forEachOperation', [l:data])
endfunction

function! s:forEachOperation(data, source) abort
    return a:source(0, function('s:forEachOperationSource', [a:data]))
endfunction

function! s:forEachOperationSource(data, t, ...) abort
    if a:t == 0 | let a:data['talback'] = a:1 | endif
    if a:t == 1 | call a:data['operation'](a:1) | endif
    if (a:t == 1 || a:t == 0) | call a:data['talkback'](1) | endif
endfunction
" }}}

" vim:ts=4:sw=4:ai:foldmethod=marker:foldlevel=0:
