let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -range=0 Gql
  \ call gql#run()

let &cpo = s:save_cpo
unlet s:save_cpo
