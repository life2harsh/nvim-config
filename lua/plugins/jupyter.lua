-- Jupyter notebooks in Neovim: edit notebooks as Python via Jupytext and run
-- cells in-place through Molten.  Start a kernel with <leader>ji.
return {
  {
    "benlubas/molten-nvim",
    version = "^1.0.0",
    lazy = false, -- Remote-plugin commands must be available when Neovim starts.
    build = ":UpdateRemotePlugins",
    init = function()
      local jupyter_bin = vim.fn.expand "~/.local/share/nvim/jupyter-venv/bin"
      vim.g.python3_host_prog = jupyter_bin .. "/python"
      vim.env.PATH = jupyter_bin .. ":" .. vim.env.PATH
      vim.g.molten_auto_open_output = false
      vim.g.molten_output_win_max_height = 20
      vim.g.molten_wrap_output = true
      vim.g.molten_virt_text_output = false
    end,
    keys = {
      { "<leader>ji", "<cmd>MoltenInit nvim-python<cr>", desc = "Jupyter: start Python kernel" },
      { "<leader>jr", "<cmd>MoltenEvaluateOperator<cr>", desc = "Jupyter: run motion" },
      { "<leader>jl", "<cmd>MoltenEvaluateLine<cr>", desc = "Jupyter: run line" },
      { "<leader>jc", "<cmd>MoltenReevaluateCell<cr>", desc = "Jupyter: run cell" },
      { "<leader>ja", "<cmd>MoltenReevaluateAll<cr>", desc = "Jupyter: run all" },
      { "<leader>jo", "<cmd>MoltenShowOutput<cr>", desc = "Jupyter: show output" },
      { "<leader>jh", "<cmd>MoltenHideOutput<cr>", desc = "Jupyter: hide output" },
      { "<leader>jd", "<cmd>MoltenDelete<cr>", desc = "Jupyter: clear output" },
      { "<leader>jr", "<cmd>MoltenEvaluateVisual<cr>gv", mode = "v", desc = "Jupyter: run selection" },
    },
  },
  {
    "GCBallesteros/jupytext.nvim",
    lazy = false,
    opts = {
      -- Python notebooks become editable `.py` buffers with `# %%` cell markers.
      style = "hydrogen",
      output_extension = "auto",
    },
    config = function(_, opts)
      require("jupytext").setup(opts)

      -- Jupytext expects valid JSON. Make a newly-created, empty `.ipynb`
      -- immediately usable instead of raising a JSON decode error on BufReadCmd.
      local handlers = vim.api.nvim_get_autocmds { group = "jupytext-nvim", event = "BufReadCmd" }
      local read_notebook = handlers[1] and handlers[1].callback
      vim.api.nvim_clear_autocmds { group = "jupytext-nvim" }
      vim.api.nvim_create_autocmd("BufReadCmd", {
        pattern = "*.ipynb",
        group = "jupytext-nvim",
        callback = function(ev)
          if vim.fn.getfsize(ev.match) == 0 then
            vim.fn.writefile({ vim.json.encode {
              cells = {},
              metadata = {
                kernelspec = { display_name = "Python (Neovim)", language = "python", name = "nvim-python" },
                language_info = { name = "python" },
              },
              nbformat = 4,
              nbformat_minor = 5,
            } }, ev.match)
          end
          return read_notebook(ev)
        end,
      })
    end,
  },
}
