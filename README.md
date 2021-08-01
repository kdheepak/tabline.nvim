# tabline.nvim

A lualine "buffer and tab" tabline:

https://user-images.githubusercontent.com/1813121/127736189-42e9d6fe-2e88-4265-b45c-9f255c4eb4b8.mov

### Install

```
use {
  'kdheepak/tabline.nvim',
  config = function()
    require'tabline'.setup {}
  end,
  requires = {'hoob3rt/lualine.nvim', 'kyazdani42/nvim-web-devicons'}
}
```
