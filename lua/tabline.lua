local M = {}

local term = require 'tabline.term'

M.options = {
  no_name = '[No Name]',
  component_left = '',
  component_right = '',
  section_left = '',
  section_right = '',
}
M.total_tab_length = 6

function M.toggle_show_all_buffers()
  local data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  data[vim.fn.tabpagenr()].show_all_buffers = not data[vim.fn.tabpagenr()].show_all_buffers
  vim.g.Tabline_tab_data = vim.fn.json_encode(data)
  vim.cmd [[redrawtabline]]
end

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

function M._new_tab_data(tabnr, data)
  if data == nil then
    data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  end
  if tabnr == nil then
    tabnr = vim.fn.tabpagenr()
  end
  if data[tabnr] == nil then
    data[tabnr] = { name = tabnr .. '', show_all_buffers = true, allowed_buffers = {} }
  end
  vim.g.Tabline_tab_data = vim.fn.json_encode(data)
end

function Tab:get_props()
  local data
  data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  if data[self.tabnr] == nil then
    self.name = self.tabnr
    M._new_tab_data(self.tabnr)
  end
  data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  self.name = data[self.tabnr].name .. ' '
  return self
end

function M.tab_rename(name)
  local data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  M._new_tab_data()
  data[vim.fn.tabpagenr()].name = name
  vim.g.Tabline_tab_data = vim.fn.json_encode(data)
  vim.cmd([[redrawtabline]])
end

function M.tab_new(...)
  local args = { ... }
  vim.cmd('tablast | tabnew')
  M._new_tab_data()
  M.toggle_show_all_buffers()
  local current_tab = M._current_tab()
  for _, file in pairs(args) do
    vim.cmd('edit ' .. file)
    current_tab.allowed_buffers[vim.fn.fnamemodify(file, ':p:~')] = true
  end
  M._current_tab(current_tab)
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
    max_length = math.floor(vim.o.columns / 3)
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
    if after ~= nil and i == 1 then
      line = line .. '%#tabline_b_to_a#' .. M.options.section_right .. '%#tabline_b_normal#' .. '...'
    elseif after ~= nil then
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
  self.filepath = vim.fn.expand('#' .. self.bufnr .. ':p:~')
  self.buftype = vim.fn.getbufvar(self.bufnr, '&buftype')
  self.filetype = vim.fn.getbufvar(self.bufnr, '&filetype')
  self.modified = vim.fn.getbufvar(self.bufnr, '&modified') == 1
  self.modified_icon = self.modified and ' ' or ''
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
  elseif vim.fn.isdirectory(self.file) == 1 then
    dev, devhl = '', nil
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
  return vim.fn.strchars(' ' .. ' ' .. ' ' .. self.name .. ' ' .. self.modified_icon .. ' ') + margin
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
  elseif vim.fn.isdirectory(self.file) == 1 then
    return vim.fn.fnamemodify(self.file, ':p:.')
  elseif self.file == '' then
    return '[No Name]'
  end
  return vim.fn.pathshorten(vim.fn.fnamemodify(self.file, ':p:.'))
end

function Buffer:render()
  local line = self:hl() .. '%' .. self.bufnr .. '@TablineSwitchBuffer@' .. ' ' .. self.icon .. ' ' .. self.name .. ' '
                   .. self.modified_icon .. '%T' .. self:separator()
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
    max_length = math.max(vim.o.columns * 2 / 3, vim.o.columns - M.total_tab_length)
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

function M._current_tab(tab)
  local data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  if tab == nil then
    return data[vim.fn.tabpagenr()]
  else
    data[vim.fn.tabpagenr()] = tab
    vim.g.Tabline_tab_data = vim.fn.json_encode(data)
  end
end

function M.clear_bind_buffers()
  local data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  data[vim.fn.tabpagenr()].allowed_buffers = {}
  data[vim.fn.tabpagenr()].show_all_buffers = true
  vim.g.Tabline_tab_data = vim.fn.json_encode(data)
  vim.cmd [[redrawtabline]]
