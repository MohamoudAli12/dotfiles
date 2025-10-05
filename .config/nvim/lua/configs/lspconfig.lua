require("nvchad.configs.lspconfig").defaults()

local servers = { "lua_ls", "ruff", "clangd" }
vim.lsp.enable(servers)

-- read :h vim.lsp.config for changing options of lsp servers 
