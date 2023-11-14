local pluginName = 'dialog to lua editor'

local classes = script.classes
local collectorClasses = classes.collectors
local init = script.init

local plugin = plugin :: Plugin

require(script.services)

-- shared init
shared.cellSize = 0x10

--- classes ---
local toolbar: toolbar.constructor = require(classes.toolbar)
local decryptor: decryptor.constructor = require(collectorClasses.localDecryptor)

--- decryptors ---
local markersDecryptor: decryptor.object = --[[new]] decryptor()

shared.markersDecryptor = markersDecryptor

--- objects ---
local pluginToolbar: toolbar.object = --[[new]] toolbar(plugin, pluginName)

--- initializers ---
local initDialogEditor = require(init.dialogEditorWindow)
local initNewDialog = require(init.newDialogCoreGui)
local initImportDialog = require(init.importDialogCoreGui)

initDialogEditor(pluginToolbar)
initNewDialog(pluginToolbar)
initImportDialog(pluginToolbar)
