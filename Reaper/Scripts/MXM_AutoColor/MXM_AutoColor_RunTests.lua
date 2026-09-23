--[[
  MXM_AutoColor_RunTests.lua -- assertions for the matching layer.

  Runs either inside REAPER (results go to the ReaScript console) or standalone
  from a terminal (`lua MXM_AutoColor_RunTests.lua`), which is much faster to
  iterate on. Nothing here touches project state.
]]

local IN_REAPER = (type(reaper) == 'table' and reaper.ShowConsoleMsg ~= nil)

local ROOT
if IN_REAPER then
  local _, thisFile = reaper.get_action_context()
  ROOT = thisFile:match('^(.*[\\/])')
else
  ROOT = (arg and arg[0] or ''):match('^(.*[/\\])') or './'
end
package.path = ROOT .. '?.lua;' .. ROOT .. 'lib/?.lua;' .. package.path

local R = require 'regex'

------------------------------------------------------------------- harness
local pass, fail, failures = 0, 0, {}

local function out(s)
  if IN_REAPER then reaper.ShowConsoleMsg(s) else io.write(s) end
end

local function check(ok, label, detail)
  if ok then
    pass = pass + 1
  else
    fail = fail + 1
    failures[#failures + 1] = label .. (detail and ('  -- ' .. detail) or '')
  end
end

-- Match and return the matched text, or a sentinel describing what happened.
local function m(pat, subj, opts)
  local c, err, pos = R.compile(pat, opts)
  if not c then return '<compile:' .. err .. '@' .. tostring(pos) .. '>' end
  local a, b, caps = c:find(subj)
  if a == nil then
    if b == 'budget' then return '<budget>' end
    return nil
  end
  return subj:sub(a, b), caps
end

local function eq(pat, subj, expect, opts)
  local got = m(pat, subj, opts)
  check(got == expect, string.format('/%s/ on %q', pat, subj),
        string.format('expected %s, got %s', tostring(expect), tostring(got)))
end

local function caps_eq(pat, subj, expect, opts)
  local _, caps = m(pat, subj, opts)
  caps = caps or {}
  local okAll = #expect == #caps
  if okAll then
    for i = 1, #expect do
      if caps[i] ~= expect[i] then okAll = false break end
    end
  end
  local function show(t)
    local parts = {}
    for i = 1, #t do parts[i] = tostring(t[i]) end
    return '{' .. table.concat(parts, ',') .. '}'
  end
  check(okAll, string.format('captures /%s/ on %q', pat, subj),
        'expected ' .. show(expect) .. ', got ' .. show(caps))
end

local function bad(pat, why)
  local c, err = R.compile(pat)
  check(c == nil, 'should reject /' .. pat .. '/ (' .. (why or '') .. ')',
        c and 'compiled anyway' or nil)
  if c == nil then
    check(type(err) == 'string' and #err > 0, 'error message for /' .. pat .. '/')
  end
end

---------------------------------------------------------------- literals
eq('bass',  'Bass Guitar', nil)
eq('bass',  'sub bass DI', 'bass')
eq('bass',  'Bass Guitar', 'Bass', { ci = true })
eq('BASS',  'sub bass DI', 'bass', { ci = true })
eq('(?i)bass', 'Bass Guitar', 'Bass')
eq('',      'anything',     '')

---------------------------------------------------------------- anchors
eq('^Kick',  'Kick In',      'Kick')
eq('^Kick',  'The Kick In',  nil)
eq('In$',    'Kick In',      'In')
eq('In$',    'Kick Inside',  nil)
eq('^$',     '',             '')
eq('^$',     'x',            nil)
eq('^Gtr$',  'Gtr',          'Gtr')

---------------------------------------------------------------- dot
eq('a.c',    'abc',   'abc')
eq('a.c',    'a\nc',  nil)      -- . does not cross a newline
eq('^.$',    'e',     'e')
eq('^.{3}$', 'abc',   'abc')
eq('^.{3}$', 'Kyt',   'Kyt')
-- one multi-byte character counts as one
eq('^.$',    'e\204\129', 'e\204\129' == 'e\204\129' and nil or nil)  -- combining: two sequences
eq('^.$',    '\195\169', '\195\169')             -- U+00E9
eq('^.$',    '\208\145', '\208\145')             -- U+0411
eq('^.$',    '\226\130\172', '\226\130\172')     -- U+20AC
eq('^.$',    '\240\159\165\129', '\240\159\165\129') -- U+1F941

---------------------------------------------------------------- classes
eq('[abc]+',   'xxcabyy',  'cab')
eq('[^abc]+',  'abXYZab',  'XYZ')
eq('[a-z]+',   'ABCdefGH', 'def')
eq('[a-z]+',   'ABCdefGH', 'ABCdefGH', { ci = true })
eq('[0-9]+',   'gtr12',    '12')
eq('[]]',      ']',        ']')        -- ] first in class is literal
eq('[a%-z]',   '%',        '%')        -- % is not special here
eq('[-a]+',    '-a',       '-a')       -- leading - is literal
eq('[a-]+',    'a-',       'a-')       -- trailing - is literal
eq('[\\]]',    ']',        ']')
eq('[\\d]+',   'ab12',     '12')
eq('[\\w]+',   ' ab_1 ',   'ab_1')
bad('[z-a]', 'reversed range')
bad('[abc',  'unterminated class')

---------------------------------------------------------------- class escapes
eq('\\d+',   'gtr12dry', '12')
eq('\\D+',   '12ab34',   'ab')
eq('\\w+',   ' _a1 ',    '_a1')
eq('\\W+',   'ab  cd',   '  ')
eq('\\s+',   'a \t b',   ' \t ')
eq('\\S+',   '  abc  ',  'abc')
-- non-ASCII bytes count as word characters
eq('^\\w+$', 'Kytara_hlavn\195\173', 'Kytara_hlavn\195\173')

---------------------------------------------------------------- word boundaries
eq('\\bbass\\b',  'sub bass DI',  'bass')
eq('\\bbass\\b',  'bassoon solo', nil)
eq('\\bbass',     'bassoon solo', 'bass')
eq('\\bKick\\b',  'Kick',         'Kick')   -- both boundaries at string edges
eq('\\Bass',      'bassoon',      'ass')
eq('\\bx\\b',     'x',            'x')
eq('\\b',         '',             nil)      -- no boundary in an empty string

---------------------------------------------------------------- alternation
eq('^(kick|snare|hh)',  'snare top',  'snare')
eq('^(kick|snare|hh)',  'hh closed',  'hh')
eq('^(kick|snare|hh)',  'tom 1',      nil)
eq('cat|catalog',       'catalog',    'cat')   -- leftmost-first, not longest
eq('a(b|)c',            'ac',         'ac')    -- empty branch
eq('^(a|b)+$',          'abab',       'abab')
caps_eq('^(kick|snare)_(\\d+)$', 'snare_12', { 'snare', '12' })

---------------------------------------------------------------- quantifiers
eq('ab*',     'a',        'a')
eq('ab*',     'abbb',     'abbb')
eq('ab+',     'a',        nil)
eq('ab+',     'abbb',     'abbb')
eq('ab?',     'a',        'a')
eq('ab?',     'ab',       'ab')
eq('a.*b',    'axxbxxb',  'axxbxxb')   -- greedy
eq('a.*?b',   'axxbxxb',  'axxb')      -- lazy
eq('a.+?b',   'axxbxxb',  'axxb')
eq('^a??b',   'ab',       'ab')
eq('<.+?>',   '<a><b>',   '<a>')
eq('<.+>',    '<a><b>',   '<a><b>')

---------------------------------------------------------------- bounded repeats
eq('^a{3}$',    'aaa',    'aaa')
eq('^a{3}$',    'aa',     nil)
eq('^a{2,4}$',  'aa',     'aa')
eq('^a{2,4}$',  'aaaa',   'aaaa')
eq('^a{2,4}$',  'a',      nil)
eq('^a{2,4}$',  'aaaaa',  nil)
eq('^a{2,}$',   'aaaaa',  'aaaaa')
eq('^a{0,2}$',  '',       '')
eq('a{2,4}',    'aaaaa',  'aaaa')     -- greedy within bounds
eq('a{2,4}?',   'aaaaa',  'aa')       -- lazy within bounds
eq('^\\d{2}_',  '01_Kick', '01_')
bad('a{3,1}', 'm < n')
bad('a{300}', 'bound too large')
-- a bare { that is not a quantifier is a literal
eq('a{b',  'a{b',  'a{b')
eq('x{b}', 'x{b}', 'x{b}')
-- but a real quantifier applied to an anchor is an error, as in PCRE/Python
bad('^{2}$', 'quantified anchor')

---------------------------------------------------------------- groups & captures
caps_eq('(a)(b)(c)',      'abc',      { 'a', 'b', 'c' })
caps_eq('(a(b(c)))',      'abc',      { 'abc', 'bc', 'c' })
caps_eq('(?:ab)(c)',      'abc',      { 'c' })
caps_eq('(x)?y',          'y',        { false })
caps_eq('(x)?y',          'xy',       { 'x' })
caps_eq('^(\\d+)_',       '01_Kick',  { '01' })
caps_eq('^(\\w+?)_(\\w+)$', 'a_b_c',  { 'a', 'b_c' })
-- captures must be restored correctly when the engine backtracks
caps_eq('^(?:(a)|b)+$',   'ab',       { 'a' })
caps_eq('(a+)(a+)',       'aaa',      { 'aa', 'a' })
bad('(ab',   'missing )')
bad('ab)',   'unmatched )')

---------------------------------------------------------------- case folding
eq('[a-z]+',     'ABC',    'ABC',  { ci = true })
eq('[A-Z]+',     'abc',    'abc',  { ci = true })
eq('[^a-z]+',    'ABC',    nil,    { ci = true })   -- negation folds too
eq('gtr\\d',     'GTR7',   'GTR7', { ci = true })
eq('^(?i)x', 'X', '<compile:(?i) is only allowed at the very start of the pattern@2>')

---------------------------------------------------------------- escapes
eq('a\\.c',    'a.c',   'a.c')
eq('a\\.c',    'abc',   nil)
eq('\\$\\^',   '$^',    '$^')
eq('\\x41+',   'xAAy',  'AA')
eq('a\\tb',    'a\tb',  'a\tb')
eq('\\\\',     'a\\b',  '\\')
bad('\\q',  'unknown escape')
bad('a\\',  'trailing backslash')
bad('(?=a)', 'lookaround')
bad('(a)\\1', 'backreference')

---------------------------------------------------------------- anchor repeat
bad('^*',   'nothing to repeat')
bad('*a',   'nothing to repeat')
bad('+a',   'nothing to repeat')
bad('a**',  'nested quantifier')

------------------------------------------------- zero-width loop termination
-- These must terminate (the PROGRESS guard), not spin.
eq('^(a*)*$',   'aaa',  'aaa')
eq('^(a*)*$',   '',     '')
eq('^(|x)*$',   '',     '')
eq('^(a?)+$',   '',     '')
eq('^()*$',     '',     '')

------------------------------------------------- catastrophic backtracking
-- Each of these would hang a naive backtracker. They must come back as
-- '<budget>' (or an honest non-match) in bounded time -- never hang REAPER.
local SUBJ40 = string.rep('a', 40) .. '!'
local function bounded(pat, subj, label)
  local t0 = os.clock()
  local got = m(pat, subj)
  local dt = os.clock() - t0
  check(got == '<budget>' or got == nil, label,
        'got ' .. tostring(got))
  check(dt < 0.5, label .. ' finishes fast', string.format('took %.3fs', dt))
end
bounded('^(a+)+$',   SUBJ40, 'catastrophic (a+)+$')
bounded('^(a|a)*$',  SUBJ40, 'catastrophic (a|a)*$')
bounded('^(a*)*b',   SUBJ40, 'catastrophic (a*)*b')
bounded('^(a|aa)+$', SUBJ40, 'catastrophic (a|aa)+$')

-- The compile-time program cap must reject the classic expansion bomb.
bad('(a{200}){200}', 'program size cap')

---------------------------------------------------------------- prefilter
-- The prefilter must never change the answer, only the speed.
eq('gtr\\d+',    'my gtr12 dry',  'gtr12')
eq('gtr\\d+',    'my GTR12 dry',  nil)
eq('gtr\\d+',    'my GTR12 dry',  'GTR12', { ci = true })
eq('^bass',      'bass',          'bass')
eq('x(abc)y',    'zzxabcyzz',     'xabcy')

---------------------------------------------------------------- realistic
eq('^\\d{2}[_ -]',            '01_Kick In',   '01_')
eq('(?i)^(gtr|gui?tar)\\b',   'Guitar DI',    'Guitar')
eq('(?i)^(gtr|gui?tar)\\b',   'Gtr L',        'Gtr')
eq('(?i)\\b(vox|vocal)s?\\b', 'Lead Vocals',  'Vocals')
eq('(?i)\\bbass\\b',          'Bassoon',      nil)
eq('(?i)\\bbass\\b',          'Sub Bass',     'Bass')
eq('_(dry|wet)$',             'gtr_dry',      '_dry')
eq('^FX\\s*\\d*$',            'FX 3',         'FX 3')


--=========================================================== matcher / modes
local MT = require 'matcher'

local function mt(mode, pat, subj, ci)
  local m, err = MT.compile(mode, pat, ci)
  if not m then return '<compile:' .. tostring(err) .. '>' end
  return m:test(subj) and true or false
end

local function mteq(mode, pat, subj, expect, ci)
  local got = mt(mode, pat, subj, ci)
  check(got == expect,
        string.format('%s /%s/ on %q%s', mode, pat, subj, ci and ' (ci)' or ''),
        string.format('expected %s, got %s', tostring(expect), tostring(got)))
end

-- substring: never interprets anything
mteq('substring', 'bass',  'Sub Bass DI', false)
mteq('substring', 'bass',  'sub bass di', true)
mteq('substring', 'bass',  'Sub Bass DI', true,  true)
mteq('substring', 'a.c',   'abc',        false)          -- '.' is literal
mteq('substring', 'a.c',   'xa.cx',      true)
mteq('substring', '*',     'a*b',        true)           -- '*' is literal
mteq('substring', '[a]',   'x[a]x',      true)
mteq('substring', '',      'anything',   true)

-- glob: implicitly anchored, so it matches the WHOLE name
mteq('glob', 'bass',    'sub bass',    false)
mteq('glob', 'bass',    'bass',        true)
mteq('glob', '*bass*',  'sub bass di', true)
mteq('glob', '*bass*',  'Sub Bass DI', false)
mteq('glob', '*bass*',  'Sub Bass DI', true,  true)
mteq('glob', 'Gtr_?',   'Gtr_L',       true)
mteq('glob', 'Gtr_?',   'Gtr_LR',      false)
mteq('glob', '[Bb]ass*', 'Bass Gtr',   true)
mteq('glob', '[Bb]ass*', 'bass',       true)
mteq('glob', '[Bb]ass*', 'Sass',       false)
mteq('glob', '[!ab]*',  'cat',         true)
mteq('glob', '[!ab]*',  'about',       false)
mteq('glob', '*.wav',   'kick.wav',    true)
mteq('glob', '*.wav',   'kickXwav',    false)            -- '.' escaped
mteq('glob', '*',       '',            true)
mteq('glob', '*',       'anything',    true)
mteq('glob', 'a+b',     'a+b',         true)             -- regex metachars escaped
mteq('glob', 'a+b',     'aab',         false)
mteq('glob', 'x[',      'x[',          true)             -- unterminated class is literal

-- regex mode is the engine, unchanged
mteq('regex', '^(kick|snare)$', 'snare', true)
mteq('regex', '^(kick|snare)$', 'snares', false)
mteq('regex', 'bass',           'BASS',  true, true)

check(MT.compile('nonsense', 'x') == nil, 'unknown mode rejected')

-- a bad pattern reports an error and then simply never matches
local badm, baderr, badpos = MT.compile('regex', '(a')
check(badm == nil, 'bad regex does not compile')
check(type(baderr) == 'string' and type(badpos) == 'number', 'bad regex reports msg+pos')

-- the cache must hand back the identical object
check(MT.compile('regex', '^a') == MT.compile('regex', '^a'), 'matcher cache reuses')
check(MT.compile('regex', '^a', true) ~= MT.compile('regex', '^a', false),
      'matcher cache keys on ci')

-- prepare() / test() over rule records
local rules = {
  { mode = 'regex',     pattern = '^kick', ci = true },
  { mode = 'substring', pattern = 'bass',  ci = false },
  { mode = 'regex',     pattern = '(',     ci = false },   -- deliberately broken
  { mode = 'regex',     pattern = '',      ci = false },   -- predicate-only rule
}
local nbad = MT.prepare(rules)
check(nbad == 1, 'prepare counts broken rules', 'got ' .. nbad)
check(rules[3]._err ~= nil, 'broken rule keeps its error message')
check(MT.test(rules[1], 'Kick In') == true,  'prepared regex rule matches')
check(MT.test(rules[2], 'sub bass') == true, 'prepared substring rule matches')
check(MT.test(rules[3], 'anything') == false, 'broken rule never matches')
check(MT.test(rules[4], 'anything') == true,  'empty pattern matches any name')

-- The result memo. It is keyed by name alone, so the thing that can go wrong is
-- an edited rule still answering from the old pattern's cache.
do
  local r = { mode = 'substring', pattern = 'bass', ci = false }
  MT.prepare({ r })
  check(MT.test(r, 'sub bass') == true,  'memo: first answer')
  check(MT.test(r, 'sub bass') == true,  'memo: same answer on the second ask')
  check(MT.test(r, 'guitar')   == false, 'memo: a miss is remembered as a miss')
  check(r._memon == 2, 'memo holds one entry per distinct name', tostring(r._memon))

  -- prepare() alone must NOT throw the memo away: it runs on every sweep, which
  -- is precisely when the memo has to survive to be worth anything.
  MT.prepare({ r })
  check(r._memo ~= nil and r._memon == 2, 'an ordinary sweep keeps the memo')

  -- ...but an edited pattern must, or the rule answers from the old one.
  r.pattern = 'guitar'
  MT.prepare({ r })
  check(r._memo == nil, 'editing the pattern drops the memo')
  check(MT.test(r, 'sub bass') == false, 'and the new pattern is what answers')
  check(MT.test(r, 'guitar')   == true,  'both ways round')

  -- clear_cache() is what every rule change goes through, so it must invalidate
  -- too -- it recompiles, and the memo is only valid for one compiled matcher.
  MT.prepare({ r })
  local filled = r._memon
  MT.clear_cache()
  MT.prepare({ r })
  check(filled > 0 and r._memo == nil, 'clear_cache drops the memo as well')

  -- a pattern that gives up on the step budget must stay reported as such,
  -- rather than being remembered as a plain no-match
  local slow = { mode = 'regex', pattern = '(a+)+$', ci = false }
  MT.prepare({ slow })
  local hit1, why1 = MT.test(slow, string.rep('a', 40) .. 'b')
  local hit2, why2 = MT.test(slow, string.rep('a', 40) .. 'b')
  check(hit1 == false and why1 == 'budget', 'budget is reported')
  check(hit2 == false and why2 == 'budget', 'and survives the memo', tostring(why2))
end

--=============================================================== predicates
local PR = require 'predicates'

local function pr(only, kind, info) return PR.test(only, kind, info) end

check(pr(nil, 'track', {}) == true, 'nil predicate always passes')
check(pr('folder',   'track', { folderdepth = 1 }) == true,  'folder: parent')
check(pr('folder',   'track', { folderdepth = 0 }) == false, 'folder: plain track')
check(pr('folder',   'track', { folderdepth = -1 }) == false, 'folder: last child')
check(pr('children', 'track', { depth = 1 }) == true,  'children: inside a folder')
check(pr('children', 'track', { depth = 0 }) == false, 'children: top level')
check(pr('unnamed',  'track', { name = '' }) == true,   'unnamed: empty')
check(pr('unnamed',  'track', { name = 'x' }) == false, 'unnamed: named')
check(pr('unnamed',  'item',  { name = '' }) == true,   'unnamed works on items')
check(pr('unnamed',  'region', { name = '' }) == true,  'unnamed works on regions')
-- track-only predicates must not silently pass for other kinds
check(pr('folder',   'item',  { folderdepth = 1 }) == false, 'folder is track-only')
check(pr('children', 'region', { depth = 5 }) == false, 'children is track-only')

check(PR.applies('folder', 'track') == true,  'applies: folder/track')
check(PR.applies('folder', 'item')  == false, 'applies: folder/item')
check(PR.applies('unnamed', 'item') == true,  'applies: unnamed/item')
check(PR.applies(nil, 'item')       == true,  'applies: nil/anything')
check(PR.valid('master') == false, 'valid: the removed master filter')
check(PR.valid('folder') == true,  'valid: known')
check(PR.valid(nil)      == true,  'valid: nil')
check(PR.valid('nope')   == false, 'valid: unknown')


--=============================================================== colors
-- Outside REAPER, stand in for the two native-colour calls. The stub models
-- macOS byte order; correctness on Windows comes from always routing through
-- these two functions rather than assuming a layout.
if not IN_REAPER then
  _G.reaper = _G.reaper or {}
  reaper.ColorToNative   = function(r, g, b) return (r << 16) | (g << 8) | b end
  reaper.ColorFromNative = function(v) return (v >> 16) & 0xFF, (v >> 8) & 0xFF, v & 0xFF end
end

local CO = require 'colors'

check(CO.pack(255, 128, 0) == 0xFF8000, 'pack')
do
  local r, g, b = CO.split(0xFF8000)
  check(r == 255 and g == 128 and b == 0, 'split')
end
check(CO.pack(CO.split(0x123456)) == 0x123456, 'pack/split round trip')

-- I_CUSTOMCOLOR can come back negative; norm must make both sides comparable
check(CO.norm(0) == 0, 'norm zero')
check(CO.norm(0x1FF8000) == 0x1FF8000, 'norm passthrough')
check(CO.norm(-16744448) == CO.norm(-16744448 + 0x100000000), 'norm negative')
check(CO.norm(0x7F000000 | 0x1123456) & CO.ENABLE ~= 0, 'norm keeps enable bit')

check(CO.to_native(0xFF8000) & CO.ENABLE ~= 0, 'to_native sets the enable bit')
check(CO.from_native(CO.to_native(0x123456)) == 0x123456, 'native round trip')
check(CO.from_native(0) == nil, 'from_native 0 means no colour, not black')
check(CO.from_native(CO.ENABLE) == 0x000000, 'enable bit alone is black')

-- HSL round trip across a spread of colours
for _, c in ipairs({ 0x000000, 0xFFFFFF, 0x808080, 0xFF0000, 0x00FF00, 0x0000FF,
                     0xC44A3B, 0x3B7FC4, 0x7FC43B, 0x123456, 0xFEDCBA }) do
  local back = CO.hsl_to_rgb(CO.rgb_to_hsl(c))
  local dr = math.abs(((back >> 16) & 0xFF) - ((c >> 16) & 0xFF))
  local dg = math.abs(((back >> 8) & 0xFF) - ((c >> 8) & 0xFF))
  local db = math.abs((back & 0xFF) - (c & 0xFF))
  check(dr <= 1 and dg <= 1 and db <= 1, 'hsl round trip ' .. CO.tohex(c),
        'got ' .. CO.tohex(back))
end

check(CO.lerp(0xFF0000, 0x00FF00, 0) == 0xFF0000, 'lerp at t=0')
check(CO.lerp(0xFF0000, 0x00FF00, 1) == 0x00FF00, 'lerp at t=1')
check(CO.gradient(0xFF0000, nil, 3, 5) == 0xFF0000, 'gradient without a second colour')
check(CO.gradient(0xFF0000, 0x00FF00, 1, 1) == 0xFF0000, 'gradient of one is the first colour')
check(CO.gradient(0xFF0000, 0x00FF00, 1, 4) == 0xFF0000, 'gradient starts at colour 1')
check(CO.gradient(0xFF0000, 0x00FF00, 4, 4) == 0x00FF00, 'gradient ends at colour 2')
do
  -- a 5-step gradient must produce 5 distinct colours
  local seen, n = {}, 0
  for i = 1, 5 do
    local c = CO.gradient(0xC44A3B, 0x3B7FC4, i, 5)
    if not seen[c] then seen[c] = true; n = n + 1 end
  end
  check(n == 5, 'gradient yields distinct steps', 'got ' .. n)
end
do
  -- hue takes the SHORT way round: red -> magenta must not detour via green
  local mid = CO.lerp(0xFF0000, 0xFF00FF, 0.5)
  local r, g, b = CO.split(mid)
  check(g < 64 and r > 128 and b > 64, 'lerp takes the short hue path',
        'got ' .. CO.tohex(mid))
end
do
  -- fading to grey must not swing through an unrelated hue
  local mid = CO.lerp(0xC44A3B, 0x808080, 0.5)
  local r, g, b = CO.split(mid)
  check(r >= g and g >= b, 'lerp to grey keeps the hue', 'got ' .. CO.tohex(mid))
end

check(CO.tohex(0xFF8000) == '#FF8000', 'tohex')
check(CO.fromhex('#FF8000') == 0xFF8000, 'fromhex with hash')
check(CO.fromhex('ff8000') == 0xFF8000, 'fromhex without hash')
check(CO.fromhex('nope') == nil, 'fromhex rejects junk')


--==================================================================== json
local J = require 'json'

local function roundtrip(v, label)
  local enc, eerr = J.encode(v)
  check(enc ~= nil, 'encode ' .. label, tostring(eerr))
  if not enc then return end
  check(not enc:find('\n'), 'encode ' .. label .. ' stays on one line')
  local dec, derr = J.decode(enc)
  check(dec ~= nil, 'decode ' .. label, tostring(derr))
  return enc, dec
end

roundtrip({ a = 1, b = 'two', c = true, d = { 1, 2, 3 } }, 'nested')
roundtrip({ 1, 2, 3 }, 'array')
roundtrip({}, 'empty table')

do
  local _, dec = roundtrip({ s = 'quote" back\\ nl\n tab\t ctrl\1' }, 'nasty string')
  check(dec and dec.s == 'quote" back\\ nl\n tab\t ctrl\1', 'string survives escaping')
end
do
  -- names contain non-ASCII; it must pass through as UTF-8, not get mangled
  local _, dec = roundtrip({ n = 'Kytara_hlavn\195\173' }, 'utf8 name')
  check(dec and dec.n == 'Kytara_hlavn\195\173', 'utf8 passes through')
end
do
  local enc = J.encode({ z = 1, a = 2, m = 3 })
  check(enc == '{"a":2,"m":3,"z":1}', 'object keys are sorted', enc)
  check(J.encode({ z = 1, a = 2, m = 3 }) == enc, 'encoding is stable across calls')
end
do
  local enc = J.encode({ i = 7, f = 1.5 })
  check(enc:find('"i":7', 1, true) ~= nil, 'integers encode without a decimal point', enc)
  check(enc:find('"f":1.5', 1, true) ~= nil, 'floats keep their fraction', enc)
end
check(J.decode('{"a":1} junk') == nil, 'decode rejects trailing content')
check(J.decode('{"a":}') == nil, 'decode rejects a missing value')
check(J.decode('"unterminated') == nil, 'decode rejects an unterminated string')
check(J.decode('[1,2') == nil, 'decode rejects an unterminated array')
check(J.decode('nonsense') == nil, 'decode rejects junk')
check(select(2, J.decode('{"a":}')) ~= nil, 'decode returns a message')
do
  local cyc = {}; cyc.self = cyc
  check(J.encode(cyc) == nil, 'encode refuses a cycle')
end

--=================================================================== rules
local RU = require 'rules'

do
  local r = RU.new('track', {})
  check(r.id ~= nil and r.id ~= '', 'new rule gets an id')
  check(r.kind == 'track',     'new rule remembers its kind')
  check(r.enabled == true,     'new rule is enabled')
  check(r.ci == true,          'new rule is case-insensitive by default')
  check(r.mode == 'substring', 'new rule defaults to substring')
  check(r.cascade_items == false, 'a track rule has a cascade switch, off by default')
  check(r.targets == nil,      'the v1 targets field is gone')
end
do
  local r = RU.new('region', {})
  check(r.kind == 'region', 'a region rule knows its kind')
  check(r.cascade_items == nil, 'only track rules carry the cascade switch')
end
check(RU.newid() ~= RU.newid(), 'ids are unique')

do -- garbage in, sane rule out
  local r = RU.normalize({ mode = 'nope', pattern = 42, color = -5, ci = 'yes',
                           only = 'bogus' }, 'track')
  check(r.mode == 'substring', 'bad mode falls back')
  check(r.pattern == '',       'non-string pattern falls back')
  check(r.color == 0x808080,   'negative colour falls back')
  check(r.only == nil,         'unknown filter is dropped')
end
check(RU.normalize({ color = 0x1FF8000 }, 'track').color == 0xFF8000,
      'colour is masked to 24 bits')
check(RU.normalize({ kind = 'nonsense' }, 'nonsense').kind == 'track',
      'an unknown kind falls back to track')

-- a filter that cannot apply to the kind is dropped, not left never matching
check(RU.normalize({ only = 'folder' }, 'track').only == 'folder',
      'a track keeps the folder filter')
check(RU.normalize({ only = 'folder' }, 'region').only == nil,
      'a region drops the folder filter')
check(RU.normalize({ only = 'unnamed' }, 'region').only == 'unnamed',
      'a region keeps the unnamed filter')

do
  local w = RU.warnings(RU.normalize({ pattern = '', only = nil }, 'track'))
  check(#w > 0, 'warns about a rule that matches everything')
  local w2 = RU.warnings(RU.normalize({ pattern = 'x', only = 'unnamed' }, 'track'))
  check(#w2 > 0, 'warns about a pattern combined with the unnamed filter')
end

-- the removed 'master' filter must DISABLE a rule, not widen it to match all
do
  local legacy = RU.normalize({ id = 'r_legacy', only = 'master', pattern = '',
                                enabled = true }, 'track')
  check(legacy.only == nil,      'the legacy master filter is dropped')
  check(legacy.enabled == false, 'and the rule is DISABLED, not left matching everything')
  check(legacy.note:find('master') ~= nil, 'and the reason is recorded in its note')
end

--================================================================== config
local CF = require 'config'

do
  local d = CF.defaults()
  check(d.version == CF.VERSION, 'defaults carry the current version')
  check(d.options.propagate_folders == 'fill_unmatched', 'default folder policy')
  check(d.options.subfolder_splits_range == true,
        'subfolders split the parent range by default')
  for _, k in ipairs(RU.KINDS) do
    check(type(d.rules[k]) == 'table' and #d.rules[k] == 0,
          'defaults have an empty ' .. k .. ' list')
  end
  check(d.options.match_master == nil, 'the master option is gone')
end

do -- option coercion
  local c = CF.normalize{ options = { propagate_folders = 'bogus', tick_interval = 99,
                                      font_size = -3, clear_unmatched = 'yes' } }
  check(c.options.propagate_folders == 'fill_unmatched', 'bad enum falls back')
  check(c.options.tick_interval == 2.0, 'tick interval clamps to max')
  check(c.options.font_size == 8, 'font size clamps to min')
  check(CF.normalize{ options = { font_size = 99 } }.options.font_size == 20,
        'and to max, so a config written before the cap is brought down')
  check(c.options.clear_unmatched.track == false, 'non-boolean coerces to false per kind')
  check(type(c.options.clear_unmatched) == 'table', 'clear_unmatched is a per-kind table')
end

do -- a boolean that defaults TRUE must survive a config written before it existed
  local old = CF.normalize{ options = { propagate_folders = 'off' } }
  check(old.options.subfolder_splits_range == true,
        'a missing boolean takes its DEFAULT, not false')
  check(old.options.auto_undo == false, 'and a default-false boolean is unchanged')
  check(CF.normalize{ options = { subfolder_splits_range = false } }
          .options.subfolder_splits_range == false, 'an explicit false is kept')
  check(CF.normalize{ options = { subfolder_splits_range = 'yes' } }
          .options.subfolder_splits_range == true, 'junk falls back to the default')
end

do -- ids must be unique ACROSS kinds; they key GUI widgets and the undo stack
  local c = CF.normalize{ rules = { track = { { id = 'dup' } }, item = { { id = 'dup' } } } }
  check(c.rules.track[1].id ~= c.rules.item[1].id,
        'a duplicate id across two kinds is reassigned')
end

do -- EVERY starter pattern must compile; shipping a broken one would be bad
  local starter = CF.starter()
  local total = 0
  for _, k in ipairs(RU.KINDS) do
    total = total + #starter.rules[k]
    local bad = MT.prepare(starter.rules[k])
    check(bad == 0, 'every starter ' .. k .. ' rule compiles', bad .. ' failed')
  end
  check(total > 0, 'starter set is not empty')
  check(#starter.rules.region > 0, 'the starter set includes region rules')
  check(#starter.rules.marker > 0, 'the starter set includes marker rules')
end

--------------------------------------------------- v1 -> v2 migration
-- v1 kept one list with track/item/region/marker checkboxes. A rule that
-- ticked several must become one rule per kind, keeping its relative order --
-- and must NOT end up sharing an id with its own copies.
do
  local v1 = {
    version = 1,
    options = { propagate_folders = 'force', match_master = true },
    rules = {
      { id = 'a', label = 'Both',   pattern = 'x', color = 0x111111,
        targets = { track = true, item = true } },
      { id = 'b', label = 'Region', pattern = 'y', color = 0x222222,
        targets = { region = true } },
      { id = 'c', label = 'First',  pattern = 'z', color = 0x333333,
        targets = { track = true } },
    },
  }
  -- round-trip through JSON first, exactly as loading a real file would
  local migrated = CF.normalize(CF.migrate(J.decode(J.encode(v1))))

  check(#migrated.rules.track == 2, 'both track-targeting rules land on the track tab',
        #migrated.rules.track .. ' found')
  check(migrated.rules.track[1].label == 'Both', 'order within a kind is preserved')
  check(migrated.rules.track[2].label == 'First', 'and the second one follows')
  check(#migrated.rules.item == 1,   'the item copy lands on the item tab')
  check(#migrated.rules.region == 1, 'the region rule lands on the region tab')
  check(#migrated.rules.marker == 0, 'nothing lands on the marker tab')
  check(migrated.rules.track[1].id ~= migrated.rules.item[1].id,
        'the split copies do not share an id')
  check(migrated.rules.item[1].pattern == 'x', 'the copy keeps the pattern')
  check(migrated.rules.item[1].color == 0x111111, 'and the colour')
  check(migrated.options.propagate_folders == 'force', 'options survive migration')
  check(type(migrated.options.clear_unmatched) == 'table',
        'a v1 clear_unmatched boolean becomes a per-kind table')
  check(migrated.version == CF.VERSION, 'the migrated config is stamped v2')
end

-- File round trip, skipped inside REAPER so tests never touch the real config.
if not IN_REAPER and os.getenv('NC_TEST_DIR') then
  local cfg = CF.starter()
  cfg.options.font_size = 17
  -- A default-TRUE boolean turned off is the case that used to be lost: it
  -- has to survive the write AND the normalize on the way back in.
  cfg.options.subfolder_splits_range = false
  local ok, err = CF.save(cfg)
  check(ok, 'config saves', tostring(err))

  local loaded, info = CF.load()
  check(not info.created, 'second load is not a first run')
  check(loaded.options.font_size == 17, 'options survive a round trip')
  check(loaded.options.subfolder_splits_range == false,
        'and a default-true boolean turned OFF stays off')
  check(#loaded.rules.track == #cfg.rules.track, 'track rules survive a round trip')
  check(#loaded.rules.region == #cfg.rules.region, 'region rules survive a round trip')
  check(loaded.rules.track[1].pattern == cfg.rules.track[1].pattern,
        'patterns survive verbatim')
  check(loaded.rules.track[1].id == cfg.rules.track[1].id, 'rule ids are stable')
  check(loaded.rules.track[1].cascade_items == cfg.rules.track[1].cascade_items,
        'the cascade switch survives a round trip')

  -- the per-kind clear option must survive JSON, not collapse to a boolean
  cfg.options.clear_unmatched = { track = false, item = true,
                                  region = false, marker = true }
  assert(CF.save(cfg))
  local l2 = CF.load()
  check(type(l2.options.clear_unmatched) == 'table', 'clear_unmatched stays a table')
  check(l2.options.clear_unmatched.item == true,   'a ticked kind survives')
  check(l2.options.clear_unmatched.marker == true, 'and another one')
  check(l2.options.clear_unmatched.track == false, 'an unticked kind stays off')

  -- a corrupt file must be parked, not lost, and must not stop the tool
  local f = io.open(CF.path(), 'wb'); f:write('{not json'); f:close()
  local c2, info2 = CF.load()
  check(info2.corrupt, 'corrupt config is detected')
  check(io.open(CF.badpath()) ~= nil, 'corrupt config is kept aside')
  check(#c2.rules.track == 0, 'corrupt config falls back to defaults')

  -- a file from a newer build loads read-only rather than being downgraded
  local f2 = io.open(CF.path(), 'wb')
  f2:write(J.encode{ version = CF.VERSION + 5, options = {}, rules = {} })
  f2:close()
  local _, info3 = CF.load()
  check(info3.readonly, 'a newer config version loads read-only')

  os.remove(CF.path()); os.remove(CF.bakpath()); os.remove(CF.badpath())
end

-- Rules carry runtime scratch (_m, _err, _timeouts) once prepared. Serialising
-- those directly fails, which used to silently break every save after the
-- first preview.
do
  local cfg2 = CF.starter()
  MT.prepare(cfg2.rules.track)
  check(cfg2.rules.track[1]._m ~= nil, 'a prepared rule really does carry scratch')
  check(J.encode(cfg2) == nil, 'encoding a live rule fails, as expected')
  local enc = J.encode(CF.serializable(cfg2))
  check(enc ~= nil, 'serializable() strips the scratch so encoding works')
  for _, k in ipairs({ '"_m"', '"_err"', '"_errpos"', '"_timeouts"' }) do
    check(enc and not enc:find(k, 1, true), 'no runtime key ' .. k .. ' leaks into the file')
  end
  local back = J.decode(enc or '')
  check(back and #back.rules.track == #cfg2.rules.track, 'the cleaned copy keeps every rule')
  check(back and back.rules.track[1].pattern == cfg2.rules.track[1].pattern,
        'patterns survive cleaning')
end

--=============================================================== sws import
-- This whole section runs with no REAPER table in sight, which is the point:
-- everything except paths()/read() is pure, so the mapping is testable here
-- rather than only by clicking about inside REAPER.
local SI = require 'swsimport'

do -- tokenizer: WDL's LineParser rules, quotes and all
  local t = SI.tokenize('0 "(MIDI input)" 50331644 "" "" ""')
  check(#t == 6, 'a modern record is six tokens', #t .. ' tokens')
  check(t[2] == '(MIDI input)', 'a quoted token loses its quotes')
  -- Load-bearing: the token COUNT is what separates the modern record from the
  -- legacy three-token one, so trailing empties must not be swallowed.
  check(t[4] == '' and t[5] == '' and t[6] == '', 'empty tokens are emitted, not skipped')

  local b = SI.tokenize('0 (any) 0 "" "" ""')
  check(b[2] == '(any)', 'a bare token survives -- SWS only quotes what it must')

  check(SI.tokenize("x 'has \"quotes\"' y")[2] == 'has "quotes"',
        'single quotes are a quote character too')
  check(SI.tokenize('x `odd \'un` y')[2] == "odd 'un", 'and so is a backtick')

  check(#SI.tokenize('a b ;trailing note') == 2, '";" at a token start starts a comment')
  check(#SI.tokenize('a b #trailing note') == 2, 'and so does "#"')
  check(SI.tokenize('a;b')[1] == 'a;b', 'but only at a token start, never mid-token')

  check(SI.tokenize('a "unterminated')[2] == 'unterminated',
        'an unterminated quote runs to the end of the line, as WDL does')
  check(#SI.tokenize('a\tb\t\tc') == 3, 'tabs separate tokens')
  check(#SI.tokenize('') == 0, 'an empty line is no tokens')
end

do -- ini reader
  local ini = SI.ini('[A]\nx=1\n[SWS]\nAutoColor 1=0 (any) 0\nAutoColorCount=1\n')
  check(ini.SWS ~= nil and ini.A ~= nil, 'sections are kept apart')
  check(ini.SWS['AutoColor 1'] == '0 (any) 0', 'a key keeps its embedded space')
  check(ini.A.x == '1' and ini.SWS.x == nil, 'keys do not leak between sections')
  -- A filter can contain '=' and a key never does.
  check(SI.ini('[SWS]\nk=a=b\n').SWS.k == 'a=b', 'the split is at the FIRST "="')
  -- An ini carried over from a Windows install is CRLF, and without this
  -- tonumber('16\r') is nil and the import silently finds nothing.
  check(SI.ini('[SWS]\r\nAutoColorCount=2\r\n').SWS.AutoColorCount == '2',
        'a trailing CR is stripped')
  check(next(SI.ini('no section here\nk=v\n')) == nil, 'keys before any section are dropped')
end

do -- colour decode -- deliberately NOT routed through colors.lua
  local w, c = SI.decode_color(50331644)     -- the value in the real file
  check(w == 'rgb' and c == 0xFFFFFC, 'a portable colour drops its flag and enable bit',
        tostring(w) .. ' ' .. string.format('%06X', c or 0))

  local w0, c0 = SI.decode_color(0)
  -- colors.from_native answers nil here, which would quietly turn every black
  -- SWS rule into the default grey. This is the one place that matters.
  check(w0 == 'rgb' and c0 == 0x000000, '0 is BLACK, not "no colour"')

  local _, c2 = SI.decode_color(0x2000000 | 0x123456)
  check(c2 == 0x123456, 'the portable flag is stripped, the colour is not')

  for n, name in pairs({ [-1] = 'custom', [-2] = 'gradient', [-3] = 'random',
                         [-4] = 'none', [-5] = 'parent', [-6] = 'ignore' }) do
    check(select(1, SI.decode_color(n)) == name, 'sentinel ' .. n .. ' is "' .. name .. '"')
    check(select(2, SI.decode_color(n)) == nil, 'and carries no colour')
  end

  -- No portable flag: written before the format was portable, so it is in the
  -- byte order of whichever machine wrote it and only the host can say which.
  local got
  local _, cl = SI.decode_color(0xFF0000, {
    native_to_rgb = function(v) got = v; return ((v & 0xFF) << 16) | (v & 0xFF00) | ((v >> 16) & 0xFF) end,
  })
  check(got == 0xFF0000, 'a legacy colour is handed to the host already masked to 24 bits')
  check(cl == 0x0000FF, 'and the host decides its byte order')
  check(select(2, SI.decode_color(0xFF0000)) == 0xFF0000,
        'with no host, a legacy colour is left alone')
end

do -- gradient endpoints, which live in reaper.ini rather than beside the rules
  local a, b = SI.gradient_ends('[SWS]\nColorGradients=33554432 50331647\n')
  check(a == 0x000000 and b == 0xFFFFFF, 'portable gradient endpoints are decoded',
        string.format('%06X %06X', a, b))
  local da, db = SI.gradient_ends(nil)
  check(da == 0x000000 and db == 0xFFFFFF, 'an absent reaper.ini falls back to SWS\'s default')
  check(select(1, SI.gradient_ends('[SWS]\nColorGradients=-3 -3\n')) == 0x000000,
        'a sentinel where a colour belongs falls back too')
end

-- The fixture. Read by path so the awkward cases live in a file that looks
-- like the real thing rather than as string literals dotted through here.
local FIXDIR = ROOT .. '../../../tests/fixtures/'
local function slurp(p)
  local f = io.open(p, 'r'); if not f then return nil end
  local s = f:read('a'); f:close(); return s
end
local FIX  = slurp(FIXDIR .. 'sws-autocoloricon.ini')
local RINI = slurp(FIXDIR .. 'reaper.ini')
check(FIX ~= nil, 'the SWS fixture is readable')

if FIX then
  local res = SI.parse(FIX, RINI)
  local by = {}
  for _, k in ipairs({ 'track', 'item', 'region', 'marker' }) do
    by[k] = res.rules[k]
  end

  check(res.count == 16, 'every AutoColorCount entry is looked at', tostring(res.count))
  check(#by.item == 0, 'SWS has no item rules, so the item list stays empty')
  check(#by.region == 1, 'a type-2 rule becomes a region rule', tostring(#by.region))
  check(#by.marker == 1, 'a type-1 rule becomes a marker rule', tostring(#by.marker))
  -- 14 is an unknown type and 15 has too few tokens; neither can be a rule.
  check(res.skipped == 2, 'an unknown type and a malformed line are skipped',
        tostring(res.skipped))
  check(res.imported == 14, 'and everything else is imported', tostring(res.imported))

  local t = by.track
  check(t[1].pattern == '(MIDI input)' and t[1].enabled == false,
        'an unsupported property filter arrives OFF')
  -- Not an empty pattern: that would match EVERY track, so re-enabling it out
  -- of curiosity would repaint the project. The keyword matches nothing.
  check(t[1].label:find('(MIDI input) filter is not supported', 1, true) ~= nil,
        'and says why in its NAME, which is the only field the list renders')

  check(t[2].pattern == '' and t[2].only == nil and t[2].enabled == true,
        '(any) is an empty pattern with no filter')
  check(t[3].pattern == 'Kick' and t[3].mode == 'substring' and t[3].ci == true,
        'a plain name filter is a case-insensitive substring -- SWS\'s stristr exactly')
  check(t[3].color == 0x00A655, 'and keeps its colour',
        string.format('%06X', t[3].color))
  check(t[4].pattern == 'Lead Vox', 'a quoted filter keeps its spaces')
  check(t[4].label == 'Lead Vox', 'and the filter becomes the rule name')

  check(t[5].only == 'folder' and t[5].pattern == '', '(folder) becomes the folder filter')
  -- The one sentinel that translates exactly: SWS ramps its global gradient
  -- across every track THAT rule matched, which is what scope 'all' means.
  check(t[5].enabled == true, 'a gradient rule arrives ENABLED')
  check(t[5].color == 0x000000 and t[5].color2 == 0xFFFFFF,
        'with the SWS gradient endpoints')
  check(t[5].gradient_scope == 'all', 'spread across all matches')
  check(t[5].label == '(folder)', 'and nothing appended to its name')

  check(t[6].only == 'unnamed' and t[6].enabled == false,
        '(unnamed) maps, but a random colour does not')
  check(t[6].label:find('random colours', 1, true) ~= nil, 'and says so')
  check(t[7].only == 'children' and t[7].enabled == false, '(children) maps, parent colour does not')
  check(t[8].enabled == false, '(master) arrives off')
  check(t[8].label:find('(master) filter', 1, true) ~= nil,
        'because REAPER ignores a custom colour on the master track')

  check(t[9].color == 0xFF0000, 'a legacy colour with no portable flag still decodes',
        string.format('%06X', t[9].color))
  check(t[10].pattern == 'say "hi"', 'a filter SWS had to single-quote round trips')
  check(t[11].pattern == 'Legacy' and t[11].color == 0x00A655,
        'the legacy three-token form is a track rule')
  check(t[12].enabled == false and t[12].label:find('ignore', 1, true) ~= nil,
        '"ignore" arrives off -- its loss changes which OTHER rule wins')

  check(by.region[1].pattern == '' and by.region[1].color == 0xFFFFFF,
        'the region rule keeps its colour')
  check(by.marker[1].only == 'unnamed' and by.marker[1].enabled == false,
        'the marker rule keeps its filter and loses its "none" colour')

  check(res.disabled == 6, 'six rules could not be expressed', tostring(res.disabled))

  -- Order is priority order on both sides, so it has to survive the trip.
  check(#t == 12, 'twelve of the sixteen entries are track rules', tostring(#t))
  check(t[1].pattern == '(MIDI input)' and t[12].pattern == 'Ignored',
        'file order is preserved within a kind')

  -- Normalising twice must be a no-op, or a hand edit of the saved file would
  -- come back different from what was written.
  local stable = true
  for _, list in pairs(res.rules) do
    for _, r in ipairs(list) do
      local again = RU.normalize({ id = r.id, label = r.label, enabled = r.enabled,
                                   mode = r.mode, pattern = r.pattern, only = r.only,
                                   ci = r.ci, invert = r.invert, color = r.color,
                                   color2 = r.color2, note = r.note,
                                   cascade_items = r.cascade_items,
                                   gradient_scope = r.gradient_scope }, r.kind)
      if again.enabled ~= r.enabled or again.only ~= r.only
         or again.color ~= r.color or again.gradient_scope ~= r.gradient_scope then
        stable = false
      end
    end
  end
  check(stable, 'every imported rule is already normalised')

  -- The regression that would otherwise only surface as a silently failed save.
  do
    local cfg = CF.defaults()
    SI.merge(cfg, res)
    local enc = J.encode(CF.serializable(CF.normalize(cfg)))
    check(enc ~= nil, 'an imported rule set encodes')
    local ids = {}
    local dup = false
    for _, r in ipairs(CF.all_rules(cfg)) do
      if ids[r.id] then dup = true end
      ids[r.id] = true
    end
    check(not dup, 'and every rule has a distinct id')
  end
end

do -- merge
  local res = SI.parse('[SWS]\nAutoColorCount=1\nAutoColor 1=0 Kick 50374229 "" "" ""\n')
  check(res.imported == 1, 'a one-rule file imports one rule')

  local cfg = CF.defaults()
  cfg.rules.track[1] = RU.new('track', { pattern = 'mine' })
  cfg.rules.item[1]  = RU.new('item',  { pattern = 'takes' })
  SI.merge(cfg, res, 'append')
  check(#cfg.rules.track == 2, 'append grows the list')
  -- END, not top: an SWS "(any)" catch-all arriving above the user's own rules
  -- would repaint the project on the next auto tick.
  check(cfg.rules.track[1].pattern == 'mine', 'and the user\'s rules keep precedence')
  check(cfg.rules.track[2].pattern == 'Kick', 'with the imported ones below')
  check(#cfg.rules.item == 1, 'append leaves the item tab alone')

  -- There is no replace mode, and that is the point: merge can only ever grow
  -- a list, so no import can destroy a rule the user wrote.
  local cfg3 = CF.defaults()
  cfg3.rules.track[1] = RU.new('track', { pattern = 'mine' })
  SI.merge(cfg3, SI.parse('[SWS]\nAutoColorCount=0\n'))
  check(#cfg3.rules.track == 1, 'importing nothing changes nothing')
end

do -- degenerate files
  check(SI.parse('').imported == 0, 'an empty file imports nothing')
  check(SI.parse('[Other]\nx=1\n').count == 0, 'a file with no [SWS] section imports nothing')
  check(SI.parse('[SWS]\nAutoColorCount=3\nAutoColor 1=0 a 0 "" "" ""\n').skipped == 2,
        'a count larger than the rules present skips the gaps')
  -- A hand-edited file with the count dropped should not lose rules that are
  -- plainly there.
  check(SI.parse('[SWS]\nAutoColor 1=0 a 0 "" "" ""\nAutoColor 2=0 b 0 "" "" ""\n').imported == 2,
        'a missing count falls back to the highest index present')
end

--=================================================================== about
-- The version exists twice: ReaPack reads it from the header of
-- Color/MXM_AutoColor.lua, which never ships to Scripts/, and lib/about.lua
-- carries the copy the About dialog shows. Nothing stops them drifting except
-- this.
do
  local AB = require 'about'
  check(AB.VERSION:match('^%d+%.%d+%.%d+$') ~= nil,
        'the shipped version is three numbers', tostring(AB.VERSION))
  for _, k in ipairs({ 'NAME', 'AUTHOR', 'LICENCE', 'COPYRIGHT', 'TAGLINE',
                       'URL_REPO', 'URL_DOCS' }) do
    check(type(AB[k]) == 'string' and AB[k] ~= '', 'about carries ' .. k)
  end
  check(AB.URL_REPO:match('^https://') ~= nil, 'the repo link is https')
  check(AB.URL_DOCS:match('^https://') ~= nil, 'and so is the docs link')

  -- Only reachable outside REAPER: the manifest is not installed beside the
  -- scripts, so there is nothing to compare against in there.
  if not IN_REAPER then
    -- run.sh runs this with the cwd at the script directory, three levels under
    -- the repo root. Both spellings are tried so running it from the root works
    -- too; if neither is there the check simply does not run.
    local f
    for _, rel in ipairs({ '../../../Color/MXM_AutoColor.lua',
                           'Color/MXM_AutoColor.lua' }) do
      f = io.open(rel)
      if f then break end
    end
    if f then
      local manifest = f:read('a'); f:close()
      local declared = manifest:match('\nVersion:%s*([%d%.]+)')
      check(declared ~= nil, 'the ReaPack manifest declares a version')
      check(declared == AB.VERSION,
            'the shipped version matches the ReaPack manifest',
            tostring(declared) .. ' vs ' .. tostring(AB.VERSION))
    end
  end
end

--=================================================================== apply
-- plan() is pure, so the whole decision layer can be tested with synthetic
-- entries -- no project, no REAPER objects.
local AP = require 'apply'

local RED, GRN, BLU = 0xC44A3B, 0x3BC44A, 0x3B4AC4

local function tr(name, o)
  o = o or {}
  return { kind = 'track', name = name, guid = 'g:' .. name,
           folderdepth = o.fd or 0, depth = o.depth or 0,
           context = o.context, spacer_above = o.spacer,
           color = o.color and CO.to_native(o.color) or 0 }
end
local function item(name, o)
  o = o or {}
  return { kind = 'item', name = name, guid = 'i:' .. name,
           track_guid = o.on and ('g:' .. o.on) or nil,
           color = o.color and CO.to_native(o.color) or 0 }
end
local function region(name, o)
  o = o or {}
  return { kind = 'region', name = name, guid = 'r:' .. name,
           color = o.color and CO.to_native(o.color) or 0 }
end
local function marker(name, o)
  o = o or {}
  return { kind = 'marker', name = name, guid = 'm:' .. name,
           color = o.color and CO.to_native(o.color) or 0 }
end

--- build a rules map from { track = {...}, item = {...} } shorthand
local function ruleset(spec)
  local out = {}
  for _, k in ipairs(RU.KINDS) do
    out[k] = {}
    for _, o in ipairs(spec[k] or {}) do
      out[k][#out[k] + 1] = RU.new(k, o)
    end
  end
  return out
end

-- name -> planned colour ('CLEAR' for a clear op); entries with no op are absent
local function planmap(entries, rules, opts)
  local ops = AP.plan(entries, rules, opts or {})
  local out = {}
  for _, op in ipairs(ops) do
    out[op.entry.name] = op.clear and 'CLEAR' or op.rgb
  end
  return out, ops
end

-- first match wins, within the kind's own list
do
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'bass', color = RED },
    { mode = 'substring', pattern = 'sub',  color = BLU },
  } }
  check(planmap({ tr('Sub Bass') }, rs)['Sub Bass'] == RED, 'first matching rule wins')
end
do
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'sub',  color = BLU },
    { mode = 'substring', pattern = 'bass', color = RED },
  } }
  check(planmap({ tr('Sub Bass') }, rs)['Sub Bass'] == BLU, 'reordering changes the winner')
end

-- a rule only ever sees its own kind
do
  local rs = ruleset{ item = { { mode = 'substring', pattern = 'x', color = RED } } }
  local m = planmap({ tr('x1'), item('x2') }, rs)
  check(m['x1'] == nil, 'an item rule leaves tracks alone')
  check(m['x2'] == RED, 'an item rule colours items')
end
do
  local rs = ruleset{ region = { { mode = 'regex', pattern = '^Chorus', color = RED } } }
  local m = planmap({ region('Chorus 1'), marker('Chorus 1'), region('Verse 1') }, rs)
  check(m['Chorus 1'] == RED, 'a region rule matches regions')
  check(m['Verse 1'] == nil,  'and is selective')
  local mk = planmap({ marker('Chorus 1') }, rs)
  check(next(mk) == nil, 'a region rule does NOT touch a marker of the same name')
end

-- precedence between the tabs is independent
do
  local rs = ruleset{
    track  = { { mode = 'substring', pattern = 'a', color = RED } },
    region = { { mode = 'substring', pattern = 'a', color = BLU } },
  }
  local m = planmap({ tr('abc'), region('abc') }, rs)
  check(m['abc'] == RED or m['abc'] == BLU, 'both kinds resolve')
  local ops = select(2, planmap({ tr('abc'), region('abc') }, rs))
  local bykind = {}
  for _, op in ipairs(ops) do bykind[op.entry.kind] = op.rgb end
  check(bykind.track == RED,  'the track rule colours the track')
  check(bykind.region == BLU, 'the region rule colours the region, independently')
end

-- disabled rules are skipped
do
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'bass', color = RED, enabled = false },
    { mode = 'substring', pattern = 'bass', color = BLU },
  } }
  check(planmap({ tr('Bass') }, rs)['Bass'] == BLU, 'disabled rule is skipped')
end

-- filters narrow, they do not replace the pattern
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = '', only = 'folder',
                                  color = RED } } }
  local m = planmap({ tr('Drums', { fd = 1 }), tr('Kick'), tr('Snare', { fd = -1 }) },
                    rs, { propagate_folders = 'off' })
  check(m['Drums'] == RED, 'folder filter matches the parent')
  check(m['Kick'] == nil,  'folder filter skips children')
end

-- invert
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'bass', color = RED,
                                  invert = true } } }
  local m = planmap({ tr('Bass'), tr('Kick') }, rs)
  check(m['Bass'] == nil, 'inverted rule skips what it matches')
  check(m['Kick'] == RED, 'inverted rule takes what it does not match')
end

-- no-op pruning
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'bass', color = RED } } }
  local ops, stats = AP.plan({ tr('Bass', { color = RED }) }, rs, {})
  check(#ops == 0, 'an already-correct colour produces no op')
  check(stats.unchanged == 1, 'stats count it as unchanged')
  check(stats.matched == 1,   'stats still count it as matched')
end

-- clear_unmatched, now per kind
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'bass', color = RED } } }
  local entries = { tr('Bass', { color = RED }), tr('Random', { color = GRN }) }
  check(planmap(entries, rs, {})['Random'] == nil,
        'unmatched colours are left alone by default')
  check(planmap(entries, rs, { clear_unmatched = { track = true } })['Random'] == 'CLEAR',
        'clearing is honoured for the track kind')
  check(planmap(entries, rs, { clear_unmatched = { item = true } })['Random'] == nil,
        'and NOT applied to a kind that was not ticked')
  check(planmap(entries, rs, { clear_unmatched = true })['Random'] == 'CLEAR',
        'a legacy boolean still applies to every kind')
end

-- THE point of clearing items: an item with no custom colour is drawn by REAPER
-- in its TRACK's colour, live, so it follows whatever track it is moved to.
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Strings', color = BLU } } }
  local entries = { tr('Strings'), item('06-Strum', { on = 'Strings', color = RED }) }

  check(planmap(entries, rs, { propagate_folders = 'off' })['06-Strum'] == nil,
        'by default a pasted item keeps its old colour')

  local m = planmap(entries, rs, { propagate_folders = 'off',
                                   clear_unmatched = { item = true } })
  check(m['06-Strum'] == 'CLEAR',
        'clearing unmatched items releases a stale pasted colour')
  check(m['Strings'] == BLU, 'while the track itself is still coloured')
end

do -- an item claimed by an item rule or by a cascade is never cleared
  local rs = ruleset{
    track = { { mode = 'substring', pattern = 'Strings', color = BLU,
                cascade_items = true } },
    item  = { { mode = 'glob', pattern = '*comp*', color = GRN } },
  }
  local entries = { tr('Strings'),
                    item('a_comp_1', { on = 'Strings', color = RED }),
                    item('plain',    { on = 'Strings', color = RED }) }
  local m = planmap(entries, rs, { propagate_folders = 'off',
                                   clear_unmatched = { item = true } })
  check(m['a_comp_1'] == GRN, 'an item rule still wins over clearing')
  check(m['plain'] == BLU,    'and a cascade still wins over clearing')
end

-- gradients
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'T', color = RED,
                                  color2 = BLU } } }
  local m = planmap({ tr('T1'), tr('T2'), tr('T3') }, rs, { propagate_folders = 'off' })
  check(m['T1'] == RED, 'gradient starts at the first colour')
  check(m['T3'] == BLU, 'gradient ends at the second colour')
  check(m['T2'] ~= RED and m['T2'] ~= BLU, 'gradient middle is distinct')
end

--------------------------------------------------- gradient grouping
-- A gradient used to spread across every match in the project. It now restarts
-- per group, and gradient_scope says what separates one group from the next.

local function grad_rule(o)
  o.color, o.color2 = RED, BLU
  return o
end

do -- runs: a track the rule does not win ends the gradient
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'run' } } }
  local entries = { tr('String1'), tr('String2'), tr('String3'),
                    tr('Bus'),
                    tr('String11'), tr('String12'), tr('String13') }
  local m = planmap(entries, rs, { propagate_folders = 'off' })
  check(m['String1']  == RED, 'first run starts at colour 1')
  check(m['String3']  == BLU, 'and ends at colour 2')
  check(m['String11'] == RED, 'the second run starts over')
  check(m['String13'] == BLU, 'and ends at colour 2 as well')
  check(m['String2'] == m['String12'], 'matching positions get the same shade')
  check(m['String2'] ~= RED and m['String2'] ~= BLU, 'and it really is mid-ramp')
end

do -- 'all' keeps the old whole-project spread
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'all' } } }
  local entries = { tr('String1'), tr('String2'), tr('String3'),
                    tr('Bus'),
                    tr('String11'), tr('String12'), tr('String13') }
  local m = planmap(entries, rs, { propagate_folders = 'off' })
  check(m['String13'] == BLU, 'the ramp ends at the last match in the project')
  check(m['String3']  ~= BLU, 'and does not restart at the gap')
