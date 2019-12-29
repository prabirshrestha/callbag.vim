# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag).

## Source Factories

| Implemented   | Operators                                              |
|---------------|--------------------------------------------------------|
| Yes           | create                                                 |

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

## Utils

| Implemented   | Operators                                              |
|---------------|--------------------------------------------------------|
| Yes           | pipe                                                   |

**Note**

*In order to support older version of vim without lambdas, callbag.vim explicitly doesn't use lambdas in the source code.*

## Difference with callbag spec

While the original callbag spec requires payload to be optional - `(type: number, payload?: any) => void`,
callbag.vim requires payload to be required. This is primarily due to limition on how vimscript functions works.
Having optional parameter and using `...` and `a:0` to read the extra args and then use `a:1` makes the code complicated.
You can use `callbag#undefined()` method to pass undefined.

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

## License

MIT

## Author

Prabir Shrestha
