local codex_terminals = {}
local active_root
local last_file

local function is_file_buffer(buffer)
  return vim.api.nvim_buf_is_valid(buffer)
    and vim.bo[buffer].buftype == ""
    and vim.api.nvim_buf_get_name(buffer) ~= ""
end

local function remember_file(buffer)
  if is_file_buffer(buffer) then last_file = vim.fs.normalize(vim.api.nvim_buf_get_name(buffer)) end
end

local function current_file()
  local buffer = vim.api.nvim_get_current_buf()
  if is_file_buffer(buffer) then
    remember_file(buffer)
    return last_file
  end
  return last_file
end

local function project_root(file)
  local start = file and vim.fs.dirname(file) or vim.fn.getcwd()
  return vim.fs.normalize(vim.fs.root(start, ".git") or vim.fn.getcwd())
end

local function context_root()
  if vim.bo.buftype == "terminal" and active_root then return active_root end
  return project_root(current_file())
end

local function panel_width()
  return math.min(80, math.max(40, math.floor(vim.o.columns * 0.42)))
end

local function active_terminal()
  return active_root and codex_terminals[active_root] or nil
end

local function focus_codex_input(terminal)
  terminal = terminal or active_terminal()
  if not terminal or not terminal:is_open() then return end
  if vim.api.nvim_get_current_win() ~= terminal.window then return end
  vim.cmd.startinsert()
end

local function close_other_panels(root)
  for other_root, terminal in pairs(codex_terminals) do
    if other_root ~= root and terminal:is_open() then terminal:close() end
  end
end

local toggle_codex

local function codex_command(root)
  local executable = vim.fn.shellescape(vim.fn.exepath "codex")
  local directory = vim.fn.shellescape(root)
  return ("%s resume --last -C %s || exec %s -C %s"):format(executable, directory, executable, directory)
end

local function create_terminal(root)
  local Terminal = require("toggleterm.terminal").Terminal
  local terminal

  terminal = Terminal:new {
    cmd = codex_command(root),
    dir = root,
    direction = "vertical",
    display_name = "Codex",
    hidden = true,
    close_on_exit = true,
    on_open = function(term)
      vim.wo[term.window].winfixwidth = true
      vim.keymap.set({ "n", "t", "i" }, "<F7>", toggle_codex, {
        buffer = term.bufnr,
        desc = "Toggle Codex panel",
      })
      vim.schedule(function() focus_codex_input(term) end)
    end,
    on_exit = function(term)
      if codex_terminals[root] == term then codex_terminals[root] = nil end
      if active_root == root then active_root = nil end
    end,
  }

  codex_terminals[root] = terminal
  return terminal
end

local function get_terminal(root)
  return codex_terminals[root] or create_terminal(root)
end

local function open_or_focus_codex(root)
  close_other_panels(root)
  active_root = root

  local terminal = get_terminal(root)
  if terminal:is_open() then
    terminal:focus()
    vim.schedule(function() focus_codex_input(terminal) end)
  else
    terminal:open(panel_width())
  end

  return terminal
end

toggle_codex = function()
  if vim.fn.executable "codex" ~= 1 then
    vim.notify("Codex CLI was not found in PATH", vim.log.levels.ERROR)
    return
  end

  local root = context_root()
  local terminal = get_terminal(root)
  active_root = root

  if terminal:is_open() and terminal:is_focused() then
    terminal:close()
    return
  end

  open_or_focus_codex(root)
end

local function attach_current_file()
  if vim.fn.executable "codex" ~= 1 then
    vim.notify("Codex CLI was not found in PATH", vim.log.levels.ERROR)
    return
  end

  local file = current_file()
  if not file then
    vim.notify("Save the file before attaching it to Codex", vim.log.levels.WARN)
    return
  end

  local root = project_root(file)
  local relative = vim.fs.relpath(root, file) or file
  local terminal = open_or_focus_codex(root)

  vim.schedule(function()
    if terminal.job_id and terminal.job_id > 0 then
      vim.fn.chansend(terminal.job_id, "@" .. relative .. " ")
      focus_codex_input(terminal)
    end
  end)
end

local function is_codex_window(window)
  for _, terminal in pairs(codex_terminals) do
    if terminal:is_open() and terminal.window == window then return true end
  end
  return false
end

local function is_neotree_window(window)
  local buffer = vim.api.nvim_win_get_buf(window)
  return vim.bo[buffer].filetype == "neo-tree"
end

local function close_auxiliary_windows_before_final_quit()
  if #vim.api.nvim_list_tabpages() ~= 1 then return end

  local current_window = vim.api.nvim_get_current_win()
  if is_codex_window(current_window) or is_neotree_window(current_window) then return end

  local windows = vim.tbl_filter(function(window)
    return vim.api.nvim_win_get_config(window).relative == ""
  end, vim.api.nvim_tabpage_list_wins(0))

  for _, window in ipairs(windows) do
    if window ~= current_window and not is_codex_window(window) and not is_neotree_window(window) then return end
  end

  for _, window in ipairs(windows) do
    if window ~= current_window and is_neotree_window(window) then pcall(vim.api.nvim_win_close, window, true) end
  end

  local terminals = vim.tbl_values(codex_terminals)
  codex_terminals = {}
  active_root = nil
  for _, terminal in ipairs(terminals) do
    terminal:shutdown()
  end
end

---@type LazySpec
return {
  {
    "akinsho/toggleterm.nvim",
    init = function()
      local group = vim.api.nvim_create_augroup("CodexPanel", { clear = true })

      vim.api.nvim_create_user_command("CodexPanel", toggle_codex, {
        desc = "Toggle the Codex side panel",
      })

      vim.api.nvim_create_user_command("CodexAttachFile", attach_current_file, {
        desc = "Attach the current file to Codex",
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        group = group,
        desc = "Remember the latest editing file for Codex",
        callback = function(args) remember_file(args.buf) end,
      })

      vim.api.nvim_create_autocmd("QuitPre", {
        group = group,
        desc = "Close auxiliary panels before quitting the final editing window",
        callback = close_auxiliary_windows_before_final_quit,
      })

      vim.api.nvim_create_autocmd("WinEnter", {
        group = group,
        desc = "Focus Codex terminal input",
        callback = function() vim.schedule(focus_codex_input) end,
      })
    end,
  },
  {
    "AstroNvim/astrocore",
    opts = function(_, opts)
      for _, mode in ipairs { "n", "i", "t" } do
        opts.mappings[mode]["<F7>"] = { toggle_codex, desc = "Toggle Codex panel" }
      end
      opts.mappings.n["<Leader>tc"] = { toggle_codex, desc = "Toggle Codex panel" }
      opts.mappings.n["<Leader>ta"] = { attach_current_file, desc = "Attach current file to Codex" }
    end,
  },
}
