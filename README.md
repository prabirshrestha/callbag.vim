# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag).

## Source Factories

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | create                                                 |
| Yes           | empty                                                  |
| Yes           | fromArray                                              |
| Yes           | fromEvent                                              |
| Yes           | fromPromise                                            |
| Yes           | interval                                               |
| Yes           | lazy                                                   |
| Yes           | never                                                  |
| Yes           | of                                                     |
| Yes           | throwError                                             |

## Sink Factories

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | forEach                                                |
| Yes           | subscribe                                              |
| Yes           | toList                                                 |

## Multicasting

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | makeSubject                                            |
| Yes           | share                                                  |

## Operators

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | combine                                                |
| Yes           | concat                                                 |
| Yes           | debounceTime                                           |
| Yes           | delay                                                  |
| Yes           | distinctUntilChanged                                   |
| Yes           | filter                                                 |
| Yes           | flatten                                                |
| Yes           | group                                                  |
| Yes           | map                                                    |
| Yes           | merge                                                  |
| Yes           | scan                                                   |
| Yes           | switchMap                                              |
| Yes           | take                                                   |
| Yes           | takeUntil                                              |
| Yes           | takeWhile                                              |
| Yes           | tap                                                    |
| No            | concatWith                                             |
| No            | mergeWith                                              |
| No            | rescue                                                 |
| No            | retry                                                  |
| No            | skip                                                   |
| No            | throttle                                               |
| No            | timeout                                                |

## Utils

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | operate                                                |
| Yes           | pipe                                                   |

`pipe()`'s first argument should be a source factory.
`operate()` doesn't requires first function to be the source.

**Note** In order to support older version of vim without lambdas, callbag.vim explicitly doesn't use lambdas in the source code.

## Difference with callbag spec

While the original callbag spec requires payload to be optional - `(type: number, payload?: any) => void`,
callbag.vim requires payload to be required. This is primarily due to limition on how vimscript functions works.
Having optional parameter and using `...` and `a:0` to read the extra args and then use `a:1` makes the code complicated.
You can use `callbag#undefined()` method to pass undefined.

## Example

```viml
    function s:log(message) abort
        echom a:message
    endfunction

    call callbag#pipe(
        \ callbag#fromEvent(['TextChangedI', 'TextChangedP']),
        \ callbag#debounceTime(250),
        \ callbag#subscribe({
        \   'next':{x->s:log('text changed')},
        \   'error':{e->s:log('error')},
        \   'complete':{->s:log('complete')}
        \ }),
        \ )
```

Refer to [examples.vim](examples.vim) for more.

## Synchronously waiting for completion or error

`callbag#toList()` operator with `wait()` will allow to synchronously wait for 
completion or error. Default value for `sleep` is `1` miliseconds and `timeout` 
is `-1` which means it will never timeout.

```vim
try
    let l:result = callbag#pipe(
        \ callbag#interval(250),
        \ callbag#take(3),
        \ callbag#toList(),
        \ ).wait({ 'sleep': 1, 'timeout': 5000 })
    echom l:result
catch
    " error may be thrown due to timeout or if it emits error
    echom v:exception . ' ' . v:throwpoint
endtry
```

Similar to `callbag#subscribe` you can manually unsubscribe instead of waiting
for timeout. By default `wait()` will auto unsubscribe when it completes or errors.

```vim
let l:result = callbag#pipe(
    \ callbag#interval(250),
    \ callbag#take(10),
    \ callbag#toList(),
    \ )

call timer_start(250, {x->l:result.unsubscribe()})
let l:items = l:result.wait({ 'sleep': 1, 'timeout': 5000 })
```

`wait()` is already implemented in an efficient way i.e. if it has already completed
or errored it will synchronously return values without any `sleep` or `timers`.

## Embedding

Please do not take direct dependency on this plugin and instead embed it using the following command.

```vim
:CallbagEmbed path=./autoload/myplugin/callbag.vim namespace=myplugin#callbag
```

This can then be referenced using `myplugin#callbag#pipe()`

## License

MIT

## Author

Prabir Shrestha
