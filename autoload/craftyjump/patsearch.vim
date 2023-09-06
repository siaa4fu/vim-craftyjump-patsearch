vim9script
scriptencoding utf-8

# requires 'siaa4fu/vim-craftyjump'
import autoload 'craftyjump.vim'

# initialize plugkeys
const plugkey = '<Plug>(craftyjump-patsearch)'
execute 'nnoremap' plugkey '<Nop>'
execute 'nnoremap' plugkey .. 'a <Nop>'
execute 'nnoremap' plugkey .. 'i <Nop>'
execute 'nnoremap' plugkey .. '<CR> <ScriptCmd>v:hlsearch = v:hlsearch ? 0 : 1<CR>'

var patsets: dict<list<string>>
export def DefinePatternset(name: string, keys: list<string>, patset: list<string>)
  # @param {string} name - a unique name for a pattern set
  # @param {list<string>} keys - select the pattern set by typing one of the items in the list
  # @param {list<string>} patset - a set of regexp patterns to search for
  #   @param {string} [0] - if [1] is omitted, simply search for matches of [0]
  #   @param {string=} [1] - or, search for matches of pairs that start with [0] and end with [1]
  try
    if has_key(patsets, name)
      throw 'A pattern set is already defined: ' .. name
    endif
    for key in keys
      # turn <> notations into special characters
      const chars = substitute(key, '<[^<>]\+>', (m) => eval('"\' .. m[0] .. '"'), 'g')
      if chars =~# "[\<Esc>\<C-c>]"
        throw '<Esc> and <C-c> cannot be used to select pattern sets.'
      elseif maparg(plugkey .. chars, 'n') !~# '^\%(<Nop>\)\=$'
        # the mapping that searches for another set is already defined
        throw 'The key that selects a pattern set must be unique: ' .. key
      endif
      # define mappings if no error occurs
      patsets[name] = patset
      const lhs = substitute(chars, '\ze\%(\s\||\)', "\<C-v>", 'g')
      execute 'nnoremap' plugkey .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ')<CR>'
      if len(patset) > 1
        execute 'nnoremap' plugkey .. 'a' .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ', ''a'')<CR>'
        execute 'nnoremap' plugkey .. 'i' .. lhs '<ScriptCmd>Patsearch(' .. string(name) .. ', ''i'')<CR>'
      endif
    endfor
  catch
    echoerr substitute(v:exception, '^Vim\%((\a\+)\)\=:', '', '')
  endtry
enddef
def Patsearch(name: string, asBlock = '')
  # @param {string} name - the name of a pattern set to search for
  # @param {string=} asBlock
  #   ''  - separately search for matches of the start and end of the pattern set
  #   'a' - search for matches of 'a' block surrounded by pattern set like text-objects
  #   'i' - search for matches of an 'inner' block surrounded by pattern set like text-objects
  const cnt = v:count
  const patset = patsets[name]
  var pat: string
  if asBlock ==# ''
    pat = '\V\%(' .. join(patset, '\|') .. '\)\+'
  elseif asBlock ==# 'a'
    pat = '\V' .. patset[0] .. '\%(\%(' .. patset[1] .. '\)\@!\.\)\*' .. patset[1]
  elseif asBlock ==# 'i'
    pat = '\V' .. patset[0] .. '\zs\%(\%(' .. patset[1] .. '\)\@!\.\)\*\ze' .. patset[1]
  endif
  craftyjump.SearchPattern(true, pat, cnt)
enddef

var patsetcollections: dict<list<any>>
patsetcollections.bracket = [
  ['parenthesis', ['b', '(', ')'], ['(', ')']],
  ['brace',       ['B', '{', '}'], ['{', '}']],
  ['bracket',     ['r', '[', ']'], ['[', ']']],
  ['angle',       ['a', '<', '>'], ['<', '>']],
]
patsetcollections.symbol = [
  ['space',            ['<Space>', 's'], [' ']],
  ['tab',              ['<Tab>', 't'],   ['\t']],
  ['blank',            ['S', 'T'],       ['\s']],
  ['double-quote',     ['"', 'd'],       ['\["\u201c\u201d]', '\["\u201c\u201d]']],
  ['single-quote',     ["'", 'q'],       ['\[''\u2018\u2019]', '\[''\u2018\u2019]']],
  ['back-quote',       ['`'],            ['`', '`']],
  ['comma',            [',', 'c'],       [',']],
  ['period',           ['.'],            ['.']],
  ['Punctuation',      ['C'],            ['\[,.]']],
  ['leader',           ['l'],            ["\\%(\u2026\\|...\\)"]],
  ['colon',            [':'],            [':']],
  ['semicolon',        [';'],            [';']],
  ['plus',             ['+'],            ['+']],
  ['hyphenminus',      ['-'],            ['\[-\00ad\u2010-\u2015]']],
  ['equal',            ['=', 'e'],       ['=']],
  ['ampersand',        ['&'],            ['&']],
  ['pipe',             ['<Bar>', 'p'],   ['|']],
  ['question-mark',    ['?'],            ['?']],
  ['exclamation-mark', ['!'],            ['!']],
  ['slash',            ['/'],            ['/', '/']],
  ['back-slash',       ['\'],            ['\\']],
  ['caret',            ['^'],            ['^']],
  ['tilde',            ['~'],            ['\[~\u2053]']],
  ['number-sign',      ['#'],            ['#']],
  ['dollar-sign',      ['$'],            ['$']],
  ['percent-sign',     ['%'],            ['\[%\u2030\u2031]']],
  ['at-sign',          ['@'],            ['@']],
  ['asterisk',         ['*'],            ['*']],
  ['underscore',       ['_'],            ['_']],
]
patsetcollections.bracket_ja = [
  ['ja-kakko-maru',         ['jb', 'j(', 'j)'], ["\uff08", "\uff09"]],
  ['ja-kakko-nami',         ['jB', 'j{', 'j}'], ["\uff5b", "\uff5d"]],
  ['ja-kakko-kaku',         ['jr', 'j[', 'j]'], ["\uff3b", "\uff3d"]],
  ['ja-kakko-angle',        ['ja', 'j<', 'j>'], ["\uff1c", "\uff1e"]],
  ['ja-kakko-double-angle', ['jA'],             ["\u226a", "\u226b"]],
  ['ja-kakko-yama',         ['jy'],             ["\u3008", "\u3009"]],
  ['ja-kakko-double-yama',  ['jY'],             ["\u300a", "\u300b"]],
  ['ja-kakko-kagi',         ['jk'],             ["\u300c", "\u300d"]],
  ['ja-kakko-double-kagi',  ['jK'],             ["\u300e", "\u300f"]],
  ['ja-kakko-sumitsuki',    ['js'],             ["\u3010", "\u3011"]],
  ['ja-kakko-kikkou',       ['jt'],             ["\u3014", "\u3015"]],
]
patsetcollections.symbol_ja = [
  ['ja-not-hankaku',  ['zz'],       ['\[^\x01-\x7e]']],
  ['ja-digit',        ['zd'],       ['\[\uff10-\uff19]']],
  ['ja-alphabet',     ['za'],       ['\[\uff21-\uff5a]']],
  ['ja-space',        ['j<Space>'], ['\[\u3000\u2002\u2003\u2009]']],
  ['ja-blank',        ['jS', 'jT'], ['\[\u3000\u2002\u2003\u2009\t]']],
  ['ja-comma',        ['j,', 'jc'], ["\u3001"]],
  ['ja-period',       ['j.'],       ["\u3002"]],
  ['ja-punctuation',  ['jC'],       ['\[\u3001\u3002]']],
  ['ja-leader',       ['jl'],       ['\[\u2025\u2026]']],
  ['ja-double-quote', ['j"', 'jd'], ['\[\uff02\u201c\u201d]', '\[\uff02\u201c\u201d]']],
  ['ja-single-quote', ["j'", 'jq'], ['\[\uff07\u2018\u2019]', '\[\uff07\u2018\u2019]']],
  ['ja-slash',        ['j/'],       ['\[\u2022\u25e6\uff0f\u30fb\uff65]']],
]
export def EnablePatternsetCollection(name: string)
  for arglist in patsetcollections[name]
    call(DefinePatternset, arglist)
  endfor
enddef
