function! s:log(...) abort
    echom json_encode([strftime('%X'), a:000])
endfunction

function! callbag#demo() abort
    " simulate async
    call callbag#pipe(
        \   callbag#of(1, 2, 3, 4, 5),
        \   callbag#flatMap({x->
        \       callbag#pipe(
        \           callbag#timer(rand(s:seed) % 10000),
        \           callbag#mapTo(x),
        \       )
        \   }),
        \   callbag#subscribe({
        \   'next':{x->s:log('next', x)},
        \   'error':{e->s:log('error', e)},
        \   'complete':{->s:log('complete')},
        \ })
        \ )

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
        \ callbag#subscribe(
        \   {x->s:log('next will not be called')},
        \   {e->s:log('error will not be called')},
        \   {->s:log('complete will not be called')},
        \ ),
        \ )
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
        \ callbag#lazy({->2*10}),
        \ callbag#subscribe({
        \   'next':{x->s:log('next ' . x)},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#throwError('my dummy error'),
        \ callbag#subscribe({
        \   'next': {x->s:log('next will never be called')},
        \   'error': {e->s:log('error called with ' . e)},
        \   'complete': {->s:log('complete will never be called')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#of(1, 2, 3, 4),
        \ callbag#subscribe({
        \   'next': {x->s:log('next value is ' . x)},
        \   'complete': {->s:log('completed of')},
        \ }),
        \ )
     call callbag#pipe(
        \ callbag#merge(
        \   callbag#fromEvent('InsertEnter'),
        \   callbag#fromEvent('InsertLeave'),
        \ ),
        \ callbag#forEach({x->s:log('InsertEnter or InsertLeave')}),
        \ )
     call callbag#pipe(
        \ callbag#fromEvent('TextChangedI', 'text_change_autocmd_group_name'),
        \ callbag#takeUntil(
        \   callbag#fromEvent('InsertLeave', 'insert_leave_autocmd_group_name'),
        \ ),
        \ callbag#debounceTime(250),
        \ callbag#subscribe({
        \   'next': {x->s:log('next')},
        \   'error': {x->s:log('error')},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )
     call callbag#pipe(
        \ callbag#fromEvent('InsertEnter'),
        \ callbag#delay(2000),
        \ callbag#forEach({x->s:log('next')}),
        \ )
     call callbag#pipe(
        \ callbag#of(1,2,3,4,5,6,7,8,9),
        \ callbag#group(3),
        \ callbag#forEach({x->s:log(x)}),
        \ )
     call callbag#pipe(
        \ callbag#fromEvent('InsertEnter'),
        \ callbag#map({x->callbag#interval(1000)}),
        \ callbag#flatten(),
        \ callbag#forEach({x->s:log(x)}),
        \ )
     call callbag#pipe(
        \ callbag#of(1,2,3,4,5),
        \ callbag#scan({prev, x-> prev + x}, 0),
        \ callbag#forEach({x->s:log(x)}),
        \ )
    call callbag#pipe(
        \ callbag#of(1,2,3,4,5),
        \ callbag#reduce({prev, x-> prev + x}, 0),
        \ callbag#forEach({x->s:log(x)}),
        \ )
    call callbag#pipe(
        \ callbag#concat(
        \  callbag#of(1,2,3),
        \  callbag#of(4,5,6),
        \ ),
        \ callbag#subscribe({
        \   'next':{x->s:log('next ' . x)},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#combine(
        \  callbag#interval(100),
        \  callbag#interval(350),
        \ ),
        \ callbag#take(10),
        \ callbag#skip(2),
        \ callbag#subscribe({
        \   'next':{x->s:log('next '. x[0] . ' ' . x[1])},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )
    call callbag#pipe(
        \ callbag#of(1, 2, 3, 4, 5),
        \ callbag#takeWhile({x -> x != 4}),
        \ callbag#subscribe({
        \   'next':{x->s:log('next ' . x)},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )

    let l:MapAndTake3 = callbag#operate(
        \ callbag#map({x->x*10}),
        \ callbag#take(3),
        \ )
    call callbag#pipe(
        \ callbag#of(1,2,3,4,5,6,7,8,9),
        \ l:MapAndTake3,
        \ callbag#subscribe({
        \   'next': {x->s:log(x)},
        \   'complete': {->s:log('complete')},
        \ })
        \ )
    call callbag#pipe(
        \ callbag#fromList([1,2,3,4]),
        \ callbag#subscribe({
        \   'next': {x->s:log(x)},
        \   'complete': {->s:log('complete')},
        \ }),
        \ )

        let l:subject = callbag#createSubject()

        let l:result = callbag#pipe(
            \ s:subject.asObservable(),
            \ callbag#take(3),
            \ callbag#subscribe({
            \   'next': {x-> s:log(x)},
            \   'complete': {-> s:log('complete')},
            \ }),
            \ )

        call s:subject['next']('a')
        call s:subject['next']('b')
        call s:subject['next']('c')
        call s:subject['next']('d')
        call s:subject['next']('e')

    let s:ShareSource = callbag#share()(
        \ callbag#pipe(
        \   callbag#interval(1000),
        \   callbag#take(10),
        \ )
        \ )
    call callbag#pipe(
        \ s:ShareSource,
        \ callbag#subscribe({
        \   'next': {x->s:log(['first',x])},
        \   'complete': {->s:log(['first','complete'])},
        \ })
        \ )
    call timer_start(3500, {->callbag#pipe(
        \ s:ShareSource,
        \ callbag#subscribe({
        \   'next': {x->s:log(['second',x])},
        \   'complete': {->s:log(['second','complete'])},
        \ })
        \ )})


    call callbag#pipe(
        \ callbag#of(1, 1, 2, 3, 3, 3, 4, 1, 5),
        \ callbag#distinctUntilChanged(),
        \ callbag#subscribe({
        \   'next': {x->s:log('next ' . x)},
        \   'complete': {-> s:log('complete')},
        \ }),
        \ )

    call callbag#pipe(
        \ callbag#of('hi'),
        \ callbag#switchMap({->callbag#of(10, 20, 30)}, {char, num-> char . num}),
        \ callbag#subscribe({
        \   'next':{x->s:log(x)},
        \   'error':{e->s:log(e)},
        \   'complete':{->s:log('complete')},
        \ }),
        \ )
    
    call callbag#pipe(
        \ callbag#of(1, 2, 3),
        \ callbag#tap({'next':{x->s:log(x)}, 'complete':{->s:log('complete')}}),
        \ callbag#subscribe(),
        \ )

    call callbag#pipe(
        \ callbag#of(1, 2, 3),
        \ callbag#materialize(),
        \ callbag#subscribe({
        \   'next':{x->s:log(['next', x, callbag#isNextNotification(x), callbag#isErrorNotification(x), callbag#isCompleteNotification(x)])},
        \   'error':{x->s:log(['error', x])},
        \   'complete':{->s:log('complete')},
        \ })
        \ )

    let l:undefined = callbag#undefined()
    echom callbag#isUndefined(l:undefined)
    echom callbag#isUndefined({})

    try
        let l:result = callbag#pipe(
            \ callbag#interval(250),
            \ callbag#take(3),
            \ callbag#toBlockingList(),
            \ ).wait({ 'sleep': 1, 'timeout': 5000 })
        echom l:result
    catch
        " error may be thrown due to timeout or if it emits error
        echom v:exception . ' ' . v:throwpoint
    endtry

    " let s:stdin = callbag#createSubject()
    " call callbag#pipe(
    "     \ callbag#spawn(['bash', '-c', 'read i; echo $i'], {
    "     \   'stdin': s:stdin.asObservable(),
    "     \   'stdout': 1,
    "     \ }),
    "     \ callbag#subscribe({
    "     \   'next':{x->s:log(['next', x])},
    "     \   'complete':{->s:log('complete')},
    "     \   'error':{x->s:log(['error', x])},
    "     \ }),
    "     \ )
    " call s:stdin.next('hello')
    " call s:stdin.next('world')
    " call s:stdin.complete()

    " Plug 'vim-jp/vital.vim'
    "
    " call callbag#pipe(
    "     \   callbag#fromPromise(s:promiseWait(2000)),
    "     \   callbag#subscribe({
    "     \       'next': {x->s:log('next')},
    "     \       'complete':{->s:log('complete')},
    "     \       'error': {e->s:log('error')},
    "     \   })
    "     \ )
endfunction

function! s:promiseWait(ms)
    let s:V = vital#vital#new()
    let s:Promise = s:V.import('Async.Promise')
    return s:Promise.new({resolve -> timer_start(a:ms, resolve)})
endfunction