end

do -- a REAPER visual spacer ends a run, with no separator track needed
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'run' } } }
  -- the spacer is stored on the track BELOW the gap (I_SPACER = "above this")
  local m = planmap({ tr('Str1'), tr('Str2'), tr('Str3'),
                      tr('Str4', { spacer = true }), tr('Str5'), tr('Str6') }, rs,
                    { propagate_folders = 'off' })
  check(m['Str1'] == RED and m['Str3'] == BLU, 'the run above the spacer ramps fully')
  check(m['Str4'] == RED and m['Str6'] == BLU, 'and the one below starts over')
  check(m['Str2'] == m['Str5'], 'matching positions match')

  -- with no spacer the same six tracks are one ramp
  local m2 = planmap({ tr('Str1'), tr('Str2'), tr('Str3'),
                       tr('Str4'), tr('Str5'), tr('Str6') }, rs,
                     { propagate_folders = 'off' })
  check(m2['Str3'] ~= BLU, 'without the spacer they are a single group')
end

do -- a spacer does not disturb folder grouping, which is structural
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('Str1', { fd = 1 }), tr('Str2', { depth = 1, spacer = true }),
                      tr('Str3', { fd = -1, depth = 1 }) }, rs,
                    { propagate_folders = 'off' })
  check(m['Str1'] == RED and m['Str3'] == BLU,
        'by folder, a spacer inside the folder is ignored')
