return {
  'nvim-telescope/telescope.nvim',
  dependencies = {
    'nvim-lua/plenary.nvim',
    { 'nvim-telescope/telescope-fzf-native.nvim', build = 'make'}
  },
  config = function()
    require('telescope').setup {
      extensions = {
        fzf = {}
      }
    }
    require('telescope').load_extension('fzf')
  end
}
