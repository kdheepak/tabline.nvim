
# tabline.nvim

A "buffer and tab" tabline:

<img width="835" alt="Screen Shot 2021-08-01 at 1 31 41 AM" src="https://user-images.githubusercontent.com/1813121/127763079-4be5c3ce-bad2-4c76-ae16-3d22efb983ed.png">

- Show buffers and tabs in tabline
- Use same style as lualine by default
- Bold buffers that are visible
- Ability to name tabs
- Toggle showing buffers per tabs


![](https://user-images.githubusercontent.com/1813121/128622268-173d2d40-a391-4fc7-b3ad-d10f2be97013.gif)


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
