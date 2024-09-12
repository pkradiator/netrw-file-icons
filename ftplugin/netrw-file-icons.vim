" Save as ~/.vim/ftplugin/netrw_icons.vim

if exists('b:netrw_icons_loaded')
  finish
endif
let b:netrw_icons_loaded = 1

autocmd TextChanged <buffer> call s:NetrwAddIcons()

if empty(prop_type_get('netrw_file_icon', {'bufnr': bufnr('%')}))
  call prop_type_add('netrw_file_icon', {
        \ 'bufnr':   bufnr('%'),
        \ 'combine': v:true
        \ })
endif

let s:skip = 'synIDattr(synID(line("."), col("."), 0), "name") !~ "netrwDir\\|netrwExe\\|netrwSymLink\\|netrwPlain"'

function s:NetrwAddIcons() abort
  if !exists('b:netrw_curdir')
    return
  endif

  " Clear out any previous matches
  call prop_remove({'type': 'netrw_file_icon', 'all': v:true})

  let saved_view = winsaveview()
  defer winrestview(saved_view)

  let current_dir = b:netrw_curdir

  " Keep track of nodes we've already annotated:
  let seen = {}

  " Start from the beginning of the file
  normal! gg0

  let pattern = '\f\+'

  if get(b:, 'netrw_liststyle') == 1
    " The timestamps shown at the side should not be iterated, so let's take
    " the list of files to determine what the last column should be:
    let files = readdir(current_dir)
    let max_length = max(map(files, {_, f -> len(f)}))

    let max_col = max_length + 2
    let pattern = '\f\+\%<'..max_col..'c'
  endif

  while search(pattern, 'W', 0, 0, s:skip) > 0
    let pos = getpos('.')
    let node = netrw#GX()
    call setpos('.', pos)

    if node =~ '/$'
      let is_dir = 1
    else
      let is_dir = 0
    endif

    if s:CurrentSyntaxName() == 'netrwSymLink'
      let is_symlink = 1
    else
      let is_symlink = 0
    endif

    if exists('*WebDevIconsGetFileTypeSymbol')
      let symbol = WebDevIconsGetFileTypeSymbol(b:netrw_curdir..'/'..node, is_dir)
    elseif is_symlink
      let symbol = '🔗'
    elseif is_dir
      let symbol = '📁'
    else
      let symbol = '📄'
    endif

    if symbol != ''
      call prop_add(line('.'), col('.'), {
            \ 'type': 'netrw_file_icon',
            \ 'text': symbol..' ',
            \ })
    endif

    " move to the end of the node
    call search('\V'..escape(node, '\'), 'We', line('.'))

    if is_symlink
      " if there's a -->, then the view is long and we can just go to the end
      " of the line
      if search('\s\+-->\s*\f\+', 'Wn', line('.'))
        normal! $
      endif
    endif
  endwhile
endfunction

function! s:CurrentSyntaxName() abort
  return synIDattr(synID(line("."), col("."), 0), "name")
endfunction
