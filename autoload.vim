" Vim script
" Last Change: July 23, 2010
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
          let args = [start_time, filename, fnamemodify(filename, ':~')]
          let result = call(callback, args)
          if type(result) == type([])
            call call('xolox#timer#stop', result)
          endif
          unlet result
        endif
      endfor
    endif
    unlet s:reload_script_active
  endfunction
endif

function! s:reload_plugin(start_time, filename, friendly_name) " {{{1
  call s:reload_message('plug-in', a:friendly_name)
  " Clear include guard so full plug-in can be reloaded?
  let variable = 'g:loaded_' . fnamemodify(a:filename, ':t:r')
  if exists(variable)
    execute 'unlet' variable
  endif
  execute 'source' fnameescape(a:filename)
  return ["%s: Reloaded %s plug-in in %s.", s:script, a:friendly_name, a:start_time]
endfunction

if !exists('s:reload_script_active')
  function! s:reload_autoload(start_time, filename, friendly_name) " {{{1
    call s:reload_message('auto-load script', a:friendly_name)
    execute 'source' fnameescape(a:filename)
    return ["%s: Reloaded %s auto-load script in %s.", s:script, a:friendly_name, a:start_time]
  endfunction
endif

function! s:reload_ftplugin(st, fn, hr) " {{{1
  return s:reload_buffers(a:st, a:fn, a:hr, 'file type plug-in', 'b:reload_ftplugin')
endfunction

function! s:reload_syntax(st, fn, hr) " {{{1
  return s:reload_buffers(a:st, a:fn, a:hr, 'syntax script', 'b:reload_syntax')
endfunction

function! s:reload_indent(st, fn, hr) " {{{1
  return s:reload_buffers(a:st, a:fn, a:hr, 'indent script', 'b:reload_indent')
endfunction

function! s:reload_buffers(start_time, filename, friendly_name, script_type, variable)
  let type = fnamemodify(a:filename, ':t:r')
  " Make sure we can restore the user's context after reloading!
  let bufnr_save = bufnr('%')
  let view_save = winsaveview()
  " Temporarily enable the SwapExists automatic command to prevent the E325
  " prompt from rearing its ugly head while reloading (in :bufdo below).
  let s:reloading_buffers = 1
  call s:reload_message(a:script_type, a:friendly_name)
  silent hide bufdo if &ft == type | execute 'let' a:variable '= 1' | endif
  call xolox#reload#windows()
  " Restore the user's context.
  silent execute 'buffer' bufnr_save
  call winrestview(view_save)
  " Disable the SwapExists automatic command.
  unlet s:reloading_buffers
  return ["%s: Reloaded %s %s in %s.", s:script, a:script_type, a:friendly_name, a:start_time]
endfunction

function! xolox#reload#open_readonly() " {{{1
  if exists('s:reloading_buffers')
    let v:swapchoice = 'o'
  endif
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
    return ["%s: Reloaded %s color scheme in %s.", s:script, a:friendly_name, a:start_time]
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

function! s:reload_message(scripttype, scriptname) " {{{2
  call xolox#message('%s: Reloading %s %s', s:script, a:scripttype, a:scriptname)
endfunction

" vim: ts=2 sw=2 et
