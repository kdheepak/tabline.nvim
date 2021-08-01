
# tabline.nvim

A "buffer and tab" tabline:

<img width="835" alt="Screen Shot 2021-08-01 at 1 28 45 AM" src="https://user-images.githubusercontent.com/1813121/127763005-eb7bd6c3-ff8e-41c9-a738-6cb689fff58e.png">

- Show buffers and tabs in tabline
- Use same style as lualine by default
- Bold buffers that are visible

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
