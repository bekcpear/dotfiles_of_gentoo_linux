return require('packer').startup(function(use)
	-- manage packer itself
	use 'wbthomason/packer.nvim'

	use {
		'rmagatti/auto-session',
		config = function()
			require("auto-session").setup {
				log_level = "error",
				auto_session_enable_last_session = false,
				auto_session_enabled = true,
				auto_save_enabled = true,
				auto_restore_enabled = true,
				auto_session_suppress_dirs = nil,
				auto_session_allowed_dirs = {"/*"},
				auto_session_use_git_branch = true
			}
		end
	}

	use 'h-hg/fcitx.nvim'

	use {
		'nvim-tree/nvim-tree.lua',
		requires = {
			'nvim-tree/nvim-web-devicons', -- optional
		},
	}

	use({
		"kylechui/nvim-surround",
		-- Use for stability; omit to use `main` branch for the latest features
		tag = "*",
		config = function()
			require("nvim-surround").setup({
				-- Configuration here, or leave empty to use defaults
			})
		end
	})

	use {
		"windwp/nvim-autopairs",
		config = function()
			require("nvim-autopairs").setup({})
		end
	}
end)
