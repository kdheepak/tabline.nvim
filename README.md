
This plugin is archived. Check out the following instead:

- https://github.com/backdround/tabscope.nvim
- https://github.com/tiagovla/scope.nvim
- https://github.com/nvim-lualine/lualine.nvim

---

# tabline.nvim

A "buffer and tab" tabline:

- Show buffers and tabs in tabline
- Use same style as lualine by default
- Uses same section and component separators as lualine by default
- Bold buffers that are visible
- Ability to name tabs
- Toggle showing buffers per tabs
- Support nvim-web-devicons
- Works with sessions

![](https://user-images.githubusercontent.com/1813121/128622268-173d2d40-a391-4fc7-b3ad-d10f2be97013.gif)

# Installation

**Using Packer**

```lua
use {
  'kdheepak/tabline.nvim',
  config = function()
    require'tabline'.setup {
      -- Defaults configuration options
      enable = true,
      options = {
      -- If lualine is installed tabline will use separators configured in lualine by default.
      -- These options can be used to override those settings.
        section_separators = {'', ''},
        component_separators = {'', ''},
        max_bufferline_percent = 66, -- set to nil by default, and it uses vim.o.columns * 2/3
        show_tabs_always = false, -- this shows tabs only when there are more than one tab or if the first tab is named
        show_devicons = true, -- this shows devicons in buffer section
        show_bufnr = false, -- this appends [bufnr] to buffer section,
        bufnr_style = { '⁰', '¹', '²', '³', '⁴', '⁵', '⁶', '⁷', '⁸', '⁹' }, -- this change the [bufnr] style
        bufnr_direction = true, -- set true to put buffer number at title's left
        show_filename_only = false, -- shows base filename only instead of relative path in filename
        modified_icon = "+ ", -- change the default modified icon
        modified_italic = false, -- set to true by default; this determines whether the filename turns italic if modified
        show_tabs_only = false, -- this shows only tabs instead of tabs + buffers
      }
    }
    vim.cmd[[
      set guioptions-=e " Use showtabline in gui vim
      set sessionoptions+=tabpages,globals " store tabpages and globals in session
    ]]
  end,
  requires = { { 'hoob3rt/lualine.nvim', opt=true }, {'kyazdani42/nvim-web-devicons', opt = true} }
}
```

# Usage

### :TablineBufferNext

Move to next buffer in the tabline.

### :TablineBufferPrevious

Move to previous buffer in the tabline.

### :TablineTabNew {filename1.ext} {filename2.ext}

Open a new tab with these files.

### :TablineToggleShowAllBuffers

Toggles whether to show all buffers that are open versus only buffers that are currently visible or bound.

### :TablineBuffersBind {filename1.ext} {filename2.ext}

Bind the current tab's buffers to these files.

### :TablineBuffersClearBind

Clear the binding of current tab's buffers.

### :TablineTabRename {name}

Rename current tab's name.

# Configuration

You can customize the behavior of this extension by setting values for any of the following optional parameters.

### tabline_show_devicons

Show devicons in tabline for each buffer (default = true)

### tabline_show_bufnr

Show bufnr in tabline for each buffer (default = false)

### tabline_show_filename_only

Show only filename instead of shortened full path (default = false)

### tabline_show_last_separator

Show separator after the last buffer or tab (default = false)

### tabline_show_tabs_only

Show only tabs instead of tabs + buffers (default = false)

# Lualine tabline support

[`nvim-lualine/lualine.nvim`](https://github.com/nvim-lualine/lualine.nvim) now has buffers and tabs as components.
If you are not interested in binding buffers to tabs, I'd recommend using those components. They work well in any section.

If you'd still like to use tabline with lualine's tabline instead, you can do the following:

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
