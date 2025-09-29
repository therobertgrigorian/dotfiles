return {
  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 
      'nvim-tree/nvim-web-devicons',
      'catppuccin/nvim'  -- Add catppuccin as a dependency
    },
    config = function()
      local catppuccin = require("catppuccin.utils.lualine")
      local lualine_theme = catppuccin("mocha")
      require('lualine').setup {
        options = {
          theme = lualine_theme,  -- Set catppuccin as the theme
          component_separators = '',
          section_separators = { left = '', right = '' },
        },
        sections = {
          lualine_a = { { 'mode', separator = { left = '' }, right_padding = 2 } },
          lualine_b = { 'filename', 'branch' },
          lualine_c = {
            '%=', --[[ add your center components here in place of this comment ]]
          },
          lualine_x = {},
          lualine_y = { 'filetype', 'progress' },
          lualine_z = {
            { 'location', separator = { right = '' }, left_padding = 2 },
          },
        },
      }
    end
  },
}
