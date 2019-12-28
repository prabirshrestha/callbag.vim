# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag)

## Example

```viml
function! s:log(x) abort
    echom a:x
endfunction

function! callbag#demo() abort
    call callbag#pipe(
        \ callbag#interval(1000),
        \ callbag#take(10),
        \ callbag#map({x-> x + 1}),
        \ callbag#filter({x-> x % 2 == 0}),
        \ callbag#map({x-> x * 1000}),
        \ callbag#forEach({x -> s:log(x) }),
        \ )
    call callbag#pipe(
        \ callbag#fromEvent('InsertEnter'),
        \ callbag#forEach({x -> s:log('InsertEnter') }),
        \ )
    call callbag#pipe(
        \ callbag#fromEvent('InsertLeave'),
        \ callbag#forEach({x -> s:log('InsertLeave') }),
        \ )
endfunction
```