end

do -- a lone match is a group of one, so it gets the first colour
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'run' } } }
  local m = planmap({ tr('String1'), tr('Bus'), tr('String2') }, rs,
                    { propagate_folders = 'off' })
  check(m['String1'] == RED and m['String2'] == RED,
        'a group of one gets the first colour')
end

do -- a DIFFERENT rule between two matches also ends the run
  local rs = ruleset{ track = {
    grad_rule{ mode = 'substring', pattern = 'String', gradient_scope = 'run' },
    { mode = 'substring', pattern = 'Bass', color = GRN },
  } }
  local m = planmap({ tr('String1'), tr('Bass'), tr('String2') }, rs,
                    { propagate_folders = 'off' })
  check(m['String1'] == RED and m['String2'] == RED,
        'a run is a stretch won by the SAME rule, not merely "matched"')
end

do -- context entries take part in grouping, both ways round
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'run' } } }
  local m = planmap({ tr('String1'), tr('String2'),
                      tr('Bus', { context = true }), tr('String3') }, rs,
                    { propagate_folders = 'off' })
  check(m['String3'] == RED, 'a context entry ends a run like any other')

  -- The guarantee this protects: apply-to-selection must colour a track the
  -- same as apply-all. Under selected_only the unselected tracks come through
  -- as context, so if grouping ignored them the ranks would differ.
  local all = planmap({ tr('String1'), tr('String2'), tr('String3') }, rs,
                      { propagate_folders = 'off' })
  local sel = planmap({ tr('String1', { context = true }), tr('String2'),
                        tr('String3') }, rs, { propagate_folders = 'off' })
  check(all['String2'] == sel['String2'] and all['String3'] == sel['String3'],
        'a selection gets the same colours as a full apply')
