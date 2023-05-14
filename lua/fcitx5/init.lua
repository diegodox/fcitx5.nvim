local M = {
	is_ime_available = nil,
	last_ime_status = nil,
	last_filetype = nil,
	
	ime_on_status = 1,
	ime_off_status = 2,

	ime_on_arg = "-o",
	ime_off_arg = "-c",
}

---@param cmd string
---@param raw boolean?
---@return string
local function os_capture(cmd, raw)
	local f = assert(io.popen(cmd, "r"))
	local s = assert(f:read("*a"))
	f:close()
	if raw then
		return s
	end
	s = string.gsub(s, "^%s+", "")
	s = string.gsub(s, "%s+$", "")
	s = string.gsub(s, "[\n\r]+", " ")
	return s
end

---@param bufnr number
---@return string?
local function buf_filetype(bufnr)
	return vim.api.nvim_buf_get_option(bufnr, "filetype")
end

---@return boolean?
function M.is_ime_on()
	if not M.is_ime_available then
		return nil
	end
	local status = os_capture("fcitx5-remote")
	if status == M.ime_off_status then
		return false
	end
	if status == M.ime_on_status then
		return true
	end
	return nil
end

---remember current ime mode to `last_ime_status`
function M.store_ime_status()
	M.last_ime_status = M.is_ime_on()
end

---call system function to make ime off.
---if parameter `store` is true, remember ime status before make ime off.
---@param store boolean?
---@return boolean?  suc
---@return exitcode? exitcode
---@return integer?  code
function M.ime_off(store)
	if store then
		M.store_ime_status()
	end
	return os.execute("fcitx5-remote " .. M.ime_off_arg .. " > /dev/null 2>&1")
end

---call system function to make ime on.
---if parameter `store` is true, remember ime status before make ime on.
---@param store boolean?
---@return boolean?  suc
---@return exitcode? exitcode
---@return integer?  code
function M.ime_on(store)
	if store then
		M.store_ime_status()
	end
	return os.execute("fcitx5-remote " .. M.ime_on_arg .. " > /dev/null 2>&1")
end

---restore ime status (i.e. set to `last_ime_status`)
function M.restore_ime_status()
	if M.last_ime_status == nil then
		return
	elseif M.last_ime_status then
		M.ime_on(false)
	elseif not M.last_ime_status then
		M.ime_off(false)
	end
end

function M.setup(cfg)
	M.is_ime_available = os.execute("which fcitx5-remote > /dev/null") == 0
	if not M.is_ime_available then
		return
	end

	M.ime_on_status = cfg.ime_on_status or M.ime_on_status
	M.ime_off_status = cfg.ime_off_status or M.ime_off_status
	M.ime_on_arg = cfg.ime_on_arg or M.ime_on_arg
	M.ime_off_arg = cfg.ime_off_arg or M.ime_off_arg

	local g = vim.api.nvim_create_augroup("Fcitx5", { clear = true })

	vim.api.nvim_create_autocmd("WinLeave", {
		callback = function(opts)
			M.last_filetype = buf_filetype(opts.buf)
		end,
		group = g,
		desc = "Keep last filetype for fcitx5",
	})

	vim.api.nvim_create_autocmd("InsertEnter", {
		callback = function(opts)
			if buf_filetype(opts.buf) ~= "TelescopePrompt" then
				M.last_filetype = buf_filetype(opts.buf)
				M.restore_ime_status()
			end
		end,
		group = g,
		desc = "Restore IME Mode when Enter Insert Mode",
	})

	vim.api.nvim_create_autocmd("InsertLeavePre", {
		callback = function()
			local is_disble_filetype = M.last_filetype ~= "TelescopePrompt"
			M.ime_off(is_disble_filetype)
		end,
		group = g,
		desc = "Store IME Mode and Turn off when Leave Insert",
	})
end

return M
