function! callbag#undefined() abort
    return '__callback_undefined__'
endfunction

function! s:noop(...) abort
endfunction

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

" create() {{{
function! callbag#create(...) abort
    let l:data = {}
    if a:0 > 0
        let l:data['prod'] = a:1
    endif
    return function('s:createProd', [l:data])
endfunction

function! s:createProd(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['sink'] = a:sink
    if !has_key(a:data, 'prod') || type(a:data['prod']) != type(function('s:noop'))
        call a:sink(0, function('s:noop'))
        call a:sink(2, callbag#undefined())
        return
    endif
    let a:data['end'] = 0
    call a:sink(0, function('s:createSinkCallback', [a:data]))
    if a:data['end'] | return | endif
    let a:data['clean'] = a:data['prod'](function('s:createNext', [a:data]), function('s:createError', [a:data]), function('s:createComplete', [a:data]))
endfunction

function! s:createSinkCallback(data, t, ...) abort
    if !a:data['end']
        let a:data['end'] = (a:t == 2)
        if a:data['end'] && has_key(a:data, 'clean') && type(a:data['clean']) == type(function('s:noop'))
            call a:data['clean']()
        endif
    endif
endfunction

function! s:createNext(data, d) abort
    if !a:data['end'] | call a:data['sink'](1, a:d) | endif
endfunction

function! s:createError(data, e) abort
    if !a:data['end'] && e != callbag#undefined()
        let a:data['end'] = 1
        call a:data['sink'](2, a:e)
    endif
endfunction

function! s:createComplete(data) abort
    if !a:data['end']
        let a:data['end'] = 1
        call a:data['sink'](2, callbag#undefined())
    endif
endfunction
" }}}

" empty() {{{
function! callbag#empty() abort
    let l:data = {}
    return function('s:emptyStart', [l:data])
endfunction

function! s:emptyStart(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['disposed'] = 0
    call a:sink(0, function('s:emptySinkCallback', [a:data]))
    if a:data['disposed'] | return | endif
    call a:sink(2, callbag#undefined())
endfunction

function! s:emptySinkCallback(data, t, ...) abort
    if a:t != 2 | return | endif
    let a:data['disposed'] = 1
endfunction

function! s:empty_sink_callback(data, t, ...) abort
    if a:t == 2 | call timer_stop(a:data['timer']) | endif
endfunction
" }}}

" never() {{{
function! callbag#never() abort
    return function('s:never')
endfunction

function! s:never(start, sink) abort
    if a:start != 0 | return | endif
    call a:sink(0, function('s:noop'))
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

function! s:forEachOperationSource(data, t, d) abort
    if a:t == 0 | let a:data['talkback'] = a:d | endif
    if a:t == 1 | call a:data['operation'](a:d) | endif
    if (a:t == 1 || a:t == 0) | call a:data['talkback'](1, callbag#undefined()) | endif
endfunction
" }}}

" interval() {{{
function! callbag#interval(period) abort
    let l:data = { 'period': a:period }
    return function('s:intervalPeriod', [l:data])
endfunction

function! s:intervalPeriod(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['i'] = 0
    let a:data['sink'] = a:sink
    let a:data['timer'] = timer_start(a:data['period'], function('s:interval_callback', [a:data]), { 'repeat': -1 })
    call a:sink(0, function('s:interval_sink_callback', [a:data]))
endfunction

function! s:interval_callback(data, ...) abort
    let l:i = a:data['i']
    let a:data['i'] = a:data['i'] + 1
    call a:data['sink'](1, l:i)
endfunction

function! s:interval_sink_callback(data, t, ...) abort
    if a:t == 2 | call timer_stop(a:data['timer']) | endif
endfunction
" }}}

" take() {{{
function! callbag#take(max) abort
    let l:data = { 'max': a:max }
    return function('s:takeMax', [l:data])
endfunction

function! s:takeMax(data, source) abort
    let a:data['source'] = a:source
    return function('s:takeMaxSource', [a:data])
endfunction

function! s:takeMaxSource(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['taken'] = 0
    let a:data['end'] = 0
    let a:data['sink'] = a:sink
    let a:data['talkback'] = function('s:takeTalkback', [a:data])
    call a:data['source'](0, function('s:takeSourceCallback', [a:data]))
endfunction

function! s:takeTalkback(data, t, d) abort
    if a:t == 2
        let a:data['end'] = true
        call a:data['sourceTalkback'](a:t, a:d)
    elseif a:data['taken'] < a:data['max']
        call a:data['sourceTalkback'](a:t, a:d)
    endif
endfunction

function! s:takeSourceCallback(data, t, d) abort
    if a:t == 0
        let a:data['sourceTalkback'] = a:d
        call a:data['sink'](0, a:data['talkback'])
    elseif a:t == 1
        if a:data['taken'] < a:data['max']
            let a:data['taken'] = a:data['taken'] + 1
            call a:data['sink'](a:t, a:d)
            if a:data['taken'] == a:data['max'] && !a:data['end']
                let a:data['end'] = 1
                call a:data['sink'](2, callbag#undefined())
                call a:data['sourceTalkback'](2, callbag#undefined())
            endif
        endif
    else
        call a:data['sink'](a:t, a:d)
    endif
endfunction
" }}}

" map() {{{
function! callbag#map(F) abort
    let l:data = { 'f': a:F }
    return function('s:mapF', [l:data])
endfunction

function! s:mapF(data, source) abort
    let a:data['source'] = a:source
    return function('s:mapFSource', [a:data])
endfunction

function! s:mapFSource(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['sink'] = a:sink
    call a:data['source'](0, function('s:mapFSourceCallback', [a:data]))
endfunction

function! s:mapFSourceCallback(data, t, d) abort
    call a:data['sink'](a:t, a:t == 1 ? a:data['f'](a:d) : a:d)
endfunction
" }}}

" filter() {{{
function! callbag#filter(condition) abort
    let l:data = { 'condition': a:condition }
    return function('s:filterCondition', [l:data])
endfunction

function! s:filterCondition(data, source) abort
    let a:data['source'] = a:source
    return function('s:filterConditionSource', [a:data])
endfunction

function! s:filterConditionSource(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['sink'] = a:sink
    call a:data['source'](0, function('s:filterSourceCallback', [a:data]))
endfunction

function! s:filterSourceCallback(data, t, d) abort
    if a:t == 0
        let a:data['talkback'] = a:d
        call a:data['sink'](a:t, a:d)
    elseif a:t == 1
        if a:data['condition'](a:d)
            call a:data['sink'](a:t, a:d)
        else
            call a:data['talkback'](1, callbag#undefined())
        endif
    else
        call a:data['sink'](a:t, a:d)
    endif
endfunction
" }}}

" fromEvent() {{{
let s:event_prefix_index = 0
function! callbag#fromEvent(events, ...) abort
    let l:data = { 'events': a:events }
    if a:0 > 0
        let l:data['augroup'] = a:1
    else
        let l:data['augroup'] = 'rx_callback_event_prefix_' + s:event_prefix_index
        let s:event_prefix_index = s:event_prefix_index + 1
    endif
    return function('s:fromEventName', [l:data])
endfunction

let s:event_handler_index = 0
let s:event_handlers_data = {}
function! s:fromEventName(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['disposed'] = 0
    let a:data['sink']  = a:sink
    let a:data['handler'] = function('s:fromEventHandler', [a:data])
    let a:data['handler_index'] = s:event_handler_index
    call a:sink(0, function('s:fromEventNameSinkHandler', [a:data]))

    if a:data['disposed'] | return | endif

    let s:event_handlers_data[a:data['handler_index']] = a:data
    let s:event_handler_index = s:event_handler_index + 1

    execute 'augroup ' a:data['augroup']
        autocmd!
        let l:events = type(a:data['events']) == type('') ? [a:data['events']] : a:data['events']
        for l:event in l:events
            let l:exec =  'call s:notify_event_handler(' . a:data['handler_index'] . ')'
            if type(l:event) == type('')
                execute 'au ' . l:event . ' * ' . l:exec
            else
                execute 'au ' . join(l:event, ' ') .' ' .  l:exec
            endif
        endfor
    execute 'augroup end'
endfunction

function! s:fromEventHandler(data) abort
    " send v:event if it exists
    call a:data['sink'](1, {})
endfunction

function! s:fromEventNameSinkHandler(data, t, ...) abort
    if a:t != 2 | return | endif
    let a:data['disposed'] = 1
    execute 'augroup ' a:data['augroup']
        autocmd!
    execute 'augroup end'
    if has_key(s:event_handlers_data, a:data['handler_index'])
        call remove(s:event_handlers_data, a:data['handler_index'])
    endif
endfunction

function! s:notify_event_handler(index) abort
    let l:data = s:event_handlers_data[a:index]
    call l:data['handler']()
endfunction
" }}}

" debounceTime() {{{
function! callbag#debounceTime(duration) abort
    let l:data = { 'duration': a:duration }
    return function('s:debounceTimeDuration', [l:data])
endfunction

function! s:debounceTimeDuration(data, source) abort
    let a:data['source'] = a:source
    return function('s:debounceTimeDurationSource', [a:data])
endfunction

function! s:debounceTimeDurationSource(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['sink'] = a:sink
    call a:data['source'](0, function('s:debounceTimeSourceCallback', [a:data]))
endfunction

function! s:debounceTimeSourceCallback(data, t, d) abort
    if has_key(a:data, 'timer') | call timer_stop(a:data['timer']) | endif
    if a:t == 1
        let a:data['timer'] = timer_start(a:data['duration'], function('s:debounceTimeTimerCallback', [a:data, a:d]))
    else
        call a:data['sink'](a:t, a:d)
    endif
endfunction

function! s:debounceTimeTimerCallback(data, d, ...) abort
    call a:data['sink'](1, a:d)
endfunction
" }}}

" subscribe() {{{
function! callbag#subscribe(...) abort
    let l:data = {}
    if type(a:1) == type({}) " a:1 { next, error, complete }
        if has_key(a:1, 'next') | let l:data['next'] = a:1['next'] | endif
        if has_key(a:1, 'error') | let l:data['error'] = a:1['error'] | endif
        if has_key(a:1, 'complete') | let l:data['complete'] = a:1['complete'] | endif
    else " a:1 = next, a:2 = error, a:3 = complete
        if a:0 >= 1 | let l:data['next'] = a:1 | endif
        if a:0 >= 2 | let l:data['error'] = a:2 | endif
        if a:0 >= 3 | let l:data['complete'] = a:3 | endif
    endif
    return function('s:subscribeListener', [l:data])
endfunction

function! s:subscribeListener(data, source) abort
    call a:source(0, function('s:subscribeSourceCallback', [a:data]))
    return function('s:subscribeDispose', [a:data])
endfunction

function! s:subscribeSourceCallback(data, t, d) abort
    if a:t == 0 | let a:data['talkback'] = a:d | endif
    if a:t == 1 && has_key(a:data, 'next') && !empty(a:data['next']) | call a:data['next'](a:d) | endif
    if a:t == 1 || a:t == 0 | call a:data['talkback'](1, callbag#undefined()) | endif
    if a:t == 2 && a:d == callbag#undefined() && has_key(a:data, 'complete') && !empty(a:data['complete']) | call a:data['complete']() | endif
    if a:t == 2 && a:d != callbag#undefined() && has_key(a:data, 'error') && !empty(a:data['complete']) | call a:data['error'](a:d) | endif
endfunction

function! s:subscribeDispose(data, ...) abort
    if has_key(a:data, 'talkback') | call a:data['talkback'](2, callbag#undefined()) | endif
endfunction
" }}}

" throwError {{{
function! callbag#throwError(error) abort
    let l:data = { 'error': a:error }
    return function('s:throwErrorFactory', [l:data])
endfunction

function! s:throwErrorFactory(data, start, sink) abort
    if a:start != 0 | return | endif
    let a:data['disposed'] = 0
    call a:sink(0, function('s:throwErrorSinkCallback', [a:data]))
    if a:data['disposed'] | return | endif
    call a:sink(2, a:data['error'])
endfunction

function! s:throwErrorSinkCallback(data, t, ...) abort
    if a:t != 2 | return | endif
    let a:data['disposed'] = 1
endfunction
" }}}

" vim:ts=4:sw=4:ai:foldmethod=marker:foldlevel=0:
