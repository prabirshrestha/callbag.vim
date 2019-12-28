# rx.vim

Lightweight observables and iterables for VimScript based on [Callbag](https://github.com/callbag/callbag)

Currently only callbags are implemented. There are plans to implement Rx based of callbags in future.

## Example

```viml
let s:i = 0
function! s:next(cb) abort
    echom s:i
    let s:i = s:i + 1
endfunction

function! rx#callbag#demo() abort
    let l:res = rx#callbag#pipe(
        \ rx#callbag#interval(1000),
        \ rx#callbag#take(3),
        \ rx#callbag#forEach(function('s:next')),
        \ )
    return l:res
endfunction
```