end

do -- one kind's entries never split another kind's run
  local rs = ruleset{ region = { grad_rule{ mode = 'substring', pattern = 'Ch',
                                            gradient_scope = 'run' } } }
  local m = planmap({ region('Ch1'), marker('X'), region('Ch2') }, rs, {})
  check(m['Ch1'] == RED and m['Ch2'] == BLU,
        'a marker between two regions does not split their run')

  -- but a region the rule does not win does
  local m2 = planmap({ region('Ch1'), region('Verse'), region('Ch2') }, rs, {})
  check(m2['Ch1'] == RED and m2['Ch2'] == RED,
        'an unmatched region between them splits it into two groups of one')

  -- which is exactly why regions default to one ramp across everything
  local dflt = ruleset{ region = { grad_rule{ mode = 'substring', pattern = 'Ch' } } }
  local m3 = planmap({ region('Ch1'), region('Verse'), region('Ch2') }, dflt, {})
  check(m3['Ch1'] == RED and m3['Ch2'] == BLU,
        'by default an interleaved region rule still ramps across all its matches')
end

do -- folders
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'folder' } } }
  local entries = {
    tr('String1',  { fd = 1 }), tr('String2', { depth = 1 }),
    tr('String3',  { fd = -1, depth = 1 }),
    tr('String11', { fd = 1 }), tr('String12', { depth = 1 }),
    tr('String13', { fd = -1, depth = 1 }),
  }
  local m = planmap(entries, rs, { propagate_folders = 'off' })
  check(m['String1'] == RED and m['String11'] == RED, 'each folder starts its own ramp')
  check(m['String3'] == BLU and m['String13'] == BLU, 'and runs to the end of it')
