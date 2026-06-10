-- Character-based marquee for the TIDAL title (UTF-8 aware).
-- Slides a fixed-width window of text through the (looping) title + a gap.
-- If the title fits, it's shown in full. Sets [MeterTitle]'s Text each tick.
-- Counts and slices by whole UTF-8 characters so multi-byte scripts
-- (Korean/Hangul, Swedish a-ring/o-umlaut, etc.) don't get split mid-character.
function Initialize()
  pos = 0
end

-- Split a UTF-8 byte string into a table of whole characters.
function Utf8Chars(s)
  local chars = {}
  local i = 1
  local n = string.len(s)
  while i <= n do
    local b = string.byte(s, i)
    local len = 1
    if     b >= 240 then len = 4   -- 11110xxx
    elseif b >= 224 then len = 3   -- 1110xxxx
    elseif b >= 192 then len = 2   -- 110xxxxx
    end                            -- else ASCII / continuation -> 1
    chars[#chars + 1] = string.sub(s, i, i + len - 1)
    i = i + len
  end
  return chars
end

function Update()
  local m = SKIN:GetMeasure('mTitle')
  local t = ''
  if m ~= nil then local v = m:GetStringValue(); if v ~= nil then t = v end end
  local win = tonumber(SKIN:GetVariable('Window')) or 30

  local chars = Utf8Chars(t)
  local count = #chars
  local out
  if count <= win then
    pos = 0
    out = t
  else
    -- s = title + 7-space gap (as chars); doubled so the window wraps seamlessly
    local s = {}
    for _, c in ipairs(chars) do s[#s + 1] = c end
    for _ = 1, 7 do s[#s + 1] = ' ' end
    local slen = #s
    local d = {}
    for _, c in ipairs(s) do d[#d + 1] = c end
    for _, c in ipairs(s) do d[#d + 1] = c end

    local parts = {}
    for k = pos + 1, pos + win do parts[#parts + 1] = d[k] end
    out = table.concat(parts)

    pos = pos + 1
    if pos >= slen then pos = 0 end
  end
  SKIN:Bang('!SetOption', 'MeterTitle', 'Text', out)
  return 0
end
