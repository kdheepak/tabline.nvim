local M = {}

M.options = {
  no_name = '[No Name]',
  component_left = '',
  component_right = '',
  section_left = '',
  section_right = '',
}
M.total_tab_length = 6

-- Use luatab as reference:
-- https://github.com/alvarosevilla95/luatab.nvim

function M.highlight(name, foreground, background, gui)
  local command = { 'highlight', name }
  if foreground and foreground ~= 'none' then
    table.insert(command, 'guifg=' .. foreground)
  end
  if background and background ~= 'none' then
    table.insert(command, 'guibg=' .. background)
  end
  if gui and gui ~= 'none' then
    table.insert(command, 'gui=' .. gui)
  end
  vim.cmd(table.concat(command, ' '))
end

function M.create_component_highlight_group(color, highlight_tag)
  if color.bg and color.fg then
    local highlight_group_name = table.concat({ 'tabline', highlight_tag }, '_')
    M.highlight(highlight_group_name, color.fg, color.bg, color.gui)
    return highlight_group_name
  end
end

function M.extract_highlight_colors(color_group, scope)
  if vim.fn.hlexists(color_group) == 0 then
    return nil
  end
  local color = vim.api.nvim_get_hl_by_name(color_group, true)
  if color.background ~= nil then
    color.bg = string.format('#%06x', color.background)
    color.background = nil
  end
  if color.foreground ~= nil then
    color.fg = string.format('#%06x', color.foreground)
    color.foreground = nil
  end
  if scope then
    return color[scope]
  end
  return color
end

local TabNames = {}
_G.TabNames = TabNames
M.TabNames = TabNames

local Tab = {}

function Tab:new(tab)
  assert(tab.tabnr, 'Cannot create Tab without tabnr')
  local newObj = { tabnr = tab.tabnr, options = tab.options }
  if newObj.options == nil then
    newObj.options = M.options
  end
  self.__index = self -- 4.
  newObj = setmetatable(newObj, self)
  newObj:get_props()
  return newObj
end

function Tab:get_props()
  self.name = (TabNames[self.tabnr] or (self.tabnr)) .. ' '
  return self
end

function M.tab_rename(name)
  TabNames[vim.fn.tabpagenr()] = name
  vim.cmd([[redrawtabline]])
end

function Tab:render()
  local line = ''
  line = line .. self:separator() .. self:hl() .. '%' .. self.tabnr .. '@TablineSwitchTab@' .. ' ' .. self.name .. '%T'
  return line
end

function Tab:separator()
  local hl = ''
  if self.current and self.first then
    hl = '%#tabline_a_to_c#' .. self.options.section_right
  elseif self.first then
    hl = '%#tabline_b_to_c#' .. self.options.section_right
  elseif self.aftercurrent then
    hl = '%#tabline_b_to_a#' .. self.options.section_right
  elseif self.current then
    hl = '%#tabline_a_to_b#' .. self.options.section_right
  else
    hl = '%#tabline_a_to_b#' .. self.options.component_right
  end
  return hl
end

function Tab:hl()
  if self.current then
    return '%#tabline_a_normal#'
  else
    return '%#tabline_b_normal#'
  end
end

function Tab:len()
  local margin = 1
  return vim.fn.strchars(' ' .. self.name) + margin
end

function M.format_tabs(tabs, max_length)
  if max_length == nil then
    max_length = math.floor(vim.o.columns / 2)
  end

  local line = ''
  local total_length = 0
  local current
  for i, tab in pairs(tabs) do
    if tab.current then
      current = i
    end
  end
  local current_tab = tabs[current]
  if current_tab == nil then
    local t = Tab:new{ tabnr = vim.fn.tabpagenr() }
    t.current = true
    t.last = true
    return t:render()
  end
  line = line .. current_tab:render()
  total_length = current_tab:len()
  local i = 0
  local before, after
  while true do
    i = i + 1
    before = tabs[current - i]
    after = tabs[current + i]
    if before == nil and after == nil then
      break
    end
    if before then
      total_length = total_length + before:len()
    end
    if after then
      total_length = total_length + after:len()
    end
    if total_length > max_length then
      break
    end
    if before then
      line = before:render() .. line
    end
    if after then
      line = line .. after:render()
    end
  end
  if total_length > max_length then
    if before ~= nil then
      line = '%#tabline_b_to_c#' .. M.options.section_right .. '%#tabline_b_normal#' .. '...' .. line
    end
    if after ~= nil then
      line = line .. '%#tabline_a_to_b#' .. M.options.component_right .. '%#tabline_b_normal#' .. '...'
    end
  end
  M.total_tab_length = total_length
  return line
end

local Buffer = {}

