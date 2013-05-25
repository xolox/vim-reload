# Automatic reloading of Vim scripts

The reload.vim plug-in automatically reloads various types of [Vim] [vim] scripts as you're editing them in Vim to give you instant feedback on the changes you make. For example while writing a Vim syntax script you can open a split window of the relevant file type and every time you [:update] [update] your syntax script, reload.vim will refresh the syntax highlighting in the split window. Automatic reloading of Vim scripts is currently supported for the following types of scripts:

 * [Standard plug-ins] [standard-plugins] located in `~/.vim/plugin` on UNIX, `~\vimfiles\plugin` on Windows;

 * [Auto-load scripts] [autoload-scripts] located in or below `~/.vim/autoload` on UNIX, `~\vimfiles\autoload` on Windows;

 * [File-type plug-ins] [filetype-plugins] located in or below `~/.vim/ftplugin` on UNIX, `~\vimfiles\ftplugin` on Windows;

 * [Syntax highlighting scripts] [syntax-scripts] located in `~/.vim/syntax` on UNIX, `~\vimfiles\syntax` on Windows;

 * [File-type indentation plug-ins] [indent-scripts] located in `~/.vim/indent` on UNIX, `~\vimfiles\indent` on Windows;

 * [Color scheme scripts] [color-schemes] located in `~/.vim/colors` on UNIX, `~\vimfiles\colors` on Windows.

The directories listed above are Vim's defaults but you're free to change the ['runtimepath'] [rtp] and reloading will still work.

Note that [vimrc scripts] [vimrc] are not reloaded because that seems to cause more trouble than it's worth...

## Install & first use

*Please note that the vim-reload plug-in requires my vim-misc plug-in which is separately distributed.*

Unzip the most recent ZIP archives of the [vim-reload] [download-reload] and [vim-misc] [download-misc] plug-ins inside your Vim profile directory (usually this is `~/.vim` on UNIX and `%USERPROFILE%\vimfiles` on Windows), restart Vim and execute the command `:helptags ~/.vim/doc` (use `:helptags ~\vimfiles\doc` instead on Windows).

If you prefer you can also use [Pathogen] [pathogen], [Vundle] [vundle] or a similar tool to install & update the [vim-reload] [github-reload] and [vim-misc] [github-misc] plug-ins using a local clone of the git repository.

Now try it out: Edit any Vim script that's already loaded (you can check using the [:scriptnames command] [scriptnames]) and confirm that the script is reloaded when you save it (the reload.vim plug-in will print a message to confirm when a script is reloaded).

Out of the box the reload.vim plug-in is configured to automatically reload all Vim scripts that it knows how to. If you like it this way then you don't need to configure anything! However if you don't like the automatic reloading then you can use the option below.

### The `g:reload_on_write` option

If you don't like automatic reloading because it slows Vim down or causes problems you can add the following line to your [vimrc script][vimrc]:

    let g:reload_on_write = 0

This disables automatic reloading which means you'll have to reload scripts using the command discussed below.

### The `:ReloadScript` command

You can execute the `:ReloadScript` command to reload the Vim script you're editing. If you provide a script name as argument to the command then that script will be reloaded instead, e.g.:

    :ReloadScript ~/.vim/plugin/reload.vim

If after executing this command you see Vim errors such as "Function already exists" ([E122] [E122]) or "Command already exists" ([E174] [E174]) then you'll need to change your Vim script(s) slightly to enable reloading, see below.

## Things that prevent reloading

If you want your Vim plug-ins and/or other scripts to be automatically reloaded they'll have to be written a certain way, though you can consider the following points good practice for Vim script writing anyway:

### Use a bang in command and function definitions!

Function and command definitions using Vim's [:command] [command] and [:function] [function] built-ins should include a [bang (!)] [bang] symbol, otherwise Vim will complain that the command or function already exists:

    " Bad:
    :command MyCmd call MyFun()
    :function MyFun()
    :endfunction
    
    " Good:
    :command! MyCmd call MyFun()
    :function! MyFun()
    :endfunction

