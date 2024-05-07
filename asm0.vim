" Vim syntax file
" Language: asm0
" Maintainer: Zikun Zhou
" Latest Revision: 07 April 2024

if exists("b:current_syntax")
  finish
endif

syn keyword asm0Label data enddata text endtext
syn keyword asm0Type byte endbyte 
syn keyword asm0Number inum 
syn keyword asm0Macro macro 
syn keyword asm0Proc begin end 
syn keyword asm0Operator alu src dst jmp 
syn match asm0CommentL "^ \=\*.*$" contains=@Spell
syn match asm0CommentL "\$.*$" contains=@Spell
syn match asm0Number "\<[0-9]\+\.[0-9]*\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="
syn match asm0Number "\.[0-9]\+\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="
syn match asm0Number "\<[0-9]\+\(e[-+]\=[0-9]\+\)\=\(meg\=\|[afpnumkg]\)\="

syn region asm0String start='"' end='"' contained


let b:current_syntax = "asm0"

hi def link asm0Label       Label
hi def link asm0Proc        PreProc
hi def link asm0Macro       Macro
hi def link asm0CommentL	Comment
hi def link asm0Type        Type
hi def link asm0String      String 
hi def link asm0Number      Number
hi def link asm0Operator    Operator
