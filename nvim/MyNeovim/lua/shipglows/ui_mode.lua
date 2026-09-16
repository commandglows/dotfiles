local M = {}

local bg = "#1F1F28"
local fg = "#C8C093"
local dim = "#6C6C7A"

local function clamp(v, lo, hi)
  return math.min(hi, math.max(lo, v))
end

local function hex_to_rgb(hex)
  local s = hex
  if s:sub(1, 1) == "#" then
    s = s:sub(2)
  end
  return tonumber(s:sub(1, 2), 16) / 255, tonumber(s:sub(3, 4), 16) / 255, tonumber(s:sub(5, 6), 16) / 255
end

local function rgb_to_hsl(r, g, b)
  local max = math.max(r, g, b)
  local min = math.min(r, g, b)
  local h, s
  local l = (max + min) / 2
  if max == min then
    h, s = 0, 0
  else
    local d = max - min
    s = l > 0.5 and (d / (2 - max - min)) or (d / (max + min))
    if max == r then
      h = (g - b) / d + (g < b and 6 or 0)
    elseif max == g then
      h = (b - r) / d + 2
    else
      h = (r - g) / d + 4
    end
    h = h / 6
  end
  return h, s, l
end

local function hsl_to_rgb(h, s, l)
  if s == 0 then
    return l, l, l
  end
  local function hue2rgb(p, q, t)
    if t < 0 then
      t = t + 1
    end
    if t > 1 then
      t = t - 1
    end
    if t < 1 / 6 then
      return p + (q - p) * 6 * t
    end
    if t < 1 / 2 then
      return q
    end
    if t < 2 / 3 then
      return p + (q - p) * (2 / 3 - t) * 6
    end
    return p
  end
  local q = l < 0.5 and (l * (1 + s)) or (l + s - l * s)
  local p = 2 * l - q
  return hue2rgb(p, q, h + 1 / 3), hue2rgb(p, q, h), hue2rgb(p, q, h - 1 / 3)
end

local function rescale(hex, l, s)
  local r, g, b = hex_to_rgb(hex)
  local h = select(1, rgb_to_hsl(r, g, b))
  local nr, ng, nb = hsl_to_rgb(h, s, l)
  local function ch(c)
    return string.format("%02X", math.floor(clamp(c, 0, 1) * 255 + 0.5))
  end
  return "#" .. ch(nr) .. ch(ng) .. ch(nb)
end

local function build_scale(base)
  local r, g, b = hex_to_rgb(base)
  local _, base_s, base_l = rgb_to_hsl(r, g, b)
  return {
    accent = base,
    bright = rescale(base, clamp(base_l + 0.12, 0, 0.85), base_s),
    mid = rescale(base, clamp(base_l * 0.45, 0.16, 0.32), clamp(base_s + 0.10, 0, 0.60)),
    dark = rescale(base, 0.16, math.min(base_s, 0.50)),
    deep = rescale(base, 0.11, math.min(base_s, 0.42)),
  }
end

local bases = {
  NORMAL = "#9CABCA",
  INSERT = "#6A9589",
  VISUAL = "#FFA066",
  REPLACE = "#E46876",
}

M.scales = {}
for key, base in pairs(bases) do
  M.scales[key] = build_scale(base)
end

local function resolve_mode()
  local m = vim.api.nvim_get_mode().mode
  local c = m:sub(1, 1)
  if c == "R" then
    return "REPLACE"
  end
  if c == "i" then
    return "INSERT"
  end
  if c == "v" or c == "V" then
    return "VISUAL"
  end
  return "NORMAL"
end

M.mode_key = resolve_mode

local function apply_mode_colors(key)
  local s = M.scales[key or resolve_mode()]
  vim.api.nvim_set_hl(0, "CursorLine", { bg = s.deep })
  vim.api.nvim_set_hl(0, "NormalFloat", { bg = s.dark })
  vim.api.nvim_set_hl(0, "FloatBorder", { bg = s.dark, fg = s.mid })
  vim.api.nvim_set_hl(0, "WinBar", { bg = s.dark, fg = s.mid })
  vim.api.nvim_set_hl(0, "WinBarNC", { bg = s.deep, fg = dim })
  vim.api.nvim_set_hl(0, "CursorLineNr", { fg = s.mid })
  vim.api.nvim_set_hl(0, "Cursor", { fg = bg, bg = s.bright })
  vim.api.nvim_set_hl(0, "CursorIM", { fg = bg, bg = s.bright })
end

M.apply_mode_colors = apply_mode_colors

local function lualine_sections(s)
  return {
    a = { fg = bg, bg = s.accent, gui = "bold" },
    b = { fg = fg, bg = s.dark },
    c = { fg = fg, bg = s.dark },
    x = { fg = fg, bg = s.dark },
    y = { fg = fg, bg = s.dark },
    z = { fg = bg, bg = s.accent, gui = "bold" },
  }
end

local function inactive_lualine()
  return {
    a = { fg = dim, bg = bg },
    b = { fg = dim, bg = bg },
    c = { fg = dim, bg = bg },
    x = { fg = dim, bg = bg },
    y = { fg = dim, bg = bg },
    z = { fg = dim, bg = bg },
  }
end

function M.lualine_theme()
  return {
    normal = lualine_sections(M.scales.NORMAL),
    insert = lualine_sections(M.scales.INSERT),
    visual = lualine_sections(M.scales.VISUAL),
    replace = lualine_sections(M.scales.REPLACE),
    command = lualine_sections(M.scales.NORMAL),
    inactive = inactive_lualine(),
  }
end

return M