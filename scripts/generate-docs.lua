docgen = require('babelfish')
local metadata = {
  input_file='README.md',
  output_file = 'doc/tabline.txt',
  project_name='tabline',
}
docgen.generate_readme(metadata)
