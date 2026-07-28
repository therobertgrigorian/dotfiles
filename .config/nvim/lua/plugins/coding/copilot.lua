return {
  "zbirenbaum/copilot.lua",
  -- This repo vendors a heavy language server; lazy's partial-clone fetch stalls
  -- on it here. Freeze the plugin so the update checker never re-fetches and hangs.
  pin = true,
  cmd = "Copilot",
  event = "InsertEnter",
  opts = {
    panel = { enabled = false },
    suggestion = {
      enabled = true,
      auto_trigger = true,           -- show grey ghost text as you type
      hide_during_completion = true, -- stay out of the way while the nvim-cmp menu is open
      keymap = {
        -- Tab is owned by nvim-cmp; accept Copilot's suggestion with Ctrl-l instead.
        accept = "<C-l>",
        accept_word = false,
        accept_line = false,
        next = "<M-]>",
        prev = "<M-[>",
        dismiss = "<C-]>",
      },
    },
    -- nvim-cmp still handles LSP / snippets / buffer / path; Copilot is ghost-text only.
    filetypes = { ["*"] = true },
  },
}
