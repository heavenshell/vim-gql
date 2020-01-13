" File: gql.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-gql
" Description: Execute Graphql in vim
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

let g:gql_servers = get(g:, 'gql_servers', [])
let g:gql_formatter = get(g:, '')
let g:gql_delay = get(g:, 'g:gql_delay', 10)

let s:timer = -1
let s:queue = []
let s:win_id = 0
let s:candidates = ['-server']
let s:script_path = expand('<sfile>:p:h:h')

function! s:get_range() abort
  " Get visual mode selection.
  let mode = visualmode(1)
  if mode == 'v' || mode == 'V' || mode == ''
    let start_lnum = line("'<")
    let end_lnum = line("'>")
    return {'start_lnum': start_lnum, 'end_lnum': end_lnum}
  endif

  return {'start_lnum': 1, 'end_lnum': '$'}
endfunction

function! s:parse_options(args) abort
  let servers = deepcopy(g:gql_servers)
  let server = servers[0]

  let i = 0
  let size = len(a:args)
  let variables = {}
  while i < size
    if a:args[i] =~# '-server'
      let host = get(a:args, i + 1, '')
      if host != ''
        let server = filter(servers, {_, v -> v['host'] =~# host})
        if len(server) > 0
          let server = server[0]
        endif
      endif
      let i += 1
      continue
    endif
    if a:args[i] =~# '^$\w\+.='
      let vars = split(a:args[i], '=')
      if len(vars) != 2
        let i += 1
        continue
      endif
      let key = substitute(vars[0], '^\$', '', '')
      let variables[key] = vars[1]
    endif
    let i += 1
  endwhile

  return {'server': server, 'variables': variables}
endfunction

function! s:get_query(start_lnum, end_lnum) abort
  return join(getbufline(bufnr('%'), a:start_lnum, a:end_lnum), "\n") . "\n"
endfunction

function! s:send(timer)
  let opts = remove(s:queue, 0, 0)[0]
  let res = webapi#http#post(opts['host'], opts['query'], opts['headers'])

  let winnum = bufwinnr(bufnr('^Gql$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      execute winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split Gql'
  endif
  setlocal modifiable
  silent %d

  call setline(1, json_encode(json_decode(res.content)))
  let cmd = g:gql_formatter
  if g:gql_formatter == ''
    let cmd = printf('%%!python %s/scripts/format.py', s:script_path)
  endif
  execute cmd

  setlocal buftype=nofile bufhidden=delete noswapfile ft=json
  setlocal nomodified
  setlocal nomodifiable
  nmapclear <buffer>
  nnoremap <silent> <buffer> q :close<cr>
  call win_gotoid(s:win_id)
endfunction

function! gql#complete(lead, cmd, pos) abort
  let lines = split(a:cmd[:a:pos - 1], '', 1)
  if len(lines) >= 2 && lines[-2] =~# '^-'
    let opt = lines[-2][1:]
    if opt ==# 'server'
      let args = map(deepcopy(g:gql_servers), {_, v -> v['host']})
      let ret = filter(args, {_, v -> v =~# '^' . a:lead})
      return ret
    endif
  endif

  if a:lead =~# '^-'
    let args = s:candidates
    let ret = filter(args, {_, v -> v =~# '^' . a:lead})
    return ret
  endif

  let args = []
  let input = s:get_query(1, '$')
  call substitute(input, '\$\w\+', '\=add(args, submatch(0))', 'g')
  call uniq(args)

  let args += s:candidates

  let ret = filter(args, {_, v -> v =~# '^' . a:lead})
  return ret
endfunction

function! gql#run(...)
  if len(g:gql_servers) == 0
    return
  endif

  let args = a:000[0] == '' ? [] : split(a:000[0], '')
  let opts = s:parse_options(args)
  if len(opts['server']) == 0
    return
  endif

  let range = s:get_range()
  let query = {'query': s:get_query(range['start_lnum'], range['end_lnum'])}

  if len(opts['variables']) > 0
    let query['variables'] = opts['variables']
  endif
  let query = json_encode(query)

  if s:timer != -1
    call timer_stop(s:timer)
    let s:timer = -1
  endif

  let s:queue = []
  call add(s:queue, {
    \ 'query': query,
    \ 'host': opts['server']['host'],
    \ 'headers': opts['server']['headers'],
    \ })
  let s:win_id = win_getid()

  let s:timer = timer_start(
    \ g:gql_delay,
    \ function('s:send')
    \ )
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
