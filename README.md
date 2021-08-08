# tabline.nvim

A "buffer and tab" tabline:

<img width="835" alt="Screen Shot 2021-08-01 at 1 31 41 AM" src="https://user-images.githubusercontent.com/1813121/127763079-4be5c3ce-bad2-4c76-ae16-3d22efb983ed.png">

- Show buffers and tabs in tabline
- Use same style as lualine by default
- Bold buffers that are visible
- Ability to name tabs
- Toggle showing buffers per tabs

![](https://user-images.githubusercontent.com/1813121/128622268-173d2d40-a391-4fc7-b3ad-d10f2be97013.gif)

Add the following to your `.vimrc`:

```
set guioptions-=e " Use showtabline in gui vim
set sessionoptions+=tabpages,globals " store tabpages and globals in session
```

## Documentation

:TablineBufferNext
:TablineBufferPrevious
:TablineTabNew
:TablineBuffersBind
:TablineBuffersClearBind
:TablineTabRename
:TablineToggleShowAllBuffers

## Installation

**Using Packer**

```lua
use {
  'kdheepak/tabline.nvim',
  config = function()
    require'tabline'.setup {}
    vim.cmd[[
      set guioptions-=e " Use showtabline in gui vim
      set sessionoptions+=tabpages,globals " store tabpages and globals in session
    ]]
  end,
  requires = { { 'hoob3rt/lualine.nvim', opt=true }, 'kyazdani42/nvim-web-devicons' }
}
```

## Configuration

You can customize the behavior of this extension by setting values for any of the following optional parameters.

- `tabline_show_devicons`

  Show devicons in tabline for each buffer (default = true)

- `tabline_show_bufnr`

  Show bufnr in tabline for each buffer (default = false)

## Usage

`TablineBufferNext`

> Move to next buffer in the tabline.

`TablineBufferPrevious`

> Move to previous buffer in the tabline.

`TablineTabNew <filename1.ext> <filename2.ext>`

> Open a new tab with these files.

`TablineToggleShowAllBuffers`

> Toggles whether to show all buffers that are open versus only buffers that are currently visible or bound.

`TablineBuffersBind <filename1.ext> <filename2.ext>`

> Bind the current tab's buffers to these files.

`TablineBuffersClearBind`

> Clear the binding of current tab's buffers.

`TablineTabRename <name>`

> Rename current tab's name.
