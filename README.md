# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag)

## Example

```viml
let s:i = 0
function! s:log(x) abort
    let s:i += 1
    echom 'log ' . s:i . '   ' . a:x
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
        \ callbag#fromEvent(['TextChangedI', 'TextChangedP']),
        \ callbag#debounceTime(250),
        \ callbag#forEach({x -> s:log('text changed') }),
        \ )
    call callbag#pipe(
        \ callbag#fromEvent('InsertLeave'),
        \ callbag#forEach({x -> s:log('InsertLeave') }),
        \ )
endfunction
```

## Operators

| Implemented   | Operators                                              |
|---------------|--------------------------------------------------------|
| Yes           | debounceTime                                           |
| Yes           | filter                                                 |
| Yes           | forEach                                                |
| Yes           | fromEvent                                              |
| Yes           | interval                                               |
| Yes           | map                                                    |
| Yes           | pipe                                                   |
| Yes           | take                                                   |

## License

MIT

## Author

Prabir Shrestha
