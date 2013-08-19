" Vim script
" Last Change: August 19, 2013
" Author: Peter Odding
" URL: http://peterodding.com/code/vim/reload/

" Support for automatic update using the GLVS plug-in.
" GetLatestVimScripts: 3148 1 :AutoInstall: reload.zip

" Don't source the plug-in when it's already been loaded or &compatible is set.
if &cp || exists('g:loaded_reload')
  finish
endif

" Make sure vim-misc is installed.
try
  " The point of this code is to do something completely innocent while making
  " sure the vim-misc plug-in is installed. We specifically don't use Vim's
  " exists() function because it doesn't load auto-load scripts that haven't
  " already been loaded yet (last tested on Vim 7.3).
  call type(g:xolox#misc#version)
catch
  echomsg "Warning: The vim-reload plug-in requires the vim-misc plug-in which seems not to be installed! For more information please review the installation instructions in the readme (also available on the homepage and on GitHub). The vim-reload plug-in will now be disabled."
  let g:loaded_reload = 1
  finish
endtry

if !exists('g:reload_on_write')
  let g:reload_on_write = 1
endif

command! -bar -nargs=? -complete=file ReloadScript call s:ReloadCmd(<q-args>)

augroup PluginReloadScripts
  autocmd!
  autocmd BufWritePost *.vim nested call s:AutoReload()
  " The nested keyword is so that SwapExists isn't ignored!
  autocmd SwapExists * call xolox#reload#open_readonly()
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

" Don't reload the plug-in once it has loaded successfully.
let g:loaded_reload = 1

" vim: ts=2 sw=2 et