end

do -- with no folders at all, folder scope behaves like 'all'
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('String1'), tr('String2'), tr('String3') }, rs,
                    { propagate_folders = 'off' })
  check(m['String3'] == BLU, 'tracks outside any folder share one group')
end

do -- a top-level folder ends the range around it, like any other
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'A',
                                           gradient_scope = 'folder' } } }
  local entries = { tr('A1'), tr('F', { fd = 1 }),
                    tr('Kid', { depth = 1, fd = -1 }), tr('A2') }

  -- Each is then a group of ONE, and colors.gradient gives a lone member the
  -- first colour -- the flattening the option's tooltip warns about.
  local on = planmap(entries, rs, { propagate_folders = 'off' })
  check(on['A1'] == RED and on['A2'] == RED,
        'top-level matches split across an intervening folder')

  local off = planmap(entries, rs, { propagate_folders = 'off',
                                     subfolder_splits_range = false })
  check(off['A1'] == RED and off['A2'] == BLU,
        'but with the split off they stay one group: structure, not adjacency')
end

do -- a nested folder starts its own group
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Vln',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('Strings', { fd = 1 }), tr('Vln1', { depth = 1 }),
                      tr('Solo', { fd = 1, depth = 1 }), tr('Vln2', { depth = 2 }),
                      tr('Vln3', { fd = -2, depth = 2 }) }, rs,
                    { propagate_folders = 'off' })
  check(m['Vln1'] == RED, 'the outer folder ramp starts')
  check(m['Vln2'] == RED, 'and the inner folder starts a fresh one')
  check(m['Vln3'] == BLU, 'which runs to the end of the inner folder')
