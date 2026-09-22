--[[
  swsimport.lua -- read SWS Auto Color's rule list and turn it into ours.

  Why this is worth having: SWS matches with `stristr` -- case-insensitive plain
  substring -- and applies the FIRST rule that matches. That is exactly one point
  in this tool's matcher space (mode='substring', ci=true) with exactly this
  tool's precedence, so an ordinary SWS name rule crosses over faithfully rather
  than approximately. Nothing is guessed at; see docs/RESEARCH.md for the format,
  read out of SWS 2.14.0 build 7 rather than from documentation.

  The shape of the file (one section, [SWS]):

      AutoColor 1=0 "(MIDI input)" 50331644 "" "" ""
      AutoColorCount=2

  Tokens are  type filter color icon tcp_layout mcp_layout,  written by
  AutoColorSaveState with "%d %s %d %s %s %s". A legacy three-token form
  (filter color icon, implicitly a track rule) is still accepted by SWS, and the
  TOKEN COUNT is the only thing that tells the two apart -- which is why the
  tokenizer has to emit empty tokens rather than skipping them.

  Everything here is pure except paths() and read(). That is deliberate: the
  whole mapping is then exercised by the unit suite, which runs with no `reaper`
  table at all. The one thing that genuinely needs the host is decoding a legacy
  OS-native colour, and that arrives as opts.native_to_rgb.

  NOTE ON COLOURS -- do not route these through colors.lua. colors.norm masks
  0x1FFFFFF, which drops SWS's portable flag and folds the negative sentinels
  into large positives, so every "random"/"parent"/"ignore" rule would read as a
  real colour. colors.from_native additionally returns nil for 0, which would
  turn SWS's black into "no colour". The decode below is self-contained for
  those two reasons.
]]

local rulesmod = require 'rules'
local config   = require 'config'

local M = {}

M.SOURCE = 'sws-autocoloricon.ini'
M.SECTION = 'SWS'

-- SWS's own constant. Set on every colour it has written since the format went
-- cross-platform; its absence means the value is in the host's native byte
-- order and predates that.
local PORTABLE_FLAG = 0x2000000

-- Negative colours are sentinels, stored as -1 - index into SWS's colour-type
-- enum { CUSTOM, GRADIENT, RANDOM, NONE, PARENT, IGNORE }.
local SENTINEL = {
  [-1] = 'custom',
  [-2] = 'gradient',
  [-3] = 'random',
  [-4] = 'none',
  [-5] = 'parent',
  [-6] = 'ignore',
}

-- SWS compares these with strcmp, so the match is exact and case-sensitive:
-- "(ANY)" is a literal substring filter over there and must stay one here.
--
-- The four we can express map onto a predicate with an empty pattern.
-- predicates.lua NARROWS a pattern where SWS's keyword REPLACES it, so an empty
-- pattern is the faithful translation, not a shortcut.
local FILTER_PREDICATE = {
  ['(any)']      = false,        -- expressible, but needs no predicate
  ['(unnamed)']  = 'unnamed',
  ['(folder)']   = 'folder',
  ['(children)'] = 'children',
}

-- Track properties we have no equivalent for. '(master)' is here for a reason
-- of its own: REAPER ignores a custom colour on the master track, so the filter
-- never did anything visible -- the same finding already recorded at
-- rules.lua's legacy `only == 'master'` branch.
local FILTER_UNSUPPORTED = {
  ['(master)']       = true,
  ['(receive)']      = true,
  ['(record armed)'] = true,
  ['(vca master)']   = true,
  ['(instrument)']   = true,
  ['(audio input)']  = true,
  ['(audio output)'] = true,
  ['(MIDI input)']   = true,
  ['(MIDI output)']  = true,
}

local KIND_OF_TYPE = { [0] = 'track', [1] = 'marker', [2] = 'region' }

