" Vim script
" Last Change: July 12, 2010
" Author: Peter Odding
" URL: http://peterodding.com/code/vim/reload/
" License: MIT
" Version: 0.3

if !exists('g:reload_on_write')
  let g:reload_on_write = 1
endif

command! -bar -nargs=? -complete=file ReloadScript call s:ReloadCmd(<q-args>)

augroup PluginReloadScripts
  autocmd!
  autocmd BufWritePost *.vim call s:AutoReload()
  autocmd TabEnter * call xolox#reload#windows()
augroup END

function! s:ReloadCmd(arg)
  if a:arg !~ '\S'
    call xolox#reload#script(expand('%:p'))
  else
    call xolox#reload#script(fnamemodify(a:arg, ':p'))
  endif
endfunction

if !exists('s:auto_reload_active')
  function! s:AutoReload()
    if g:reload_on_write
      let s:auto_reload_active = 1
      call xolox#reload#script(expand('%:p'))
      unlet s:auto_reload_active
    endif
  endfunction
endif

" vim: ts=2 sw=2 et
