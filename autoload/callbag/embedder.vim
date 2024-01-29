let s:autoload_root = expand('<sfile>:p:h:h')
let s:git_dir = simplify(expand('<sfile>:p:h:h:h') . '/.git')

function! s:get_git_commit() abort
    if !executable('git') || !isdirectory(s:git_dir)
        return 'UNKNOWN'
    endif

    let l:git = 'git --git-dir=' . shellescape(s:git_dir) . ' '
    let l:commit = substitute(system(l:git . 'rev-parse HEAD'), '\n\+$', '', '') " remove \n and null bytes
    " let l:is_dirty = system(l:git . 'status --porcelain') =~? '\S'
    " return l:commit . (l:is_dirty ? ' (dirty)' : '')
    return l:commit
endfunction

function! callbag#embedder#embed(...) abort
	let l:args = {}

	for l:arg in a:000
		let l:idx = stridx(l:arg, '=')
		let l:key = l:arg[:l:idx - 1]
		let l:value = l:arg[l:idx + 1:]
		let l:args[l:key] = l:value
	endfor

	if !has_key(l:args, 'path')
		echom 'path required'
		return
	endif

	if !has_key(l:args, 'namespace')
		echom 'namespace required'
	endif
	
	let l:lines = readfile(s:autoload_root . '/callbag.vim')
	let l:lines = map(l:lines, {_, l -> substitute(l, '__callbag', '__' . substitute(l:args['namespace'], '#', '__', 'g'), 'g')})
	let l:lines = map(l:lines, {_, l -> substitute(l, '\V\C\<callbag', l:args['namespace'], 'g')})
	
	let l:content = [
		\ printf('" https://github.com/prabirshrestha/callbag.vim#%s', s:get_git_commit()),
		\ '"    :CallbagEmbed ' . join(a:000, ' '),
		\ '',	
		\ ]

	let l:content += l:lines
	call mkdir(fnamemodify(l:args['path'], ':h'), 'p')
	call writefile(l:content, l:args['path'])
endfunction