function Buffer:new(buffer)
  assert(buffer.bufnr, 'Cannot create Buffer without bufnr')
  local newObj = { bufnr = buffer.bufnr, options = buffer.options }
  if newObj.options == nil then
    newObj.options = M.options
  end
  self.__index = self -- 4.
  newObj = setmetatable(newObj, self)
  newObj:get_props()
  return newObj
end

function Buffer:get_props()
  self.file = vim.fn.bufname(self.bufnr)
  self.buftype = vim.fn.getbufvar(self.bufnr, '&buftype')
  self.filetype = vim.fn.getbufvar(self.bufnr, '&filetype')
  self.modified = vim.fn.getbufvar(self.bufnr, '&modified') == 1 and '[+] ' or ''
  self.visible = vim.fn.bufwinid(self.bufnr) ~= -1
  local dev, devhl
  if self.filetype == 'TelescopePrompt' then
    dev, devhl = require'nvim-web-devicons'.get_icon('telescope')
  elseif self.filetype == 'fugitive' then
    dev, devhl = require'nvim-web-devicons'.get_icon('git')
  elseif self.filetype == 'vimwiki' then
    dev, devhl = require'nvim-web-devicons'.get_icon('markdown')
  elseif self.buftype == 'terminal' then
    dev, devhl = require'nvim-web-devicons'.get_icon('zsh')
  else
    dev, devhl = require'nvim-web-devicons'.get_icon(self.file, vim.fn.expand('#' .. self.bufnr .. ':e'))
  end
  if dev then
    self.icon = dev
  else
    self.icon = ''
  end
  self.name = self:name()
  return self
end

function split(s, delimiter)
  local result = {};
  for match in (s .. delimiter):gmatch('(.-)' .. delimiter) do
    table.insert(result, match);
  end
  return result;
end

function Buffer:len()
  local margin = 2
  return vim.fn.strchars(' ' .. ' ' .. ' ' .. self.name .. ' ' .. self.modified .. ' ') + margin
end

function Buffer:name()
  if self.buftype == 'help' then
    return 'help:' .. vim.fn.fnamemodify(self.file, ':t:r')
  elseif self.buftype == 'quickfix' then
    return 'quickfix'
  elseif self.filetype == 'TelescopePrompt' then
    return 'Telescope'
  elseif self.filetype == 'dashboard' then
    return 'Dashboard'
  elseif self.filetype == 'packer' then
    return 'Packer'
  elseif self.file:sub(self.file:len() - 2, self.file:len()) == 'FZF' then
    return 'FZF'
  elseif self.buftype == 'terminal' then
    local mtch = string.match(split(self.file, ' ')[1], 'term:.*:(%a+)')
    return mtch ~= nil and mtch or vim.fn.fnamemodify(vim.env.SHELL, ':t')
  elseif self.file == '' then
    return '[No Name]'
  end
  return vim.fn.pathshorten(vim.fn.fnamemodify(self.file, ':p:~:t'))
end

function Buffer:render()
  local line = self:hl() .. '%' .. self.bufnr .. '@TablineSwitchBuffer@' .. ' ' .. self.icon .. ' ' .. self.name .. ' '
                   .. self.modified .. '%T' .. self:separator()
  return line
end

function Buffer:separator()
  local hl = ''
  if self.current and self.last then
    hl = '%#tabline_a_to_c#' .. self.options.section_left
  elseif self.last then
    hl = '%#tabline_b_to_c#' .. self.options.section_left
  elseif self.beforecurrent then
    hl = '%#tabline_b_to_a#' .. self.options.section_left
  elseif self.current then
    hl = '%#tabline_a_to_b#' .. self.options.section_left
  else
    hl = '%#tabline_a_to_b#' .. self.options.component_left
  end
  return hl
end

function Buffer:window_count()
  local nwins = vim.fn.bufwinnr(self.bufnr)
  return nwins > 1 and '(' .. nwins .. ') ' or ''
end

function M.format_buffers(buffers, max_length)
  if max_length == nil then
    max_length = vim.o.columns - M.total_tab_length
  end

  local line = ''
  local total_length = 0
  local complete = false
  local current
  for i, buffer in pairs(buffers) do
    if buffer.current then
      current = i
    end
  end
  local current_buffer = buffers[current]
  if current_buffer == nil then
    local b = Buffer:new{ bufnr = vim.fn.bufnr() }
    b.current = true
    b.last = true
    return b:render()
  end
  line = line .. current_buffer:render()
  total_length = current_buffer:len()
  local i = 0
  local before, after
  while true do
    i = i + 1
    before = buffers[current - i]
    after = buffers[current + i]
    if before == nil and after == nil then
      break
    end
    if before then
      total_length = total_length + before:len()
    end
    if after then
      total_length = total_length + after:len()
    end
    if total_length > max_length then
      break
    end
    if before then
      line = before:render() .. line
    end
    if after then
      line = line .. after:render()
    end
  end
  if total_length > max_length then
    if before ~= nil then
      line = '%#tabline_b_normal#...' .. M.options.component_left .. line
    end
    if after ~= nil then
      line = line .. '...' .. '%#tabline_b_to_c#' .. M.options.section_left .. '%#tabline_c_normal#'
    end
  end
  return line
