# tabline.nvim

A "buffer and tab" tabline:

- Show buffers and tabs in tabline
- Use same style as lualine by default
- Uses same section and component separators as lualine by default
- Bold buffers that are visible
- Ability to name tabs
- Toggle showing buffers per tabs
- Support nvim-web-devicons

![](https://user-images.githubusercontent.com/1813121/128622268-173d2d40-a391-4fc7-b3ad-d10f2be97013.gif)

## Installation

**Using Packer**

```lua
use {
  'kdheepak/tabline.nvim',
  config = function()
    require'tabline'.setup {
      -- Defaults configuration options
      enable = true
      options = {
      -- if lualine is installed tabline will use separators configured in lualine by default.
      -- These options can be used to override those settings.
        section_separators = {'', ''},
        component_separators = {'', ''},
      }
    }
    vim.cmd[[
      set guioptions-=e " Use showtabline in gui vim
      set sessionoptions+=tabpages,globals " store tabpages and globals in session
    ]]
  end,
  requires = { { 'hoob3rt/lualine.nvim', opt=true }, {i 'kyazdani42/nvim-web-devicons', opt = true} }
}
```

## Usage

`TablineBufferNext`

Move to next buffer in the tabline.

`TablineBufferPrevious`

Move to previous buffer in the tabline.

`TablineTabNew <filename1.ext> <filename2.ext>`

Open a new tab with these files.

`TablineToggleShowAllBuffers`

Toggles whether to show all buffers that are open versus only buffers that are currently visible or bound.

`TablineBuffersBind <filename1.ext> <filename2.ext>`

Bind the current tab's buffers to these files.

`TablineBuffersClearBind`

Clear the binding of current tab's buffers.

`TablineTabRename <name>`

Rename current tab's name.

## Configuration

You can customize the behavior of this extension by setting values for any of the following optional parameters.

- `tabline_show_devicons`

Show devicons in tabline for each buffer (default = true)

- `tabline_show_bufnr`

Show bufnr in tabline for each buffer (default = false)

- `tabline_show_filename_only`

Show only filename instead of shortened full path (default = false)

## Lualine tabline support

If you'd like to use tabline with lualine's tabline instead, you can do the following:

```lua
use {
  'kdheepak/tabline.nvim',
  config = function()
    require'tabline'.setup {enable = false}
  end,
  requires = {'hoob3rt/lualine.nvim', 'kyazdani42/nvim-web-devicons'}
}

require'lualine'.setup {
  tabline = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = { require'tabline'.tabline_buffers },
    lualine_x = { require'tabline'.tabline_tabs },
    lualine_y = {},
    lualine_z = {},
  },
}
```

Currently, this works best when the buffers and tabs are in section `lualine_c` and `lualine_x` respectively.
Support for other sections will be added in the future.
