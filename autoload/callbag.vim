function! s:noop(...) abort
endfunction

let s:undefined_token = '__callbag_undefined__'
let s:str_type = type('')
let s:func_type = type(function('s:noop'))

" ***** UTILS ***** {{{

" undefined() {{{
function! callbag#undefined() abort
    return s:undefined_token
endfunction
" }}}

" isUndefined() {{{
function! callbag#isUndefined(d) abort
    return type(a:d) == s:str_type && a:d ==# s:undefined_token
endfunction
" }}}

" pipe() {{{
function! callbag#pipe(...) abort
    if a:0 == 0
        return function('s:pipeIdentity')
    elseif a:0 == 1
        return a:1
    else
        let l:Res = a:1
        let l:i = 1
        while l:i < a:0
            let l:Res = a:000[l:i](l:Res)
            let l:i = l:i + 1
        endwhile
        return l:Res
    endif
endfunction

function! s:pipeIdentity(x) abort
    return a:x
endfunction
" }}}

" subscribe() {{{
function! callbag#subscribe(...) abort
    " listener
    let l:ctxListener = {}
    let l:observer = {}
    if a:0 > 0 && type(a:1) == type({}) " a:1 { next, error, complete }
        if has_key(a:1, 'next') | let l:observer['next'] = a:1['next'] | endif
        if has_key(a:1, 'error') | let l:observer['error'] = a:1['error'] | endif
        if has_key(a:1, 'complete') | let l:observer['complete'] = a:1['complete'] | endif
    else " a:1 = next, a:2 = error, a:3 = complete
        if a:0 >= 1 | let l:observer['next'] = a:1 | endif
        if a:0 >= 2 | let l:observer['error'] = a:2 | endif
        if a:0 >= 3 | let l:observer['complete'] = a:3 | endif
    endif
    let l:ctxListener['o'] = l:observer
    return function('s:subscribeSourceFn', [l:ctxListener])
endfunction

function! s:subscribeSourceFn(ctxListener, source) abort
    let l:ctxSource = { 'source': a:source, 'ctxListener': a:ctxListener }
    call a:source(0, function('s:subscribeSinkFn', [l:ctxSource]))
    return function('s:subscribeDispose', [l:ctxSource])
endfunction

function! s:subscribeSinkFn(ctxSource, t, d) abort
    if a:t == 0
        let a:ctxSource['sourceTalkback'] = a:d
    elseif a:t == 1
        if has_key(a:ctxSource['ctxListener']['o'], 'next') | call a:ctxSource['ctxListener']['o']['next'](a:d) | endif
    elseif a:t == 2
        if callbag#isUndefined(a:d)
            if has_key(a:ctxSource['ctxListener']['o'], 'complete') | call a:ctxSource['ctxListener']['o']['complete']() | endif
        else
            if has_key(a:ctxSrouce['ctxListener']['o'], 'error') | call a:ctxSource['ctsListener']['o']['error'](a:d) | endif
        endif
    endif
endfunction

