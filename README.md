# callbag.vim

Lightweight observables and iterables for VimScript based on [Callbag Spec](https://github.com/callbag/callbag).

## Source Factories

| Implemented   | Name                                                   |
|---------------|--------------------------------------------------------|
| Yes           | create                                                 |
| Yes           | empty                                                  |
| Yes           | fromArray                                              |
| Yes           | fromEvent                                              |
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