end

function M.bind_buffers(...)
  local args = { ... }
  M._bind_buffers(args)
end

function M._bind_buffers(args)
  local filelist = {}
  if #args == 0 then
    filelist[#filelist + 1] = vim.fn.expand('%:p:~')
  else
    for _, buffer_name in pairs(args) do
      filelist[#filelist + 1] = vim.fn.fnamemodify(vim.fn.expand(buffer_name), ':p:~')
    end
  end
  local data = vim.fn.json_decode(vim.g.Tabline_tab_data)
  data[vim.fn.tabpagenr()].allowed_buffers = filelist
  data[vim.fn.tabpagenr()].show_all_buffers = false
  vim.g.Tabline_tab_data = vim.fn.json_encode(data)
  vim.cmd [[redrawtabline]]
end

function M.telescope_bind_buffers(opts)
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    error('This function requires telescope.nvim: https://github.com/nvim-telescope/telescope.nvim')
  end

  local finders = require('telescope.finders')
  local pickers = require('telescope.pickers')

  local buffers = {}
  for b = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(b) ~= 0 and vim.fn.getbufvar(b, '&buftype') ~= 'quickfix' then
      local buffer = Buffer:new{ bufnr = b }
      buffers[#buffers + 1] = '[' .. buffer.bufnr .. ']' .. ' ' .. buffer.name
    end
  end

  pickers.new(opts, { prompt_title = 'Custom Picker', finder = finders.new_table { results = buffers } }):find()
end

function M.fzf_bind_buffers()
  local fzf = require'fzf'.fzf
  local action = require'fzf.actions'.action

  local function get_buf_number(line)
    return tonumber(string.match(line, '%[(%d+)'))
  end

  local shell = action(function(items, fzf_lines, _)
    local item = items[1]
    local buf = get_buf_number(item)
    return vim.api.nvim_buf_get_lines(buf, 0, fzf_lines, false)
  end)

  coroutine.wrap(function()
    local buffers = {}
    for b = 1, vim.fn.bufnr('$') do
      if vim.fn.buflisted(b) ~= 0 and vim.fn.getbufvar(b, '&buftype') ~= 'quickfix' then
        local buffer = Buffer:new{ bufnr = b }
        local item_string = string.format('[%s] %s', term.cyan .. tostring(buffer.bufnr) .. term.reset, buffer.name)
        buffers[#buffers + 1] = item_string
      end
    end
    local choices = fzf(buffers,
                        '--layout=reverse --bind=\'f2:toggle-preview,f3:toggle-preview-wrap,shift-down:preview-page-down,shift-up:preview-page-up,ctrl-d:half-page-down,ctrl-u:half-page-up,ctrl-f:page-down,ctrl-b:page-up,ctrl-a:toggle-all,ctrl-l:clear-query\' --prompt=\'Buffers> \' --preview-window=\'nohidden:border:nowrap:right:60%\' --preview='
                            .. shell
                            .. ' --height=100% --ansi --info=inline --expect=ctrl-s,ctrl-v,ctrl-x,ctrl-t --multi')
    if not choices then
      return
    end

    local bind_buffers = {}

    for _, name in pairs(choices) do
      if name ~= '' then
        local bufnr = get_buf_number(name)
        bind_buffers[#bind_buffers + 1] = vim.fn.expand('#' .. bufnr .. ':p:~')
      end
    end

    M._bind_buffers(bind_buffers)

  end)()
end

local function contains(list, x)
  for _, v in pairs(list) do
    if v == x then
      return true
    end
  end
  return false
end

function M.tabline_buffers(opt)
  if opt == nil then
    opt = M.options
  end
  local buffers = {}
  M.buffers = buffers
  local current_tab = M._current_tab()
  for b = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(b) ~= 0 and vim.fn.getbufvar(b, '&buftype') ~= 'quickfix' then
      local buffer = Buffer:new{ bufnr = b, options = opt }
      if buffer.visible then
        buffers[#buffers + 1] = buffer
      elseif current_tab.show_all_buffers then
        buffers[#buffers + 1] = buffer
      else
        local filepath = vim.fn.expand('#' .. buffer.bufnr .. ':p:~')
        if contains(current_tab.allowed_buffers, filepath) then
          buffers[#buffers + 1] = buffer
        end
      end
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
  if self.current and self.modified then
    return '%#tabline_a_normal_italic#'
  elseif self.current then
    return '%#tabline_a_normal#'
  elseif self.visible and self.modified then
    return '%#tabline_b_normal_bold_italic#'
  elseif self.visible then
    return '%#tabline_b_normal_bold#'
  elseif self.modified then
    return '%#tabline_b_normal_italic#'
  else
    return '%#tabline_b_normal#'
  end
end

function M.tabline_tabs(opt)
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
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'italic' }, 'b_normal_italic')
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'bold,italic' }, 'b_normal_bold_italic')
  fg = M.extract_highlight_colors('tabline_a_normal', 'fg')
  bg = M.extract_highlight_colors('tabline_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'bold' }, 'a_normal_bold')
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'italic' }, 'a_normal_italic')
  M.create_component_highlight_group({ bg = bg, fg = fg, gui = 'bold,italic' }, 'a_normal_bold_italic')
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

function M.mod(a, b)
  a = a - 1
  b = b
  return (a - (math.floor(a / b) * b)) + 1
end

function M.buffer_next()
  local next
  for i, buffer in pairs(M.buffers) do
    local next_buffer = M.buffers[M.mod(i + 1, #M.buffers)]
    if buffer.current and next_buffer ~= nil then
      next = next_buffer.bufnr
    end
  end
  if next ~= nil then
    vim.cmd('buffer ' .. next)
  end
end

function M.buffer_previous()
  local previous
  for i, buffer in pairs(M.buffers) do
    local previous_buffer = M.buffers[M.mod(i - 1, #M.buffers)]
    if buffer.current and previous_buffer ~= nil then
      previous = previous_buffer.bufnr
    end
  end
  if previous ~= nil then
    vim.cmd('buffer ' .. previous)
  end
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

    command! -count TablineBufferNext             :lua require'tabline'.buffer_next()
    command! -count TablineBufferPrevious         :lua require'tabline'.buffer_previous()

    command! -count TablineBufferNext             :lua require'tabline'.buffer_next()
    command! -count TablineBufferPrevious         :lua require'tabline'.buffer_previous()

    command! -nargs=* -complete=file TablineTabNew :lua require'tabline'.tab_new(<f-args>)
    command! -nargs=+ -complete=buffer TablineBuffersBind :lua require'tabline'.bind_buffers(<f-args>)
    command! -complete=buffer TablineBuffersClearBind :lua require'tabline'.clear_bind_buffers()

    set guioptions-=e

    function! TablineSwitchBuffer(bufnr, mouseclicks, mousebutton, modifiers)
      execute ":b " . a:bufnr
    endfunction

    function! TablineSwitchTab(tabnr, mouseclicks, mousebutton, modifiers)
      execute ":tab " . a:tabnr
    endfunction

    let g:Tabline_tab_data = get(g:, "Tabline_tab_data", '{}')
    " {'1': { name = '', show_all_buffers = true, allowed_buffers = {'/path/to/file': true} } }
    command! -nargs=1 TablineRename lua require('tabline').tab_rename(<f-args>)

    command! TablineToggleShowAllBuffers lua require('tabline').toggle_show_all_buffers()
  ]])

  function _G.tabline_buffers_tabs()
    M.highlight_groups()
    local tabs = M.tabline_tabs(M.options)
    return M.tabline_buffers(M.options) .. tabs
  end

  vim.o.tabline = '%!v:lua.tabline_buffers_tabs()'
  vim.o.showtabline = 2
end

return M
