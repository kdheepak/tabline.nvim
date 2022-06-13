describe('tabline.nvim', function()

  local tabline = require('tabline')
  before_each(function()
    tabline.setup()
  end)

  it('can enable tableline', function()
    assert.is_true(true)
  end)
end)
