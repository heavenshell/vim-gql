" File: gql.vim
" Author: Shinya Ohyanagi <sohyanagi@gmail.com>
" WebPage: http://github.com/heavenshell/vim-gql
" Description: Execute Graphql in vim
" License: BSD, see LICENSE for more details.
let s:save_cpo = &cpo
set cpo&vim

command! -nargs=* -range=0 -complete=customlist,gql#complete Gql :call gql#run(<q-args>, <count>, <line1>, <line2>)

let &cpo = s:save_cpo
unlet s:save_cpo