function! s:subscribeDispose(ctxSource) abort
    if has_key(a:ctxSource, 'sourceTalkback') | call a:ctxSource['sourceTalkback'](2, callbag#undefined()) | endif
endfunction
" }}}

" }}}

" ***** SOURCES ***** {{{

" createSource() {{{
function! callbag#createSource(fn) abort
    let l:ctx = { 'fn': a:fn }
    return function('s:createSourceFn', [l:ctx])
endfunction

function! s:createSourceFn(ctx, start, sink) abort
    let l:ctxCreateSource = { 'ctx': a:ctx, 'sink': a:sink }
    if a:start == 0
        let l:ctxCreateSource['finished'] = 0
        let l:observer = {
            \ 'next': function('s:createSourceFnNextFn', [l:ctxCreateSource]),
            \ 'error': function('s:createSourceFnErrorFn', [l:ctxCreateSource]),
            \ 'complete': function('s:createSourceFnCompleteFn', [l:ctxCreateSource]),
            \ }
        let l:ctxCreateSource['unsubscribe'] = a:ctx['fn'](l:observer)
        let l:ctxCreateSource['talkback'] = function('s:createSourceFnTalkbackFn', [l:ctxCreateSource])
        call a:sink(0, l:ctxCreateSource['talkback'])
    endif
endfunction

function! s:createSourceFnNextFn(ctxCreateSource, value) abort
    if a:ctxCreateSource['finished'] | return | endif
    call a:ctxCreateSource['sink'](1, a:value)
endfunction

function! s:createSourceFnErrorFn(ctxCreateSource, err) abort
    if a:ctxCreateSource['finished'] | return | endif
    let a:ctxCreateSource['finished'] = 1
    call a:ctxCreateSource['sink'](2, a:err)
endfunction

function! s:createSourceFnCompleteFn(ctxCreateSource) abort
    if a:ctxCreateSource['finished'] | return | endif
    let a:ctxCreateSource['finished'] = 1
    call a:ctxCreateSource['sink'](2, callbag#undefined())
endfunction

function! s:createSourceFnTalkbackFn(ctxCreateSource, t, d) abort
    if a:t == 2 && has_key(a:ctxCreateSource, 'unsubscribe') && type(a:ctxCreateSource['unsubscribe']) == s:func_type
        call a:ctxCreateSource['unsubscribe']()
    endif
endfunction
" }}}

" empty() {{{
function! callbag#empty() abort
    return callbag#createSource(function('s:emptyCreateSourceFn'))
endfunction

function! s:emptyCreateSourceFn(o) abort
    call a:o['complete']()
endfunction
" }}}

" of() {{{
function! callbag#of(...) abort
    return callbag#fromList(a:000)
endfunction
" }}}

" fromList() {{{
function! callbag#fromList(values) abort
    let l:ctx = { 'values': a:values }
    return callbag#createSource(function('s:fromListCreateSourceFn', [l:ctx]))
endfunction

function! s:fromListCreateSourceFn(ctx, o) abort
    let l:ctxCreateSource = { 'finished': 0 }

    for l:value in a:ctx['values']
        if l:ctxCreateSource['finished'] | break | endif
        call a:o['next'](l:value)
    endfor

    if !l:ctxCreateSource['finished']
        call a:o['complete']()
    endif

    return function('s:fromListDisposeFn', [l:ctxCreateSource])
endfunction

function! s:fromListDisposeFn(ctxCreateSource) abort
    let a:ctxCreateSource['finished'] = 1
endfunction
" }}}

" lazy() {{{
function! callbag#lazy(f) abort
    let l:ctx = { 'f': a:f }
    return callbag#createSource(function('s:lazyCreateSourceFn', [l:ctx]))
endfunction

function! s:lazyCreateSourceFn(ctx, o) abort
    let l:ctxCreateSource = { 'finished': 0 }
    call a:o['next'](a:ctx['f']())
    if !l:ctxCreateSource['finished'] | call a:o['complete']() | endif
    return function('s:lazyDisposeFn', [l:ctxCreateSource])
endfunction

function! s:lazyDisposeFn(ctxCreateSource) abort
    let a:ctxCreateSource['finished'] = 1
endfunction
" }}}

" never() {{{
function! callbag#never() abort
    return callbag#createSource(function('s:neverCreateSourceFn'))
endfunction

function! s:neverCreateSourceFn(o) abort
    " source that never completes and emits no data
endfunction
" }}}

" interval() {{{
function! callbag#interval(period) abort
    return callbag#timer(a:period, a:period)
endfunction
" }}}

" timer() {{{
function! callbag#timer(initialDelay, ...) abort
    let l:ctx = { 'initialDelay': a:initialDelay }
    if a:0 == 1 | let l:ctx['period'] = a:1 | endif
    return callbag#createSource(function('s:timerCreateSourceFn', [l:ctx]))
endfunction

function! s:timerCreateSourceFn(ctx, o) abort
    let l:ctxCreateSource = { 'o': a:o, 'n': -1, 'ctx': a:ctx }

    let l:ctxCreateSource['initialDelayTimerId'] = timer_start(a:ctx['initialDelay'],
        \ function('s:timerInitialDelayTimerCb', [l:ctxCreateSource]))

    return function('s:timerDisposeFn', [l:ctxCreateSource])
endfunction

function! s:timerInitialDelayTimerCb(ctxCreateSource, ...) abort
    let a:ctxCreateSource['n'] += 1
    call a:ctxCreateSource['o']['next'](a:ctxCreateSource['n'])
    if has_key(a:ctxCreateSource['ctx'], 'period')
        let a:ctxCreateSource['periodTimerId'] = timer_start(a:ctxCreateSource['ctx']['period'],
            \ function('s:timerPeriodTimerCb', [a:ctxCreateSource]), { 'repeat': -1 })
    else
        call a:ctxCreateSource['o']['complete']()
    endif
endfunction

function! s:timerPeriodTimerCb(ctxCreateSource, ...) abort
    let a:ctxCreateSource['n'] += 1
    call a:ctxCreateSource['o']['next'](a:ctxCreateSource['n'])
endfunction

function! s:timerDisposeFn(ctxCreateSource) abort
    call timer_stop(a:ctxCreateSource['initialDelayTimerId'])
    if has_key(a:ctxCreateSource['ctx'], 'period') && has_key(a:ctxCreateSource, 'periodTimerId')
        call timer_stop(a:ctxCreateSource['periodTimerId'])
    endif
endfunction
" }}}

" }}}

" ***** OPERATORS ***** {{{

" filter() {{{
function! callbag#filter(predicate) abort
    let l:ctx = { 'predicate': a:predicate }
    return function('s:filterFn', [l:ctx])
endfunction

function! s:filterFn(ctx, source) abort
    let l:ctxSource = { 'source': a:source, 'ctx': a:ctx }
    return callbag#createSource(function('s:filterCreateSourceFn', [l:ctxSource]))
endfunction

function! s:filterCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = { 'o': a:o, 'ctxSource': a:ctxSource }
    let l:observer = {
        \ 'next': function('s:filterNextFn', [l:ctxCreateSource]),
        \ 'error': a:o.error,
        \ 'complete': a:o.complete,
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:filterNextFn(ctxCreateSource, value) abort
    if a:ctxCreateSource['ctxSource']['ctx']['predicate'](a:value)
        call a:ctxCreateSource['o']['next'](a:value)
    endif
endfunction
" }}}

" flatMap() {{{
function! callbag#flatMap(mapper) abort
    let l:ctx = { 'mapper': a:mapper }
    return function('s:flatMapFn', [l:ctx])
endfunction

function! s:flatMapFn(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
     return callbag#createSource(function('s:flatMapCreateSourceFn', [l:ctxSource]))
endfunction

function! s:flatMapCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = {
        \ 'ctxSource': a:ctxSource,
        \ 'o': a:o,
        \ 'finished': 0,
        \ 'subscriptionList': [],
        \ }
    let l:ctxCreateSource['cancelSubscriptions'] = function('s:flatMapCancelSubscriptionsFn', [l:ctxCreateSource])
    let l:ctxCreateSource['removeSubscription'] = function('s:flatMapRemoveSubscriptionFn', [l:ctxCreateSource])

    let l:observer = {
        \ 'next': function('s:flatMapNextFn', [l:ctxCreateSource]),
        \ 'error': function('s:flatMapErrorFn', [l:ctxCreateSource]),
        \ 'complete': function('s:flatMapCompleteFn', [l:ctxCreateSource]),
        \ }

    let l:ctxCreateSource['unsubscribe'] = callbag#subscribe(l:observer)(a:ctxSource['source'])

    return function('s:flatMapDispose', [l:ctxCreateSource])
endfunction

function! s:flatMapCancelSubscriptionsFn(ctxCreateSource) abort
    for l:subscription in a:ctxCreateSource['subscriptionList']
        if has_key(l:subscription, 'unsubscribe')
            call l:subscription['unsubscribe']()
        endif
    endfor
endfunction

function! s:flatMapRemoveSubscriptionFn(ctxCreateSource, subscription) abort
    let l:i = 0
    let l:len = len(a:ctxCreateSource['subscriptionList'])
    while l:i < l:len
        let l:subscription = a:ctxCreateSource['subscriptionList'][l:i]
        if l:subscription == a:subscription
            call remove(a:ctxCreateSource['subscriptionList'], l:i)
            break
        endif
        let l:i += 1
    endwhile
endfunction

function! s:flatMapErrorFn(ctxCreateSource, err) abort
    let a:ctxCreateSource['finished'] = 1
    call a:ctxCreateSource['cancelSubscriptions']()
    call a:ctxCreateSource['o']['error'](a:err)
endfunction

function! s:flatMapCompleteFn(ctxCreateSource) abort
    let a:ctxCreateSource['finished'] = 1
    if empty(a:ctxCreateSource['subscriptionList'])
        call a:ctxCreateSource['o']['complete']()
    endif
endfunction

function! s:flatMapDispose(ctxCreateSource) abort
    call a:ctxCreateSource['cancelSubscriptions']()
    call a:ctxCreateSource['unsubscribe']()
endfunction

function! s:flatMapNextFn(ctxCreateSource, value) abort
    if !a:ctxCreateSource['finished']
        let l:mappedCtx = {}
        let l:mappedCtx['subscription'] = {}
        call add(a:ctxCreateSource['subscriptionList'], l:mappedCtx['subscription'])
        let l:mappedObserver = {
            \ 'next': function('s:flatMapMappedNextFn', [a:ctxCreateSource, l:mappedCtx]),
            \ 'error': function('s:flatMapMappedErrorFn', [a:ctxCreateSource, l:mappedCtx]),
            \ 'complete': function('s:flatMapMappedCompleteFn', [a:ctxCreateSource, l:mappedCtx]),
            \ }

        let l:Source = a:ctxCreateSource['ctxSource']['ctx']['mapper'](a:value)
        let l:mappedCtx['subscription']['unsubscribe'] = callbag#subscribe(l:mappedObserver)(l:Source)
    endif
endfunction

function! s:flatMapMappedNextFn(ctxCreateSource, mappedCtx, value) abort
    call a:ctxCreateSource['o']['next'](a:value)
endfunction

function! s:flatMapMappedErrorFn(ctxCreateSource, mappedCtx, err) abort
    call a:ctxCreateSource['removeSubscription'](a:mappedCtx['subscription'])
    call a:ctxCreateSource['cancelSubscriptions']()
    call a:ctxCreateSource['o']['error'](a:err)
    call a:ctxCreateSource['unsubscribe']()
endfunction

function! s:flatMapMappedCompleteFn(ctxCreateSource, mappedCtx) abort
    call a:ctxCreateSource['removeSubscription'](a:mappedCtx['subscription'])
    if a:ctxCreateSource['finished'] && empty(a:ctxCreateSource['subscriptionList'])
        call a:ctxCreateSource['o']['complete']()
    endif
endfunction
" }}}

" map() {{{
function! callbag#map(mapper) abort
    let l:ctx = { 'mapper': a:mapper }
    return function('s:mapFn', [l:ctx])
endfunction

function! s:mapFn(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
    return callbag#createSource(function('s:mapCreateSourceFn', [l:ctxSource]))
endfunction

function! s:mapCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = { 'ctxSource': a:ctxSource, 'o': a:o }
    let l:observer = {
        \ 'next': function('s:mapNextFn', [l:ctxCreateSource]),
        \ 'error': a:o.error,
        \ 'complete': a:o.complete,
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:mapNextFn(ctxCreateSource, value) abort
    call a:ctxCreateSource['o']['next'](a:ctxCreateSource['ctxSource']['ctx']['mapper'](a:value))
endfunction
" }}}

" mapTo() {{{
function! callbag#mapTo(value) abort
    return callbag#map(function('s:mapToFn', [a:value]))
endfunction

function! s:mapToFn(value, ...) abort
    return a:value
endfunction
" }}}

" scan() {{{
function! callbag#scan(reducer, seed) abort
    let l:ctx = { 'reducer': a:reducer, 'seed': a:seed }
    return function('s:scanFn', [l:ctx])
endfunction

function! s:scanFn(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
    return callbag#createSource(function('s:scanCreateSourceFn', [l:ctxSource]))
endfunction

function! s:scanCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = { 'ctxSource': a:ctxSource, 'o': a:o,
        \ 'acc': a:ctxSource['ctx']['seed'] }
    let l:observer = {
        \ 'next': function('s:scanNextFn', [l:ctxCreateSource]),
        \ 'error': a:o.error,
        \ 'complete': a:o.complete,
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:scanNextFn(ctxCreateSource, value) abort
    let a:ctxCreateSource['acc'] = a:ctxCreateSource['ctxSource']['ctx']['reducer'](a:ctxCreateSource['acc'], a:value)
    call a:ctxCreateSource['o']['next'](a:ctxCreateSource['acc'])
endfunction
" }}}

" reduce() {{{
function! callbag#reduce(reducer, seed) abort
    let l:ctx = { 'reducer': a:reducer, 'seed': a:seed }
    return function('s:reduceFn', [l:ctx])
endfunction

function! s:reduceFn(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
    return callbag#createSource(function('s:reduceCreateSourceFn', [l:ctxSource]))
endfunction

function! s:reduceCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = { 'ctxSource': a:ctxSource, 'o': a:o,
        \ 'acc': a:ctxSource['ctx']['seed'] }
    let l:observer = {
        \ 'next': function('s:reduceNextFn', [l:ctxCreateSource]),
        \ 'error': a:o.error,
        \ 'complete': function('s:reduceCompleteFn', [l:ctxCreateSource])
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:reduceNextFn(ctxCreateSource, value) abort
    let a:ctxCreateSource['acc'] = a:ctxCreateSource['ctxSource']['ctx']['reducer'](a:ctxCreateSource['acc'], a:value)
endfunction

function! s:reduceCompleteFn(ctxCreateSource) abort
    call a:ctxCreateSource['o']['next'](a:ctxCreateSource['acc'])
    call a:ctxCreateSource['o']['complete']()
endfunction
" }}}

" take() {{{
function! callbag#take(count) abort
    let l:ctx = { 'count': a:count }
    return function('s:takeSource', [l:ctx])
endfunction

function! s:takeSource(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
    return callbag#createSource(function('s:takeCreateSource', [l:ctxSource]))
endfunction

function! s:takeCreateSource(ctxSource, o) abort
    if a:ctxSource['ctx']['count'] <= 0
        call a:o['complete']()
        return
    endif

    let l:ctxCreateSource = {
        \ 'ctxSource': a:ctxSource,
        \ 'o': a:o,
        \ 'taken': 0,
        \ 'unsubscribe': function('s:noop')
        \ }

    let l:observer = {
        \   'next': function('s:takeNextFn', [l:ctxCreateSource]),
        \   'error': a:o['error'],
        \   'complete': a:o['complete'],
        \ }

    let l:ctxCreateSource['unsubscribe'] = callbag#subscribe(l:observer)(a:ctxSource['source'])

    return l:ctxCreateSource['unsubscribe']
endfunction

function! s:takeNextFn(ctxCreateSource, value) abort
    call a:ctxCreateSource['o']['next'](a:value)
    let a:ctxCreateSource['taken'] += 1

    if a:ctxCreateSource['taken'] >= a:ctxCreateSource['ctxSource']['ctx']['count']
        call a:ctxCreateSource['unsubscribe']()
        call a:ctxCreateSource['o']['complete']()
    endif
endfunction
" }}}

" tap {{{
function! callbag#tap(...) abort
    let l:ctx = {}
    if a:0 > 0 && type(a:1) == type({}) " a:1 { next, error, complete }
        if has_key(a:1, 'next') | let l:ctx['next'] = a:1['next'] | endif
        if has_key(a:1, 'error') | let l:ctx['error'] = a:1['error'] | endif
        if has_key(a:1, 'complete') | let l:ctx['complete'] = a:1['complete'] | endif
    else " a:1 = next, a:2 = error, a:3 = complete
        if a:0 >= 1 | let l:ctx['next'] = a:1 | endif
        if a:0 >= 2 | let l:ctx['error'] = a:2 | endif
        if a:0 >= 3 | let l:ctx['complete'] = a:3 | endif
    endif
    return function('s:tapFn', [l:ctx])
endfunction

function! s:tapFn(ctx, source) abort
    let l:ctxSource = { 'ctx': a:ctx, 'source': a:source }
    return callbag#createSource(function('s:tapCreateSourceFn', [l:ctxSource]))
endfunction

function! s:tapCreateSourceFn(ctxSource, o) abort
    let l:ctxCreateSource = { 'ctxSource': a:ctxSource, 'o': a:o }
    let l:observer = {
        \ 'next': function('s:tapNextFn', [l:ctxCreateSource]),
        \ 'error': function('s:tapErrorFn', [l:ctxCreateSource]),
        \ 'complete': function('s:tapCompleteFn', [l:ctxCreateSource]),
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:tapNextFn(ctxCreateSource, value) abort
    if has_key(a:ctxCreateSource['ctxSource']['ctx'], 'next') | call a:ctxCreateSource['ctxSource']['ctx']['next'](a:value) | endif
    call a:ctxCreateSource['o']['next'](a:value)
endfunction

function! s:tapErrorFn(ctxCreateSource, err) abort
    if has_key(a:ctxCreateSource['ctxSource']['ctx'], 'error') | call a:ctxCreateSource['ctxSource']['ctx']['error'](a:err) | endif
    call a:ctxCreateSource['o']['error'](a:err)
endfunction

function! s:tapCompleteFn(ctxCreateSource) abort
    if has_key(a:ctxCreateSource['ctxSource']['ctx'], 'complete') | call a:ctxCreateSource['ctxSource']['ctx']['complete']() | endif
    call a:ctxCreateSource['o']['complete']()
endfunction
" }}}

" toList() {{{
function! callbag#toList() abort
    return function('s:toListFn')
endfunction

function! s:toListFn(source) abort
    let l:ctxSource = { 'source': a:source }
    return callbag#createSource(function('s:toListCreateSourceFn', [l:ctxSource]))
endfunction

function! s:toListCreateSourceFn(ctxSource, o) abort
    let l:ctxCreate = { 'o': a:o, 'values': [] }
    let l:observer = {
        \ 'next': function('s:toListNextFn', [l:ctxCreate]),
        \ 'error': a:o['error'],
        \ 'complete': function('s:toListCompleteFn', [l:ctxCreate]),
        \ }
    return callbag#subscribe(l:observer)(a:ctxSource['source'])
endfunction

function! s:toListNextFn(ctxCreate, value) abort
    call add(a:ctxCreate['values'], a:value)
endfunction

function! s:toListCompleteFn(ctxCreate) abort
    call a:ctxCreate['o']['next'](a:ctxCreate['values'])
    call a:ctxCreate['o']['complete']()
endfunction
" }}}

" toBlockingList() {{{
function! callbag#toBlockingList() abort
    return function('s:toBlockingListFn')
endfunction

function! s:toBlockingListFn(source) abort
    let l:ctxSource = { 'source': a:source,
        \ 'done': 0, 'items': [], 'unsubscribed': 0 }
    let l:ctxSource['unsubscribe'] = callbag#subscribe(
        \ function('s:toBlockingListNextFn', [l:ctxSource]),
        \ function('s:toBlockingListErrorFn', [l:ctxSource]),
        \ function('s:toBlockingListCompleteFn', [l:ctxSource]),
        \ )(a:source)
    if l:ctxSource['done'] | call s:toBlockingListUnsubscribe(l:ctxSource) | endif
    return {
        \   'unsubscribe': function('s:toBlockingListUnsubscribe', [l:ctxSource]),
        \   'wait': function('s:toBlockingListWait', [l:ctxSource])
        \ }
endfunction

function! s:toBlockingListUnsubscribe(ctxSource) abort
    if !has_key(a:ctxSource, 'unsubscribe') | return | endif
    if !a:ctxSource['unsubscribed']
        let a:ctxSource['unsubscribed'] = 1
        call a:ctxSource['unsubscribe']()
        if !a:ctxSource['done']
            let a:ctxSource['done'] = 1
        endif
    endif
endfunction

function! s:toBlockingListNextFn(ctxSource, value) abort
    call add(a:ctxSource['items'], a:value)
endfunction

function! s:toBlockingListErrorFn(ctxSource, err) abort
    let a:ctxSource['done'] = 1
    let a:ctxSource['error'] = a:err
endfunction

function! s:toBlockingListCompleteFn(ctxSource) abort
    let a:ctxSource['done'] = 1
    call s:toBlockingListUnsubscribe(a:ctxSource)
endfunction

function! s:toBlockingListWait(ctxSource, ...) abort
    if a:ctxSource['done']
        if has_key(a:ctxSource, 'error')
            throw a:ctxSource['error']
        else
            return a:ctxSource['items']
        endif
    else
        let l:opt = a:0 > 0 ? copy(a:1) : {}
        let l:opt['timedout'] = 0
        let l:opt['sleep'] = get(l:opt, 'sleep', 1)
        let l:opt['timeout'] = get(l:opt, 'timeout', -1)

        if l:opt['timeout'] > -1
            let l:opt['timer'] = timer_start(l:opt['timeout'], function('s:toBlockingListTimeoutCallback', [l:opt]))
        endif

        while !a:ctxSource['done'] && !l:opt['timedout']
            exec 'sleep ' . l:opt['sleep'] . 'm'
        endwhile

        if has_key(l:opt, 'timer')
            silent! call timer_stop(l:opt['timer'])
        endif

        call s:toBlockingListUnsubscribe(a:ctxSource)

        if l:opt['timedout']
            throw 'callbag toBlockingList().wait() timedout.'
        endif

        if has_key(a:ctxSource, 'error')
            throw a:ctxSource['error']
        else
            return a:ctxSource['items']
        endif
    endif
endfunction

function! s:toBlockingListTimeoutCallback(opt, ...) abort
    let a:opt['timedout'] = 1
endfunction

" }}}

" }}}

" vim: set sw=4 ts=4 sts=4 et tw=78 foldmarker={{{,}}} foldmethod=marker foldlevel=1 spell:
