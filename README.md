# tabline.nvim

A "buffer and tab" tabline:

- Show buffers and tabs in tabline
- Use same style as lualine by default
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
    }
    vim.cmd[[
      set guioptions-=e " Use showtabline in gui vim
      set sessionoptions+=tabpages,globals " store tabpages and globals in session
    ]]
  end,
  requires = { { 'hoob3rt/lualine.nvim', opt=true }, 'kyazdani42/nvim-web-devicons' }
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
    lualine_a = { require'tabline'.buffers },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = { require'tabline'.tabs },
  },
}
```

Currently, this works best when the buffers and tabs are in section a and section z. Support for other sections will be added in the future.