### Use automatic command groups

Automatic commands using Vim's [:autocmd][autocmd] built-in should be defined inside of an [automatic command group] [augroup] that's cleared so the automatic commands don't stack indefinitely when your [:autocmd][autocmd] commands are executed several times:

    " Bad example: If the following line were re-evaluated, the message would
    " appear multiple times the next time the automatic command fires:
    :autocmd TabEnter * echomsg "Entered tab page"
    
    " Good example: The following three lines can be reloaded without the
    " message appearing multiple times:
    :augroup MyPlugin
    :  autocmd! TabEnter * echomsg "Entered tab page"
    :augroup END

## Alternatives

The [ReloadScript] [reload-script] plug-in on [Vim Online][vim] also supports reloading of Vim scripts, but there are a few notable differences:

 * This plug-in focuses on automatic reloading (I'm lazy) while the other one requires manual reloading;

 * This plug-in will *never* [:source] [source] a file that hasn't already been loaded by Vim -- it checks using Vim's [:scriptnames][scriptnames] command;

 * This plug-in can more or less reload itself ;-)

## Contact

If you have questions, bug reports, suggestions, etc. the author can be contacted at <peter@peterodding.com>. The latest version is available at <http://peterodding.com/code/vim/reload/> and <http://github.com/xolox/vim-reload>. If you like the plug-in please vote for it on [Vim Online] [vim-online].

## License

This software is licensed under the [MIT license] [mit].  
© 2013 Peter Odding &lt;<peter@peterodding.com>&gt;.


[augroup]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#:augroup
[autocmd]: http://vimdoc.sourceforge.net/htmldoc/autocmd.html#:autocmd
[autoload-scripts]: http://vimdoc.sourceforge.net/htmldoc/eval.html#autoload
[bang]: http://vimdoc.sourceforge.net/htmldoc/map.html#:command-bang
[color-schemes]: http://vimdoc.sourceforge.net/htmldoc/syntax.html#:colorscheme
[command]: http://vimdoc.sourceforge.net/htmldoc/map.html#:command
[download-misc]: http://peterodding.com/code/vim/downloads/misc.zip
[download-reload]: http://peterodding.com/code/vim/downloads/reload.zip
[E122]: http://vimdoc.sourceforge.net/htmldoc/eval.html#E122
[E174]: http://vimdoc.sourceforge.net/htmldoc/map.html#E174
[filetype-plugins]: http://vimdoc.sourceforge.net/htmldoc/filetype.html#filetype-plugins
[function]: http://vimdoc.sourceforge.net/htmldoc/eval.html#:function
[github-misc]: http://github.com/xolox/vim-misc
[github-reload]: http://github.com/xolox/vim-reload
[indent-scripts]: http://vimdoc.sourceforge.net/htmldoc/usr_30.html#30.3
[mit]: http://en.wikipedia.org/wiki/MIT_License
[pathogen]: http://www.vim.org/scripts/script.php?script_id=2332
[reload-script]: http://www.vim.org/scripts/script.php?script_id=1904
[rtp]: http://vimdoc.sourceforge.net/htmldoc/options.html#%27runtimepath%27
[scriptnames]: http://vimdoc.sourceforge.net/htmldoc/repeat.html#:scriptnames
[source]: http://vimdoc.sourceforge.net/htmldoc/repeat.html#:source
[standard-plugins]: http://vimdoc.sourceforge.net/htmldoc/usr_05.html#standard-plugin
[syntax-scripts]: http://vimdoc.sourceforge.net/htmldoc/syntax.html#syntax-highlighting
[update]: http://vimdoc.sourceforge.net/htmldoc/editing.html#:update
[vim-online]: http://www.vim.org/scripts/script.php?script_id=3148
[vim]: http://www.vim.org/
[vimrc]: http://vimdoc.sourceforge.net/htmldoc/starting.html#vimrc
[vundle]: https://github.com/gmarik/vundle
