let s:save_cpo = &cpo
set cpo&vim

let g:gql_servers = get(g:, 'gql_servers', {})

function! gql#run()
  if g:gql_servers == {}
    return
  endif
  let bufnum = bufnr('%')
  let input = join(getbufline(bufnum, 1, '$'), "\n") . "\n"
  let query = {'query': input}
  let query = json_encode(query)
  let res = webapi#http#post(g:gql_servers['server'], query, g:gql_servers['headers'])

  let winnum = bufwinnr(bufnr('^gql$'))
  if winnum != -1
    if winnum != bufwinnr('%')
      exe winnum 'wincmd w'
    endif
  else
    exec 'silent noautocmd split gql'
  endif
  setlocal modifiable
  silent %d

  call setline(1, json_encode(json_decode(res.content)))

  setlocal buftype=nofile bufhidden=delete noswapfile
  setlocal nomodified
  setlocal nomodifiable
  nmapclear <buffer>
  nnoremap <silent> <buffer> q :close<cr>
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