-- What each unsupported aspect says in the rule's NAME. The name, not the note:
-- the rule list renders `label` and never renders `note`, so a note alone would
-- be an explanation nobody can read.
local WHY = {
  nofilter = '[SWS: this rule had no filter]',
  custom   = '[SWS: custom colour cycling is not supported]',
  random   = '[SWS: random colours are not supported]',
  none     = '[SWS: "none" -- clearing the colour -- is not supported]',
  parent   = '[SWS: the parent\'s colour is not supported]',
  -- The long one earns its length: losing "ignore" is the only one of these
  -- that silently changes which OTHER rule wins. The rest merely fail to
  -- colour something.
  ignore   = '[SWS: "ignore" is not supported -- in SWS it also stopped later rules]',
}

local function why_filter(keyword)
  return '[SWS: the ' .. keyword .. ' filter is not supported]'
end

-------------------------------------------------------------------- tokenizer
--- Split one config line the way WDL's LineParser does.
---
--- Quoting comes from makeEscapedConfigString with prefer_quoteless=true: a
--- value goes out bare when it holds no whitespace and does not open with a
--- quote character, '#' or ';'. That is why "(any)" is bare in the file while
--- "(MIDI input)" is quoted -- assuming quotes is the obvious way to get this
--- wrong. There is nothing to unescape: the writer picks a quote character the
--- value does not contain rather than escaping one that it does.
---
--- Empty tokens ARE emitted. `0 "(x)" 5 "" "" ""` must come back as six, since
--- the count is what separates the modern record from the legacy one.
--- @return list of strings
function M.tokenize(line)
  local out = {}
  if type(line) ~= 'string' then return out end
  local i, n = 1, #line

  while i <= n do
    -- skip separators
    while i <= n do
      local c = line:sub(i, i)
      if c == ' ' or c == '\t' then i = i + 1 else break end
    end
    if i > n then break end

    local c = line:sub(i, i)
    if c == ';' or c == '#' then
      -- Comment, but only where a token would have started: `a;b` is one token
      -- over there, so it must be one here too.
      break
    elseif c == '"' or c == "'" or c == '`' then
      local close = line:find(c, i + 1, true)
      if close then
        out[#out + 1] = line:sub(i + 1, close - 1)
        i = close + 1
      else
        -- Unterminated: WDL runs it to the end of the line rather than failing.
        out[#out + 1] = line:sub(i + 1)
        i = n + 1
      end
    else
      local j = i
      while j <= n do
        local cc = line:sub(j, j)
        if cc == ' ' or cc == '\t' then break end
        j = j + 1
      end
      out[#out + 1] = line:sub(i, j - 1)
      i = j
    end
  end

  return out
end

------------------------------------------------------------------- ini reader
--- Parse a REAPER-style ini into { [section] = { [key] = value } }.
---
--- Deliberately blunt, and two details are load-bearing:
---   * a trailing \r is stripped, or an ini carried over from a Windows install
---     makes tonumber('2\r') nil and the whole import silently finds no rules;
---   * the split is at the FIRST '=', because a filter can contain one and a
---     key never does.
function M.ini(text)
  local out = {}
  if type(text) ~= 'string' then return out end
  local section = nil

  for raw in (text .. '\n'):gmatch('(.-)\n') do
    local line = raw:gsub('\r$', '')
    local sec = line:match('^%s*%[(.-)%]%s*$')
    if sec then
      section = sec
      out[section] = out[section] or {}
    elseif section then
      local eq = line:find('=', 1, true)
      if eq then
        -- Keys keep their case and their embedded space ("AutoColor 1").
        local key = line:sub(1, eq - 1):gsub('^%s+', ''):gsub('%s+$', '')
        if key ~= '' then out[section][key] = line:sub(eq + 1) end
      end
    end
  end

  return out
end

----------------------------------------------------------------------- colour
--- Decode one stored SWS colour.
--- @return what  'rgb' or one of the six sentinel names
--- @return rgb   0xRRGGBB when what == 'rgb', otherwise nil
function M.decode_color(n, opts)
  if type(n) ~= 'number' then return 'rgb', 0 end
  n = math.floor(n)

  if n < 0 then
    return SENTINEL[n] or 'custom', nil
  end
  -- 0 is BLACK, not "no colour". Handing it to colors.from_native, which
  -- answers nil there, would quietly turn every black SWS rule grey.
  if n & PORTABLE_FLAG ~= 0 then
    return 'rgb', n & 0xFFFFFF
  end

  -- No portable flag: written before the format was portable, so it is in the
  -- byte order of whichever machine wrote it -- and nothing in the file says
  -- which. Decoding through the host is exactly what SWS itself does, so this
  -- inherits SWS's limitation rather than inventing a new one.
  local native = n & 0xFFFFFF
  local conv = opts and opts.native_to_rgb
  if conv then return 'rgb', conv(native) & 0xFFFFFF end
  return 'rgb', native
end

--- SWS's gradient endpoints, which live in reaper.ini rather than beside the
--- rules. Absent, malformed or sentinel values fall back to SWS's own default.
--- @return start_rgb, end_rgb
function M.gradient_ends(reaper_ini_text, opts)
  local DEF_A, DEF_B = 0x000000, 0xFFFFFF
  local ini = M.ini(reaper_ini_text)
  local sws = ini[M.SECTION]
  if not sws or not sws.ColorGradients then return DEF_A, DEF_B end

  local tok = M.tokenize(sws.ColorGradients)
  if #tok < 2 then return DEF_A, DEF_B end

  local wa, a = M.decode_color(tonumber(tok[1]), opts)
  local wb, b = M.decode_color(tonumber(tok[2]), opts)
  if wa ~= 'rgb' or wb ~= 'rgb' then return DEF_A, DEF_B end
  return a, b
end

------------------------------------------------------------------------ parse
local function append_reason(label, why)
  return (label ~= '' and (label .. ' ' .. why)) or why
end

--- Turn one `AutoColor n=` value into a rule, or nil when it cannot be one.
--- @return rule, kind  or  nil
local function convert_line(value, index, grad_a, grad_b, opts)
  local tok = M.tokenize(value)
  local typ, filter, colnum

  if #tok >= 4 then
    typ    = tonumber(tok[1])
    filter = tok[2]
    colnum = tonumber(tok[3])
  elseif #tok == 3 then
    -- Legacy: filter color icon, always a track rule.
    typ    = 0
    filter = tok[1]
    colnum = tonumber(tok[2])
  else
    return nil
  end

  if typ == nil or colnum == nil then return nil end
  local kind = KIND_OF_TYPE[math.floor(typ)]
  if not kind then return nil end

  -- ------------------------------------------------------------ the filter
  local label, pattern, only, enabled = filter, filter, nil, true

  if filter == '' then
    label, pattern = '(no filter)', ''
    enabled = false
    label = append_reason(label, WHY.nofilter)
  elseif FILTER_UNSUPPORTED[filter] then
    -- The keyword is kept AS THE PATTERN rather than emptied. An empty pattern
    -- with no predicate matches every object (rules.warnings says so in as many
    -- words), so a user re-enabling this out of curiosity would repaint the
    -- whole project. "(MIDI input)" as a substring matches nothing, which is
    -- the safe inert state, and it still shows what the rule used to be.
    enabled = false
    label = append_reason(label, why_filter(filter))
  else
    local pred = FILTER_PREDICATE[filter]
    if pred ~= nil then
      pattern = ''
      only = pred or nil
      -- A predicate that cannot apply to this kind is dropped by
      -- rules.normalize; markers and regions only ever carry (any)/(unnamed),
      -- both of which are fine everywhere.
    end
  end

  -- ------------------------------------------------------------ the colour
  local what, rgb = M.decode_color(colnum, opts)
  local color, color2, scope = nil, nil, nil

  if what == 'rgb' then
    color = rgb
  elseif what == 'gradient' then
    -- The one sentinel that translates exactly. SWS ramps its global
    -- ColorGradients across every track THAT rule matched, in track order;
    -- gradient_scope='all' is "one ramp across every match in the project",
    -- and first-match-wins on both sides makes "matched" and "won" the same
    -- set. So this imports enabled, with nothing appended to its name.
    color, color2, scope = grad_a, grad_b, 'all'
  else
    enabled = false
    label = append_reason(label, WHY[what])
  end

  local rule = rulesmod.new(kind, {
    label    = label,
    enabled  = enabled,
    mode     = 'substring',      -- SWS's stristr, exactly
    ci       = true,
    invert   = false,
    pattern  = pattern,
    only     = only,
    color    = color,
    color2   = color2,
    gradient_scope = scope,
    note     = 'imported from SWS Auto Color rule ' .. index .. ': ' .. value,
  })

  return rule, kind
end

--- Convert a whole SWS ini.
--- @param sws_text        contents of sws-autocoloricon.ini
--- @param reaper_ini_text contents of reaper.ini, for the gradient endpoints
--- @param opts            { native_to_rgb = function(v) -> rgb }
--- @return result table -- see the module header
function M.parse(sws_text, reaper_ini_text, opts)
  local res = {
    rules    = config.empty_rules(),
    count    = 0,
    imported = 0,
    disabled = 0,
    skipped  = 0,
    enabled_in_sws = {},
  }

  local ini = M.ini(sws_text)
  local sws = ini[M.SECTION]
  if not sws then return res end

  for _, key in ipairs({ 'AutoColorEnable', 'AutoColorMarkerEnable',
                         'AutoColorRegionEnable' }) do
    if tonumber(sws[key]) == 1 then
      res.enabled_in_sws[#res.enabled_in_sws + 1] = key
    end
  end

  local count = tonumber(sws.AutoColorCount)
  if not count then
    -- Hand-edited file with the count dropped: take the highest index present
    -- rather than giving up on rules that are plainly there.
    count = 0
    for k in pairs(sws) do
      local n = k:match('^AutoColor (%d+)$')
      if n then count = math.max(count, tonumber(n)) end
    end
  end
  count = math.floor(count)
  if count <= 0 then return res end
  res.count = count

  local grad_a, grad_b = M.gradient_ends(reaper_ini_text, opts)
  res.gradient = { grad_a, grad_b }

  -- Iterate by index, never by walking the table: the order of `AutoColor n` is
  -- the PRIORITY order, and a Lua hash has none to give back.
  for i = 1, count do
    local value = sws['AutoColor ' .. i]
    local rule, kind = nil, nil
    if value then rule, kind = convert_line(value, i, grad_a, grad_b, opts) end

    if rule then
      local list = res.rules[kind]
      list[#list + 1] = rule
      res.imported = res.imported + 1
      if not rule.enabled then res.disabled = res.disabled + 1 end
    else
      res.skipped = res.skipped + 1
    end
  end

  return res
end

------------------------------------------------------------------------ merge
--- Fold a parse result into a config's rule lists.
--- @param mode 'append' or 'replace'
--- @return counts per kind
function M.merge(cfg, res, mode)
  local counts = {}
  -- Nothing to import changes nothing. In particular a Replace against an
  -- empty or missing SWS file must not empty the user's rule set.
  if not res or res.imported == 0 then return counts end

  if mode == 'replace' then cfg.rules = config.empty_rules() end

  for _, kind in ipairs(rulesmod.KINDS) do
    local src = res.rules[kind] or {}
    local dst = cfg.rules[kind]
    -- Appended at the END. The user's own rules are the ones they tuned, and
    -- an SWS "(any)" catch-all arriving above them would repaint the project
    -- on the next auto tick. The SWS rules keep their order among themselves,
    -- so their internal precedence survives intact.
    for _, r in ipairs(src) do dst[#dst + 1] = r end
    counts[kind] = #src
  end

  return counts
end

------------------------------------------------------------------ file access
--- @return sws_path, reaper_ini_path -- nil outside REAPER
function M.paths()
  if type(reaper) ~= 'table' or not reaper.GetResourcePath then return nil end
  local res = reaper.GetResourcePath()
  return res .. '/' .. M.SOURCE, res .. '/reaper.ini'
end

local function slurp(path)
  if not path then return nil end
  local f = io.open(path, 'r')
  if not f then return nil end
  local text = f:read('a')
  f:close()
  return text
end

--- @return sws_text, reaper_ini_text -- either may be nil
function M.read(sws_path, reaper_ini_path)
  return slurp(sws_path), slurp(reaper_ini_path)
end

return M