end

function M.buffers(opt)
  if opt == nil then
    opt = M.options
  end

  local buffers = {}
  for b = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(b) ~= 0 and vim.fn.getbufvar(b, '&buftype') ~= 'quickfix' then
      buffers[#buffers + 1] = Buffer:new{ bufnr = b, options = opt }
    end
  end
  local line = ''
  local current = 0
  for i, buffer in pairs(buffers) do
    if i == 1 then
      buffer.first = true
    end
    if i == #buffers then
      buffer.last = true
    end
    if buffer.bufnr == vim.fn.bufnr() then
      buffer.current = true
      current = i
    end
  end
  for i, buffer in pairs(buffers) do
    if i == current - 1 then
      buffer.beforecurrent = true
    end
    if i == current + 1 then
      buffer.aftercurrent = true
    end
  end
  line = M.format_buffers(buffers)
  return line
end

function Buffer:hl()
  if self.current then
    return '%#tabline_a_normal#'
  elseif self.visible then
    return '%#tabline_b_normal_bold#'
  else
    return '%#tabline_b_normal#'
  end
end

function M.switch_buffer(bufnr)
  print(bufnr)
end

function M.tabs(opt)
  if opt == nil then
    opt = M.options
  end
  local tabs = {}
  for t = 1, vim.fn.tabpagenr('$') do
    tabs[#tabs + 1] = Tab:new{ tabnr = t, options = opt }
  end
  local line = ''
  local current = 0
  for i, tab in pairs(tabs) do
    if i == 1 then
      tab.first = true
    end
    if i == #tabs then
      tab.last = true
    end
    if tab.tabnr == vim.fn.tabpagenr() then
      tab.current = true
      current = i
    end
  end
  for i, tab in pairs(tabs) do
    if i == current - 1 then
      tab.beforecurrent = true
    end
    if i == current + 1 then
      tab.aftercurrent = true
    end
  end
  line = M.format_tabs(tabs)
  line = '%=%#TabLineFill#%999X' .. line
  return line
  -- local line = '%=%#TabLineFill#%999X' .. '%#tabline_a_to_c#' .. opt.section_right .. '%#tabline_a_normal#' .. ' '
  --                  .. vim.fn.tabpagenr() .. '/' .. vim.fn.tabpagenr('$') .. ' '
  -- return line
end

function M.highlight_groups()
  local fg, bg
  fg = M.extract_highlight_colors('tabline_b_normal', 'fg')
  bg = M.extract_highlight_colors('tabline_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'bold' }, 'b_normal_bold')
  fg = M.extract_highlight_colors('tabline_a_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_b')
  fg = M.extract_highlight_colors('tabline_b_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_a')
  fg = M.extract_highlight_colors('tabline_b_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_c')
  fg = M.extract_highlight_colors('tabline_c_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_b')
  fg = M.extract_highlight_colors('tabline_a_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_c')
  fg = M.extract_highlight_colors('tabline_c_normal', 'bg')
  bg = M.extract_highlight_colors('tabline_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_a')
end

function M.setup()
  vim.cmd([[
    hi default link TablineCurrent         TabLineSel
    hi default link TablineActive          PmenuSel
    hi default link TablineHidden          TabLine
    hi default link TablineFill            TabLineFill
    hi default link tabline_a_normal       lualine_a_normal
    hi default link tabline_b_normal       lualine_b_normal
    hi default link tabline_c_normal       lualine_c_normal

    command! -count   -bang BufferNext             :bnext
    command! -count   -bang BufferPrevious         :bprev

    set guioptions-=e

    function! TablineSwitchBuffer(bufnr, mouseclicks, mousebutton, modifiers)
      execute ":b " . a:bufnr
    endfunction

    function! TablineSwitchTab(tabnr, mouseclicks, mousebutton, modifiers)
      execute ":tab " . a:tabnr
    endfunction

    command! -nargs=1 TablineRename lua require('tabline').tab_rename(<f-args>)
  ]])

  function _G.tabline_buffers()
    M.highlight_groups()
    return M.buffers(M.options)
  end

  function _G.tabline_buffers_tabs()
    M.highlight_groups()
    local tabs = M.tabs(M.options)
    return M.buffers(M.options) .. tabs
  end

  function _G.tabline_switch_buffer(bufnr)
    return M.switch_buffer(bufnr)
  end

  vim.o.tabline = '%!v:lua.tabline_buffers_tabs()'
  vim.o.showtabline = 2
end

return M