end

--------------------------------------------- subfolder_splits_range
-- The option is ON by default: a nested folder ends the range of the level it
-- sits in, so the tracks after it ramp again from the start. OFF is the older
-- behaviour, one ramp for the whole folder however deeply it is nested.
-- Only 'folder' scope can see it; 'run' never builds the container map at all
-- and 'both' already broke at a folder edge.

local vrule = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'V',
                                            gradient_scope = 'folder' } } }

do -- the headline case: a subfolder in the middle of a coloured folder
  -- Nothing but the V tracks contains a "v", so Bus/Sub/S1 never match.
  local entries = {
    tr('Bus', { fd = 1 }), tr('V1', { depth = 1 }), tr('V2', { depth = 1 }),
    tr('Sub', { fd = 1, depth = 1 }), tr('S1', { fd = -1, depth = 2 }),
    tr('V3', { depth = 1 }), tr('V4', { fd = -1, depth = 1 }),
  }

  local on = planmap(entries, vrule, { propagate_folders = 'off',
                                       subfolder_splits_range = true })
  check(on['V1'] == RED and on['V2'] == BLU, 'the ramp before the subfolder is whole')
  check(on['V3'] == RED and on['V4'] == BLU, 'and the tracks after it start it again')

  local off = planmap(entries, vrule, { propagate_folders = 'off',
                                        subfolder_splits_range = false })
  check(off['V1'] == RED and off['V4'] == BLU, 'off, the whole folder is one ramp')
  check(off['V2'] ~= BLU and off['V3'] ~= RED, 'which runs straight through the subfolder')

  -- The pin on "absent means on": a caller that predates the option, and every
  -- other test in this file, must get the shipping behaviour.
  local dflt = planmap(entries, vrule, { propagate_folders = 'off' })
  check(dflt['V3'] == on['V3'] and dflt['V4'] == on['V4'],
        'and a caller that omits the option gets the split')
end

do -- a subfolder with nothing after it costs nothing either way
  local entries = { tr('Bus', { fd = 1 }), tr('V1', { depth = 1 }),
                    tr('V2', { depth = 1 }), tr('Sub', { fd = 1, depth = 1 }),
                    tr('S1', { fd = -2, depth = 2 }) }
  local on  = planmap(entries, vrule, { propagate_folders = 'off',
                                        subfolder_splits_range = true })
  local off = planmap(entries, vrule, { propagate_folders = 'off',
                                        subfolder_splits_range = false })
  check(on['V1'] == RED and on['V2'] == BLU, 'the parent ramps in full')
  check(on['V1'] == off['V1'] and on['V2'] == off['V2'],
        'and a trailing subfolder changes nothing')
end

do -- a -2 that lands back INSIDE a folder still restarts that folder
  local entries = { tr('Top', { fd = 1 }), tr('V1', { depth = 1 }),
                    tr('Mid', { fd = 1, depth = 1 }),
                    tr('Deep', { fd = 1, depth = 2 }),
                    tr('D1', { fd = -2, depth = 3 }),
                    tr('V2', { depth = 1 }), tr('V3', { fd = -1, depth = 1 }) }

  local on = planmap(entries, vrule, { propagate_folders = 'off',
                                       subfolder_splits_range = true })
  check(on['V1'] == RED, 'alone before the nest, so it gets the first colour')
  check(on['V2'] == RED and on['V3'] == BLU, 'and the tail of Top ramps in full')

  local off = planmap(entries, vrule, { propagate_folders = 'off',
                                        subfolder_splits_range = false })
  check(off['V1'] == RED and off['V3'] == BLU and off['V2'] ~= RED,
        'off, all three of Top\'s own tracks are one ramp')
