local M = {}

M.options = {
  no_name = '[No Name]',
  component_left = '',
  component_right = '',
  section_left = '',
  section_right = '',
}

-- Use luatab as reference:
-- https://github.com/alvarosevilla95/luatab.nvim

function M.highlight(name, foreground, background)
  local command = { 'highlight', name }
  if foreground and foreground ~= 'none' then
    table.insert(command, 'guifg=' .. foreground)
  end
  if background and background ~= 'none' then
    table.insert(command, 'guibg=' .. background)
  end
  vim.cmd(table.concat(command, ' '))
end

function M.create_component_highlight_group(color, highlight_tag)
  if color.bg and color.fg then
    local highlight_group_name = table.concat({ 'tabline', highlight_tag }, '_')
    M.highlight(highlight_group_name, color.fg, color.bg)
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

function M.format_buffers(buffers, opt, max_length)
  if max_length == nil then
    max_length = vim.o.columns
  end
  local line = ''
  for i, buffer in pairs(buffers) do
    line = line .. M.format_buffer(buffer, opt)
  end
  return line
end

function M.buffers(opt)
  if opt == nil then
    opt = M.options
  end

  local fg, bg
  fg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_b')
  fg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_a')
  fg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_c')
  fg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_b')
  fg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_c')
  fg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_a')

  local buffers = {}
  for b = 1, vim.fn.bufnr('$') do
    if vim.fn.buflisted(b) ~= 0 and vim.fn.getbufvar(b, '&buftype') ~= 'quickfix' then
      buffers[#buffers + 1] = { bufnr = b }
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
  line = M.format_buffers(buffers, opt)
  return line
end

function M.buffer_name(buffer, opt)
  local bufnr = buffer.bufnr
  local file = vim.fn.bufname(bufnr)
  local buftype = vim.fn.getbufvar(bufnr, '&buftype')
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  if buftype == 'help' then
    return 'help:' .. vim.fn.fnamemodify(file, ':t:r')
  elseif buftype == 'quickfix' then
    return 'quickfix'
  elseif filetype == 'TelescopePrompt' then
    return 'Telescope'
  elseif file:sub(file:len() - 2, file:len()) == 'FZF' then
    return 'FZF'
  elseif buftype == 'terminal' then
    local _, mtch = string.match(file, 'term:(.*):(%a+)')
    return mtch ~= nil and mtch or vim.fn.fnamemodify(vim.env.SHELL, ':t')
  elseif file == '' then
    return '[No Name]'
  end
  return vim.fn.pathshorten(vim.fn.fnamemodify(file, ':p:~:t'))
end

function M.buffer_modified(buffer, opt)
  local bufnr = buffer.bufnr
  return vim.fn.getbufvar(bufnr, '&modified') == 1 and '[+] ' or ''
end

function M.buffer_devicon(buffer, opt)
  local dev, devhl
  local bufnr = buffer.bufnr
  local file = vim.fn.bufname(bufnr)
  local buftype = vim.fn.getbufvar(bufnr, '&buftype')
  local filetype = vim.fn.getbufvar(bufnr, '&filetype')
  if filetype == 'TelescopePrompt' then
    dev, devhl = require'nvim-web-devicons'.get_icon('telescope')
  elseif filetype == 'fugitive' then
    dev, devhl = require'nvim-web-devicons'.get_icon('git')
  elseif filetype == 'vimwiki' then
    dev, devhl = require'nvim-web-devicons'.get_icon('markdown')
  elseif buftype == 'terminal' then
    dev, devhl = require'nvim-web-devicons'.get_icon('zsh')
  else
    dev, devhl = require'nvim-web-devicons'.get_icon(file, vim.fn.expand('#' .. bufnr .. ':e'))
  end
  if dev then
    return ' ' .. dev .. ' '
  else
    return ' '
  end
end

function M.buffer_separator(buffer, opt)
  local hl = ''
  if buffer.current and buffer.last then
    hl = '%#tabline_a_to_c#' .. opt.section_left
  elseif buffer.last then
    hl = '%#tabline_b_to_c#' .. opt.section_left
  elseif buffer.beforecurrent then
    hl = '%#tabline_b_to_a#' .. opt.section_left
  elseif buffer.current then
    hl = '%#tabline_a_to_b#' .. opt.section_left
  else
    hl = '%#tabline_a_to_b#' .. opt.component_left
  end
  return hl
end

function M.buffer_window_count(buffer, opt)
  local bufnr = buffer.bufnr
  local nwins = vim.fn.bufwinnr(bufnr)
  return nwins > 1 and '(' .. nwins .. ') ' or ''
end

function M.hl(buffer, opt)
  if buffer.current then
    return '%#lualine_a_normal#'
  else
    return '%#lualine_b_normal#'
  end
end

function M.format_buffer(buffer, opt)
  local line = ''
  line = line .. M.hl(buffer, opt) .. '%' .. buffer.bufnr .. '@TablineSwitchBuffer@' .. M.buffer_devicon(buffer, opt)
             .. M.buffer_name(buffer, opt) .. ' ' .. '%T' .. M.buffer_separator(buffer, opt)
  return line
end

function M.switch_buffer(bufnr)
  print(bufnr)
end

function M.tabs(opt)
  if opt == nil then
    opt = M.options
  end

  local fg, bg
  fg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_b')
  fg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_a')
  fg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'b_to_c')
  fg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_b_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_b')
  fg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'a_to_c')
  fg = M.extract_highlight_colors('lualine_c_normal', 'bg')
  bg = M.extract_highlight_colors('lualine_a_normal', 'bg')
  M.create_component_highlight_group({ bg = bg, fg = fg }, 'c_to_a')

  local tabs = {}
  for t = 1, vim.fn.tabpagenr('$') do
    tabs[#tabs + 1] = { tabnr = t }
  end
  local line = '%#tabline_a_to_c#' .. opt.section_right .. '%#lualine_a_normal#' .. ' ( ' .. vim.fn.tabpagenr() .. ' / '
                   .. vim.fn.tabpagenr('$') .. ' )'
  return line
end

function M.setup()
  vim.cmd([[
    hi default link TablineCurrent         TabLineSel
    hi default link TablineActive          PmenuSel
    hi default link TablineHidden          TabLine
    hi default link TablineFill            TabLineFill

    command! -count   -bang BufferNext             :bnext
    command! -count   -bang BufferPrevious         :bprev

    set guioptions-=e

    function! TablineSwitchBuffer(bufnr, mouseclicks, mousebutton, modifiers)
      execute ":b " . a:bufnr
    endfunction
  ]])

  function _G.tabline_buffers()
    return M.buffers(M.options)
  end

  function _G.tabline_switch_buffer(bufnr)
    return M.switch_buffer(bufnr)
  end

  vim.o.tabline = '%!v:lua.tabline_buffers()'
  vim.o.showtabline = 2
end

return M
