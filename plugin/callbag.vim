if exists('g:callbag_vim')
    finish
endif
let g:callbag_vim = 1

command! -nargs=+ CallbagEmbed :call callbag#embedder#embed(<f-args>)