end

do -- sibling subfolders leave groups of one, which show the FIRST colour
  local entries = { tr('Bus', { fd = 1 }), tr('V1', { depth = 1 }),
                    tr('SubA', { fd = 1, depth = 1 }), tr('a', { fd = -1, depth = 2 }),
                    tr('V2', { depth = 1 }),
                    tr('SubB', { fd = 1, depth = 1 }), tr('b', { fd = -1, depth = 2 }),
                    tr('V3', { fd = -1, depth = 1 }) }

  local on = planmap(entries, vrule, { propagate_folders = 'off',
                                       subfolder_splits_range = true })
  check(on['V1'] == RED and on['V2'] == RED and on['V3'] == RED,
        'every stretch has one member, so every one is the first colour')

  local off = planmap(entries, vrule, { propagate_folders = 'off',
                                        subfolder_splits_range = false })
  check(off['V1'] == RED and off['V3'] == BLU, 'off, the three are one ramp')
end

do -- the other scopes cannot see the option
  local entries = {
    tr('Bus', { fd = 1 }), tr('V1', { depth = 1 }), tr('V2', { depth = 1 }),
    tr('Sub', { fd = 1, depth = 1 }), tr('S1', { fd = -1, depth = 2 }),
    tr('V3', { depth = 1 }), tr('V4', { fd = -1, depth = 1 }),
  }
  for _, scope in ipairs({ 'both', 'run', 'all' }) do
    local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'V',
                                             gradient_scope = scope } } }
    local on  = planmap(entries, rs, { propagate_folders = 'off',
                                       subfolder_splits_range = true })
    local off = planmap(entries, rs, { propagate_folders = 'off',
                                       subfolder_splits_range = false })
    local same = true
    for _, n in ipairs({ 'V1', 'V2', 'V3', 'V4' }) do
      if on[n] ~= off[n] then same = false end
    end
    check(same, scope .. ' scope is untouched by the split')
  end
end

--------------------------------- a folder rule ramps over what it INHERITS to
-- The rule names the folder; folder colours hand it down to the children; the
-- whole set is then one gradient group. Before this, propagation copied a
-- finished colour, so a two-colour folder rule came out flat.

do -- fill gaps: the parent plus its unmatched children are one ramp
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'green',
                                           gradient_scope = 'folder' } } }
  local entries = { tr('green folder', { fd = 1 }),
                    tr('Track A', { depth = 1 }), tr('Track B', { depth = 1 }),
                    tr('Track C', { depth = 1, fd = -1 }) }

  local m = planmap(entries, rs, { propagate_folders = 'fill_unmatched' })
  check(m['green folder'] == RED, 'the folder itself is the first step')
  check(m['Track C'] == BLU, 'and the last child is the last')
  check(m['Track A'] ~= RED and m['Track A'] ~= BLU, 'with the middle ones between')
  check(m['Track A'] ~= m['Track B'], 'and no two children share a shade')

  -- the old behaviour, for contrast: nothing reaches the children at all
  local off = planmap(entries, rs, { propagate_folders = 'off' })
  check(off['green folder'] == RED, 'with folder colours off the parent is alone')
  check(off['Track A'] == nil, 'and the children get no colour')
end

do -- a child with a rule of its own keeps it, and leaves the parent's ramp
  local rs = ruleset{ track = {
    grad_rule{ mode = 'substring', pattern = 'green', gradient_scope = 'folder' },
    { mode = 'substring', pattern = 'Solo', color = GRN },
  } }
  local m = planmap({ tr('green folder', { fd = 1 }),
                      tr('Track A', { depth = 1 }), tr('Solo', { depth = 1 }),
                      tr('Track B', { depth = 1, fd = -1 }) }, rs,
                    { propagate_folders = 'fill_unmatched' })
  check(m['Solo'] == GRN, 'the child keeps the colour it matched')
  check(m['green folder'] == RED and m['Track B'] == BLU,
        'and the other three still ramp end to end')
end

do -- two folders, two independent ramps
  local rs = ruleset{ track = { grad_rule{ mode = 'regex', pattern = '^(green|blue)',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('green folder', { fd = 1 }),
                      tr('A', { depth = 1 }), tr('B', { depth = 1, fd = -1 }),
                      tr('blue folder', { fd = 1 }),
                      tr('C', { depth = 1 }), tr('D', { depth = 1, fd = -1 }) }, rs,
                    { propagate_folders = 'fill_unmatched' })
  check(m['green folder'] == RED and m['B'] == BLU, 'the first folder ramps in full')
  check(m['blue folder'] == RED and m['D'] == BLU, 'and the second does its own')
end

do -- the cascade flag travels with the inherited rule, as the colour used to
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'green',
                                           gradient_scope = 'folder',
                                           cascade_items = true } },
                      item = {} }
  local m = planmap({ tr('green folder', { fd = 1 }),
                      tr('Kid', { depth = 1, fd = -1 }),
                      item('part', { on = 'Kid' }) }, rs,
                    { propagate_folders = 'fill_unmatched' })
  check(m['Kid'] == BLU, 'the child takes its step of the ramp')
  check(m['part'] == m['Kid'], 'and its items take that same shade')
end

do -- container identity, straight from folder_groups
  local e = { tr('Bus', { fd = 1 }), tr('V1'), tr('Sub', { fd = 1 }),
              tr('S1', { fd = -1 }), tr('V2'), tr('V3', { fd = -1 }) }

  local off = AP.folder_groups(e, false)
  check(off[2] == off[5], 'without the split the level resumes its own container')

  local on = AP.folder_groups(e, true)
  check(on[2] ~= on[5], 'with it, coming out of a subfolder starts a new one')
  check(on[5] == on[6], 'shared by everything after it')
  check(on[3] == on[4] and on[3] ~= on[2] and on[3] ~= on[5],
        'and the subfolder itself stays a third, distinct container')
end

do -- the parent need not match for its children to be grouped by it
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('Bus', { fd = 1 }), tr('String1', { depth = 1 }),
                      tr('String2', { depth = 1 }),
                      tr('String3', { fd = -1, depth = 1 }) }, rs,
                    { propagate_folders = 'off' })
  check(m['String1'] == RED and m['String3'] == BLU,
        'children ramp inside a folder whose parent does not match')
  check(m['Bus'] == nil, 'and the parent is left alone')
end

do -- THE difference between the two modes, on identical entries
  local entries = { tr('F', { fd = 1 }), tr('String1', { depth = 1 }),
                    tr('Perc', { depth = 1 }),
                    tr('String2', { fd = -1, depth = 1 }) }
  local byfolder = planmap(entries,
    ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                  gradient_scope = 'folder' } } },
    { propagate_folders = 'off' })
  check(byfolder['String1'] == RED and byfolder['String2'] == BLU,
        'by folder, a non-matching track in the middle is ignored')

  local byrun = planmap(entries,
    ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'String',
                                  gradient_scope = 'run' } } },
    { propagate_folders = 'off' })
  check(byrun['String1'] == RED and byrun['String2'] == RED,
        'by run, it splits them into two groups of one')
end

do -- 'both' breaks on a gap AND on a folder edge
  -- note the pattern: 'S' would match "Bus" too (matching ignores case by
  -- default), so the separator has to be something the rule really misses
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'both' } } }
  local m = planmap({ tr('Str1', { fd = 1 }), tr('Str2', { fd = -1, depth = 1 }),
                      tr('Str3'), tr('Bus'), tr('Str4') }, rs,
                    { propagate_folders = 'off' })
  check(m['Str1'] == RED and m['Str2'] == BLU, 'the folder is one group')
  check(m['Str3'] == RED, 'leaving the folder starts another')
  check(m['Str4'] == RED, 'and the gap starts a third')
end

do -- a -2 close pops both levels of the container stack
  local e = { tr('Outer', { fd = 1 }), tr('Inner', { fd = 1 }),
              tr('Leaf', { fd = -2 }), tr('After') }

  local fg = AP.folder_groups(e, false)
  check(fg[1] ~= 0 and fg[2] ~= 0, 'the two folders have containers')
  check(fg[1] ~= fg[2], 'and they are different ones')
  check(fg[3] == fg[2], 'the leaf belongs to the inner folder')
  check(fg[4] == 0, 'and a -2 close returns to the root')

  -- With the split on the root is re-issued rather than reused, so 'After'
  -- shares a container with nothing before it.
  local sp = AP.folder_groups(e, true)
  check(sp[3] == sp[2], 'the leaf still belongs to the inner folder')
  check(sp[4] ~= 0, 'and the root it returns to is a fresh container')
  check(sp[4] ~= sp[1] and sp[4] ~= sp[2], 'shared with neither folder')
end

do -- items: a change of track ends the run
  local rs = ruleset{ item = { grad_rule{ mode = 'substring', pattern = 'a',
                                          gradient_scope = 'run' } } }
  local m = planmap({ tr('T1'), tr('T2'),
                      item('a1', { on = 'T1' }), item('a2', { on = 'T1' }),
                      item('a3', { on = 'T2' }), item('a4', { on = 'T2' }) }, rs,
                    { propagate_folders = 'off' })
  check(m['a1'] == RED and m['a2'] == BLU, 'the first track ramps fully')
  check(m['a3'] == RED and m['a4'] == BLU, 'and so does the second, separately')
end

do -- items: 'all' still means "all on this track", not all in the project
  -- Without this the two tracks below share one four-step ramp, so neither
  -- gets the full range and the colours depend on how many OTHER tracks happen
  -- to hold matching items.
  local rs = ruleset{ item = { grad_rule{ mode = 'substring', pattern = 'a',
                                          gradient_scope = 'all' } } }
  local m = planmap({ tr('T1'), tr('T2'),
                      item('a1', { on = 'T1' }), item('a2', { on = 'T1' }),
                      item('a3', { on = 'T2' }), item('a4', { on = 'T2' }) }, rs,
                    { propagate_folders = 'off' })
  check(m['a1'] == RED and m['a2'] == BLU, 'the first track ramps fully')
  check(m['a3'] == RED and m['a4'] == BLU, 'and the second gets its own ramp')
end

do -- and the ramp does not depend on what other tracks hold
  local rs = ruleset{ item = { grad_rule{ mode = 'substring', pattern = 'a',
                                          gradient_scope = 'all' } } }
  local alone = planmap({ tr('T1'), item('a1', { on = 'T1' }),
                                    item('a2', { on = 'T1' }) }, rs,
                        { propagate_folders = 'off' })
  local crowd = planmap({ tr('T1'), tr('T2'),
                          item('a1', { on = 'T1' }), item('a2', { on = 'T1' }),
                          item('a3', { on = 'T2' }) }, rs,
                        { propagate_folders = 'off' })
  check(alone['a1'] == crowd['a1'] and alone['a2'] == crowd['a2'],
        'T1 colours the same either way',
        string.format('%06X/%06X vs %06X/%06X', alone['a1'], alone['a2'],
                      crowd['a1'], crowd['a2']))
  check(crowd['a3'] == RED, 'and a lone match elsewhere gets colour 1')
end

do -- scope is coerced to what each kind can actually use
  check(RU.new('track', { gradient_scope = 'folder' }).gradient_scope == 'folder',
        'tracks keep folder scope')
  check(RU.new('item', { gradient_scope = 'folder' }).gradient_scope == 'run',
        'items fall back to run -- folder ordering means nothing for them')
  check(RU.new('item', { gradient_scope = 'both' }).gradient_scope == 'run',
        'and so does "both"')
  check(RU.new('region', { gradient_scope = 'run' }).gradient_scope == 'run',
        'regions can be grouped into runs')
  check(RU.new('marker', { gradient_scope = 'run' }).gradient_scope == 'run',
        'and so can markers')
  check(RU.new('region', { gradient_scope = 'folder' }).gradient_scope == 'all',
        'but not by folder -- they have no folder structure')
  check(RU.new('region', {}).gradient_scope == 'all',
        'and they default to one ramp: a song\'s regions are interleaved, so ' ..
        'runs would leave every group with one member')
  check(RU.new('marker', {}).gradient_scope == 'all', 'markers likewise')
  check(RU.new('track', { gradient_scope = 'banana' }).gradient_scope == 'run',
        'an unknown value falls back to the default')
  check(RU.new('track', {}).gradient_scope == 'run', 'and so does a missing one')
