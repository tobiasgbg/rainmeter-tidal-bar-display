-- Character-based marquee for the TIDAL title.
-- Slides a fixed-width window of text through the (looping) title + a gap.
-- If the title fits, it's shown in full. Sets [MeterTitle]'s Text each tick.
function Initialize()
  pos = 0
end

function Update()
  local m = SKIN:GetMeasure('mTitle')
  local t = ''
  if m ~= nil then local v = m:GetStringValue(); if v ~= nil then t = v end end
  local win = tonumber(SKIN:GetVariable('Window')) or 30
  local out
  if string.len(t) <= win then
    pos = 0
    out = t
  else
    local s = t .. '       '          -- gap before it loops around
    local d = s .. s                  -- doubled so the window wraps seamlessly
    out = string.sub(d, pos + 1, pos + win)
    pos = pos + 1
    if pos >= string.len(s) then pos = 0 end
  end
  SKIN:Bang('!SetOption', 'MeterTitle', 'Text', out)
  return 0
end
