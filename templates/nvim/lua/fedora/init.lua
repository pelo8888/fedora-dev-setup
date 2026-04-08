require("fedora.options")
require("fedora.keymaps")
require("fedora.autocmds")

if vim.g.fedora_setup_nvim_extras == 1 then
  require("fedora.lazy")
end