end

do -- a folder-parents-only rule flattens ONLY when nothing reaches the children
  local r1 = RU.new('track', { pattern = 'drum', color2 = BLU,
                               gradient_scope = 'folder', only = 'folder' })
  local function warned(opts)
    for _, w in ipairs(RU.warnings(r1, opts)) do
      if w:find('alone in its group', 1, true) then return true end
    end
    return false
  end
  check(warned{ propagate_folders = 'off' },
        'warns when folder colours are off, so each parent really is alone')
  check(not warned{ propagate_folders = 'fill_unmatched' },
        'but not when the children inherit the rule and join its group')
  check(not warned{ propagate_folders = 'force' }, 'nor under force')

  -- 'force' used to collapse a folder gradient, because propagation copied a
  -- finished colour. It propagates the RULE now, so there is nothing to warn
  -- about and the warning is gone.
  local r2 = RU.new('track', { pattern = 'str', color2 = BLU,
                               gradient_scope = 'folder' })
  check(#RU.warnings(r2, { propagate_folders = 'force' }) == 0,
        'and forced folder colours no longer flatten a gradient')
  check(#RU.warnings(r2, { propagate_folders = 'fill_unmatched' }) == 0,
        'nor does the default folder policy')
end

do -- forcing folder colours ramps across the folder instead of flattening it
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'folder' } } }
  local m = planmap({ tr('Str1', { fd = 1 }), tr('Str2', { depth = 1 }),
                      tr('Str3', { fd = -1, depth = 1 }) }, rs,
                    { propagate_folders = 'force' })
  check(m['Str1'] == RED and m['Str3'] == BLU,
        'the parent and its children are one ramp, not one colour')
  check(m['Str2'] ~= RED and m['Str2'] ~= BLU, 'with the middle track between them')
end

do -- plan() reports where each match sits, for "why is it this colour?"
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'run' } } }
  local entries = { tr('Str1'), tr('Str2'), tr('Str3') }
  local _, _, _, _, _, grad = AP.plan(entries, rs, { propagate_folders = 'off' })
  check(grad[2] and grad[2].rank == 2 and grad[2].size == 3,
        'the middle track reports step 2 of 3',
        grad[2] and (grad[2].rank .. '/' .. grad[2].size))

  -- a flat rule reports nothing
  local flat = ruleset{ track = { { mode = 'substring', pattern = 'Str', color = RED } } }
  local _, _, _, _, _, g2 = AP.plan(entries, flat, { propagate_folders = 'off' })
  check(g2[1] == nil, 'a rule with no gradient reports no position')
end

do -- the hot and cold auto-loop sweeps must agree about track colours.
   -- The hot pass plans over tracks alone; the cold pass plans over the same
   -- tracks as CONTEXT plus items and markers. If grouping depended on items
   -- being present, or skipped context entries, the two would disagree and the
   -- colours would flicker between sweeps.
  local rs = ruleset{ track = { grad_rule{ mode = 'substring', pattern = 'Str',
                                           gradient_scope = 'run' } } }
  local tracks = { tr('Str1'), tr('Str2'), tr('Bus'), tr('Str3'), tr('Str4') }
  local hot = planmap(tracks, rs, { propagate_folders = 'off' })

  local cold = {}
  for _, t in ipairs({ 'Str1', 'Str2', 'Bus', 'Str3', 'Str4' }) do
    cold[#cold + 1] = tr(t, { context = true })
  end
  cold[#cold + 1] = item('x', { on = 'Str1' })
  cold[#cold + 1] = region('R1')
  local _, _, desired = AP.plan(cold, rs, { propagate_folders = 'off' })

  local same = true
  for i, e in ipairs(cold) do
    if e.kind == 'track' and hot[e.name] ~= nil and desired[i] ~= hot[e.name] then
      same = false
    end
  end
  check(same, 'the hot and cold sweeps compute identical track colours')
end

-- folder propagation
local function folderset()
  return { tr('Drums', { fd = 1 }), tr('Kick'), tr('Snare', { fd = -1 }), tr('Vox') }
end
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Drums', color = RED } } }
  local m = planmap(folderset(), rs, { propagate_folders = 'fill_unmatched' })
  check(m['Drums'] == RED, 'folder keeps its own colour')
  check(m['Kick']  == RED, 'unmatched child inherits the folder colour')
  check(m['Vox']   == nil, 'a track after the folder closes does not inherit')
end
do
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'Kick',  color = GRN },
    { mode = 'substring', pattern = 'Drums', color = RED },
  } }
  check(planmap(folderset(), rs, { propagate_folders = 'fill_unmatched' })['Kick'] == GRN,
        'a child with its own rule keeps its colour')
  check(planmap(folderset(), rs, { propagate_folders = 'force' })['Kick'] == RED,
        'force overrides a matched child')
  check(planmap(folderset(), rs, { propagate_folders = 'off' })['Snare'] == nil,
        'off does not inherit at all')
end
do -- one track closing several folder levels at once
  local entries = { tr('Outer', { fd = 1 }), tr('Inner', { fd = 1 }),
                    tr('Leaf', { fd = -2 }), tr('After') }
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Outer', color = RED } } }
  local m = planmap(entries, rs, { propagate_folders = 'fill_unmatched' })
  check(m['Inner'] == RED, 'nested folder inherits')
  check(m['After'] == nil, 'a -2 close pops both levels')
end

--------------------------------------------- track -> item cascade
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Bass', color = RED,
                                  cascade_items = true } } }
  local entries = { tr('Bass'), item('take_01', { on = 'Bass' }),
                    item('whatever', { on = 'Bass' }) }
  local m = planmap(entries, rs, { propagate_folders = 'off' })
  check(m['Bass'] == RED,      'the track is coloured')
  check(m['take_01'] == RED,   'and so are its items, whatever they are called')
  check(m['whatever'] == RED,  'every item on that track')
end
do -- cascade off: items untouched
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Bass', color = RED,
                                  cascade_items = false } } }
  local m = planmap({ tr('Bass'), item('take_01', { on = 'Bass' }) }, rs,
                    { propagate_folders = 'off' })
  check(m['Bass'] == RED,    'the track is still coloured')
  check(m['take_01'] == nil, 'but its items are not')
end
do -- an item rule OVERRIDES the cascade
  local rs = ruleset{
    track = { { mode = 'substring', pattern = 'Bass', color = RED, cascade_items = true } },
    item  = { { mode = 'glob', pattern = '*comp*', color = GRN } },
  }
  local entries = { tr('Bass'), item('bass_comp_1', { on = 'Bass' }),
                    item('bass_raw', { on = 'Bass' }) }
  local m = planmap(entries, rs, { propagate_folders = 'off' })
  check(m['bass_comp_1'] == GRN, 'an item rule beats the track cascade')
  check(m['bass_raw'] == RED,    'items with no item rule still cascade')
end
do -- items on OTHER tracks are unaffected
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Bass', color = RED,
                                  cascade_items = true } } }
  local m = planmap({ tr('Bass'), tr('Gtr'), item('a', { on = 'Bass' }),
                      item('b', { on = 'Gtr' }) }, rs, { propagate_folders = 'off' })
  check(m['a'] == RED, 'items on the matched track cascade')
  check(m['b'] == nil, 'items on another track do not')
end
do -- the cascade flag flows down a folder with the colour
  local entries = { tr('Drums', { fd = 1 }), tr('Kick'), tr('Snare', { fd = -1 }),
                    item('k1', { on = 'Kick' }), item('s1', { on = 'Snare' }) }
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Drums', color = RED,
                                  cascade_items = true } } }
  local m = planmap(entries, rs, { propagate_folders = 'fill_unmatched' })
  check(m['Kick'] == RED, 'the child track inherits the folder colour')
  check(m['k1'] == RED,   'and items on that child cascade too')
  check(m['s1'] == RED,   'for every child')
end
do -- a cascading track under a NON-cascading folder
  local entries = { tr('Drums', { fd = 1 }), tr('Kick', { fd = -1 }),
                    item('k1', { on = 'Kick' }) }
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'Kick',  color = GRN, cascade_items = true },
    { mode = 'substring', pattern = 'Drums', color = RED, cascade_items = false },
  } }
  local m = planmap(entries, rs, { propagate_folders = 'fill_unmatched' })
  check(m['Kick'] == GRN, 'the child keeps its own rule colour')
  check(m['k1'] == GRN,   'and cascades its own colour to its items')
end

---------------------------------------------------- context entries
-- Context entries take part in propagation and cascade but are never written.
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Drums', color = RED,
                                  cascade_items = true } } }
  local entries = { tr('Drums', { fd = 1, context = true }),
                    tr('Kick', { fd = -1, context = true }),
                    item('k1', { on = 'Kick' }) }
  local ops, stats = AP.plan(entries, rs, { propagate_folders = 'fill_unmatched' })
  check(#ops == 1, 'only the non-context entry produces an op', #ops .. ' ops')
  check(ops[1].entry.name == 'k1', 'and it is the item')
  check(ops[1].rgb == RED, 'which got its colour through the context tracks')
  check(stats.scanned == 1, 'context entries are not counted as scanned')
end

-- a broken pattern must not break the sweep
do
  local rs = ruleset{ track = {
    { mode = 'regex', pattern = '(unclosed', color = RED },
    { mode = 'substring', pattern = 'Bass', color = BLU },
  } }
  check(planmap({ tr('Bass') }, rs)['Bass'] == BLU,
        'a rule that will not compile is skipped, not fatal')
end

-- tally
do
  local rs = ruleset{ track = {
    { mode = 'substring', pattern = 'a', color = RED },
    { mode = 'substring', pattern = 'a', color = BLU },
  } }
  local r1, r2 = rs.track[1], rs.track[2]
  local won, shadowed = AP.tally({ tr('aaa'), tr('abc'), tr('zzz') }, rs)
  check(won[r1.id] == 2,      'tally counts what the first rule wins')
  check(won[r2.id] == 0,      'the shadowed rule wins nothing')
  check(shadowed[r2.id] == 2, 'tally reports how many it was shadowed on')
end

-- clearing
do
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'bass', color = RED } } }
  local entries = { tr('Bass', { color = RED }), tr('Other', { color = GRN }), tr('Plain') }
  check(#AP.plan_clear(entries, rs, 'matched') == 1,
        'clear "matched" only touches what the rules claim')
  check(#AP.plan_clear(entries, rs, 'all') == 2,
        'clear "all" touches every coloured object')
end
do -- an item coloured by a TRACK cascade is claimed by the rules too, so
   -- "clear what the rules match" must release it
  local rs = ruleset{ track = { { mode = 'substring', pattern = 'Bass', color = RED,
                                  cascade_items = true } } }
  local entries = { tr('Bass', { color = RED }),
                    item('anything', { on = 'Bass', color = RED }) }
  local ops = AP.plan_clear(entries, rs, 'matched', { propagate_folders = 'off' })
  local kinds = {}
  for _, op in ipairs(ops) do kinds[op.entry.kind] = true end
  check(kinds.item == true, 'a cascaded item is cleared by "what the rules match"')
  check(#ops == 2, 'along with its track', #ops .. ' ops')
end

------------------------------------------------------------------- report
local lines = {}
lines[#lines + 1] = ''
lines[#lines + 1] = '=== AutoColor regex tests ==='
if fail > 0 then
  for _, f in ipairs(failures) do
    lines[#lines + 1] = '  FAIL  ' .. f
  end
end
lines[#lines + 1] = string.format('%d passed, %d failed', pass, fail)
lines[#lines + 1] = ''
out(table.concat(lines, '\n'))

if not IN_REAPER then os.exit(fail == 0 and 0 or 1) end
