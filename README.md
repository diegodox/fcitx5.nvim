# fcitx5-nvim

fcitx5.nvim is a neovim plugin for automatically setting up the input method editor (IME) in nvim. It supports fcitx5.

## Installation

Install using your preferred plugin manager. For example, using packer.nvim:

```lua
use {'your_username/fcitx5.nvim'}
```

## Usage

Configure the plugin by calling the setup function in your init.lua or init.vim file:

```lua
require('fcitx5').setup()
```

fcitx5.nvim monitors the InsertEnter and InsertLeave events in nvim to automatically switch the IME status.

## License

MIT License. See `LICENSE` for more information.
