vim.keymap.set("n", "<leader>w", "<cmd>write<cr>", { desc = "Guardar" })
vim.keymap.set("n", "<leader>q", "<cmd>quit<cr>", { desc = "Salir" })
vim.keymap.set("n", "<leader>h", "<cmd>nohlsearch<cr>", { desc = "Limpiar busqueda" })

if vim.g.fedora_setup_nvim_extras == 1 then
  vim.keymap.set("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Buscar archivos" })
  vim.keymap.set("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Buscar texto" })
  vim.keymap.set("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
  vim.keymap.set("n", "<leader>e", "<cmd>Ex<cr>", { desc = "Explorador" })
end
