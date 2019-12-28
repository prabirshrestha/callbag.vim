# rx.vim

Lightweight observables and iterables for VimScript based on [Callbag](https://github.com/callbag/callbag)

Currently only callbags are implemented. There are plans to implement Rx based of callbags in future.

## Example

```viml
function! s:log(x) abort
    echom a:x
endfunction

function! rx#callbag#demo() abort
    call rx#callbag#pipe(
        \ rx#callbag#interval(1000),
        \ rx#callbag#take(3),
        \ rx#callbag#map({x-> x + 1}),
        \ rx#callbag#map({x-> x * 1000}),
        \ rx#callbag#forEach({x -> s:log(x) }),
        \ )
endfunction
```
