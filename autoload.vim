" Vim script
" Last Change: July 13, 2010
" Author: Peter Odding
" URL: http://peterodding.com/code/vim/reload/

let s:script = expand('<sfile>:t')

" Patterns to match various types of Vim script names. {{{1

" Enable line continuation.
let s:cpo_save = &cpo
set cpoptions-=C

if has('win32') || has('win64')
  let s:scripttypes = [
        \ ['s:reload_plugin', '\c[\\/]plugin[\\/].\{-}\.vim$'],
        \ ['s:reload_autoload', '\c[\\/]autoload[\\/].\{-}\.vim$'],
        \ ['s:reload_ftplugin', '\c[\\/]ftplugin[\\/][^\\/]\+\.vim$'],
        \ ['s:reload_syntax', '\c[\\/]syntax[\\/][^\\/]\+\.vim$'],
        \ ['s:reload_indent', '\c[\\/]indent[\\/][^\\/]\+\.vim$'],
        \ ['s:reload_colors', '\c[\\/]colors[\\/][^\\/]\+\.vim$']]
else
  let s:scripttypes = [
        \ ['s:reload_plugin', '\C/plugin/.\{-}\.vim$'],
        \ ['s:reload_autoload', '\C/autoload/.\{-}\.vim$'],
        \ ['s:reload_ftplugin', '\C/ftplugin/[^/]\+\.vim$'],
        \ ['s:reload_syntax', '\C/syntax/[^/]\+\.vim$'],
        \ ['s:reload_indent', '\C/indent/[^/]\+\.vim$'],
        \ ['s:reload_colors', '\C/colors/[^/]\+\.vim$']]
endif

" Restore compatibility options
let &cpo = s:cpo_save
unlet s:cpo_save

if !exists('s:reload_script_active')
  function! xolox#reload#script(filename) " {{{1
    let s:reload_script_active = 1
    let start_time = xolox#timer#start()
    if s:script_sourced(a:filename)
      let filename = s:unresolve_scriptname(a:filename)
      for [callback, pattern] in s:scripttypes
        if filename =~ pattern
          let friendly_name = fnamemodify(filename, ':~')
          call call(callback, [start_time, filename, friendly_name])
        endif
      endfor
    endif
    unlet s:reload_script_active
  endfunction
endif

function! s:reload_plugin(start_time, filename, friendly_name) " {{{1
  call s:reload_message('plug-in', a:friendly_name)
  execute 'source' fnameescape(a:filename)
  let msg = "%s: Reloaded %s plug-in in %s."
  call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
endfunction

if !exists('s:reload_script_active')
  function! s:reload_autoload(start_time, filename, friendly_name) " {{{1
    call s:reload_message('auto-load script', a:friendly_name)
    execute 'source' fnameescape(a:filename)
    let msg = "%s: Reloaded %s auto-load script in %s."
    call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
  endfunction
endif

function! s:reload_ftplugin(start_time, filename, friendly_name) " {{{1
  let type = fnamemodify(a:filename, ':t:r')
  let view = s:save_view()
  call s:change_swapchoice(1)
  call s:reload_message('file type plug-in', a:friendly_name)
  silent hide bufdo if &ft == type | let b:reload_ftplugin = 1 | endif
  call xolox#reload#windows()
  call s:restore_view(view)
  call s:change_swapchoice(0)
  let msg = "%s: Reloaded %s file type plug-in in %s."
  call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
endfunction

function! s:reload_syntax(start_time, filename, friendly_name) " {{{1
  let type = fnamemodify(a:filename, ':t:r')
  let view = s:save_view()
  call s:change_swapchoice(1)
  call s:reload_message('syntax highlighting', a:friendly_name)
  silent hide bufdo if &syn == type | let b:reload_syntax = 1 | endif
  call xolox#reload#windows()
  call s:restore_view(view)
  call s:change_swapchoice(0)
  let msg = "%s: Reloaded %s syntax script in %s."
  call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
endfunction

function! s:reload_indent(start_time, filename, friendly_name) " {{{1
  let type = fnamemodify(a:filename, ':t:r')
  let view = s:save_view()
  call s:change_swapchoice(1)
  call s:reload_message('indentation plug-in', a:friendly_name)
  silent hide bufdo if &ft == type | let b:reload_indent = 1 | endif
  call xolox#reload#windows()
  call s:restore_view(view)
  call s:change_swapchoice(0)
  let msg = "%s: Reloaded %s indent script in %s."
  call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
endfunction

function! xolox#reload#windows() " {{{1
  let window = winnr()
  try
    windo call s:reload_window()
  finally
    execute window . 'wincmd w'
  endtry
endfunction

function! s:reload_window()
  if exists('b:reload_ftplugin')
    unlet! b:reload_ftplugin b:did_ftplugin
    let &filetype = &filetype
  endif
  if exists('b:reload_syntax')
    unlet! b:reload_syntax b:current_syntax
    let &syntax = &syntax
  endif
  if exists('b:reload_indent')
    unlet! b:reload_indent b:did_indent
    let &filetype = &filetype
  endif
endfunction

function! s:reload_colors(start_time, filename, friendly_name) " {{{1
  let colorscheme = fnamemodify(a:filename, ':t:r')
  if exists('g:colors_name') && g:colors_name == colorscheme
    call s:reload_message('color scheme', a:friendly_name)
    let escaped = fnameescape(colorscheme)
    execute 'colorscheme' escaped
    execute 'doautocmd colorscheme' escaped
    let msg = "%s: Reloaded %s color scheme in %s."
    call xolox#timer#stop(msg, s:script, a:friendly_name, a:start_time)
  endif
endfunction

" Miscellaneous functions. {{{1

let s:loaded_scripts = {}

function! s:script_sourced(filename) " {{{2
  call s:parse_scriptnames()
  return has_key(s:loaded_scripts, resolve(a:filename))
endfunction

function! s:unresolve_scriptname(filename) " {{{2
  call s:parse_scriptnames()
  return get(s:loaded_scripts, resolve(a:filename), a:filename)
endfunction

function! s:parse_scriptnames() " {{{2
  let listing = ''
  redir => listing
  silent scriptnames
  redir END
  let lines = split(listing, "\n")
  let num_loaded = len(s:loaded_scripts)
  if len(lines) > num_loaded
    for line in lines[num_loaded : -1]
      let filename = matchstr(line, '^\s*\d\+:\s\+\zs.\+$')
      let s:loaded_scripts[resolve(filename)] = filename
    endfor
  endif
endfunction

function! s:change_swapchoice(enable) " {{{2
  let augroup = 'PluginReloadScriptsSC'
  if a:enable
    execute xolox#swapchoice#change(augroup, 'e')
  else
    execute xolox#swapchoice#restore(augroup)
  endif
endfunction

function! s:reload_message(scripttype, scriptname) " {{{2
  call xolox#message('%s: Reloading %s %s', s:script, a:scripttype, a:scriptname)
endfunction

function! s:save_view() " {{{2
  return [bufnr('%'), winsaveview()]
endfunction

function! s:restore_view(view) " {{{2
  silent execute 'buffer' a:view[0]
  call winrestview(a:view[1])
endfunction

" vim: ts=2 sw=2 et
