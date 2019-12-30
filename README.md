# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag).

## Source Factories

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | create                                                 |
| Yes           | empty                                                  |
| Yes           | fromEvent                                              |
| Yes           | interval                                               |
| Yes           | never                                                  |
| Yes           | throwError                                             |

## Sink Factories

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | forEach                                                |
| Yes           | subscribe                                              |

## Operators

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | debounceTime                                           |
| Yes           | filter                                                 |
| Yes           | map                                                    |
| Yes           | take                                                   |

## Utils

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | pipe                                                   |

`pipe()`'s first argument should be a source factory.

***Note** In order to support older version of vim without lambdas, callbag.vim explicitly doesn't use lambdas in the source code.*

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
    call callbag#pipe(
        \ callbag#empty(),
        \ callbag#subscribe({
        \   'next': {x->s:log('next will never be called')},
        \   'error': {e->s:log('error will never be called')},
        \   'complete': {->s:log('complete will be called')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#never(),
        \ callbag#subscribe({x->s:log('next will not be called')}, {e->s:log('error will not be called')}, {->s:log('complete will not be called')}),
     call callbag#pipe(
        \ callbag#create({next,error,done->next('next')}),
        \ callbag#subscribe({
        \   'next': {x->s:log('next')},
        \   'error': {e->s:log('error')},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#create({next,error,done->next('val')}),
        \ callbag#forEach({x->s:log('next value is ' . x)}),
        \ )
    call callbag#pipe(
        \ callbag#throwError('my dummy error'),
        \ callbag#subscribe({
        \   'next': {x->s:log('next will never be called')},
        \   'error': {e->s:log('error called with ' . e)},
        \   'complete': {->s:log('complete will never be called')},
        \ }),
        \ )
endfunction
```

## License

MIT

## Author

Prabir Shrestha
