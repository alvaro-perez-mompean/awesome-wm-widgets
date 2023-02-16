# awesome-wm-widgets
A collection of widgets for the awesome window manager.

## Installation
Copy the widgets you want to use to your awesome config directory. For example:
```bash
cp awesome-wm-widgets/clipboard-manager.lua ~/.config/awesome/
```

## Widgets
### Clipboard History
A clipboard widget that shows the clipboard history and allows to switch between them

#### Usage
```lua
local clipboard_manager = require("clipboard-manager")
local clipboard_widget = clipboard_manager({
    settings = function()
        widget:set_markup(markup.font("Terminus 8", "Clipboard"))
    end
})
```
