local classes = script.Parent.Parent
local gui = classes.Parent.gui
local guiPatterns = gui.patterns
local collectorClasses = classes.collectors
local guiClasses = classes.gui

local markerPattern = guiPatterns.marker
local cabelPattern = guiPatterns.cabel

local metatable = require(classes.metatable)

--- classes ---
local NVector2: NVector2.constructor = require(classes.NVector2)
local decryptor: decryptor.constructor = require(collectorClasses.localDecryptor)
local SMKConnection: SMKConnection.constructor = require(collectorClasses.localDecryptor.SMKConnection)
local event: event.constructor = require(collectorClasses.localEvent)
local SMKSignal: SMKSignal.object = require(collectorClasses.localEvent.SMKSignal)
local pin: pin.constructor = require(guiClasses.pin)

--[[ properties ]]
local cellSize         = shared.cellSize
local startPosition    = Vector3.zero
local startSize        = Vector3.new(5, 3)
local startColor       = Color3.fromHex'ffffff'
local startName        = 'New marker'
local defaultTag       = 'untagged'
local doubleClickDelta = .3
local rightsidedVector = Vector2.new(1, -1)
local cabelWidth       = 6

type void = nil

type output = {
	ancestor: marker,
	cabel: TextButton
}
type outputs = {[number]: output}

type serializeOutputs = {[number]: string}

type marker = {
	-- properties
	
	instance: Frame,
	name: string,
	position: Vector2,
	size: Vector2,
	color: Color3,
	maxOutputs: number,
	outputs: outputs,
	hash: string,
	locked: boolean,
	pin: pin.object,
	nHaveInput: boolean,
	tag: string,
	parentHash: string,
	
	-- methods
	
	setSize: (size: Vector2) -> void,
	setPosition: (pos: Vector2) -> void,
	setName: (name: string) -> void,
	setColor: (color: Color3) -> void,
	addOutput: (cabel: TextButton, marker: string) -> output,
	delOutput: (output: output) -> void,
	destroy: () -> void,
	
	-- connects
	
	opened: RBXScriptSignal,
	clicked: RBXScriptSignal,
	doubleClicked: event.object<>,
	inputSelected: RBXScriptSignal,
	outputSelected: RBXScriptSignal,
	outputAdded: event.object<output>,
	outputRemoved: event.object<output>,
	destroyed: event.object<>
}
type markerConstructor = (
	maxOutputs: number,
	visible: boolean,
	grid: ScrollingFrame,
	name: string?,
	color: Color3?,
	position: Vector2?,
	size: Vector2?,
	outputs: serializeOutputs?,
	nHaveInput: boolean?,
	locked: boolean?,
	hash: string?
) -> marker

--- other ---

export type serializeVersion = {
	color: Color3,
	position: Vector2,
	size: Vector2,
	name: string,
	maxOutputs: number,
	outputs: serializeOutputs,
	locked: boolean?,
	hash: string,
	nHaveInput: boolean
}

export type object = marker
export type constructor = markerConstructor

if shared.markerConstructor then
	return shared.markerConstructor :: markerConstructor
end

local marker: markerConstructor = function(
	maxOutputs, 
	visible, 
	grid, 
	name, 
	color, 
	position, 
	size, 
	outputs, 
	nHaveInput,
	locked, 
	hash
)
	local new: marker = {}
	
	local markersDecryptor: decryptor.object = shared.markersDecryptor
	local gridAbsolutePosition = shared.getAbsoluteGuiPosition(grid)
	
	position = position or startPosition
	size     = size     or startSize
	color    = color    or startColor
	name     = name     or startName
	
	local instance = markerPattern:Clone()
	
	instance.Parent = grid.markers
	instance.Visible = visible
	
	local window = grid:FindFirstAncestorOfClass'DockWidgetPluginGui'
	
	function new.setSize(size)
		instance.Size = UDim2.fromOffset(size.X * cellSize, size.Y * cellSize)
		new.size = size
	end
	function new.setPosition(pos)
		local center = grid.AbsoluteCanvasSize/2
		instance.Position = UDim2.fromOffset(center.X + pos.X * cellSize, center.Y - pos.Y * cellSize)
		new.position = pos
	end
	function new.setName(name)
		instance.background.name.Text = name
		new.name = name
	end
	function new.setColor(color)
		instance.background.BackgroundColor3 = color
		new.color = color
	end
	function new.addOutput(cabel, marker)
		if #new.outputs == maxOutputs then 
			cabel:Destroy()
			return 
		end
		
		local newOutput: output = {}
		
		local ancestor: marker = markersDecryptor.fire(marker)
		
		newOutput.cabel = cabel
		newOutput.ancestor = ancestor
		
		table.insert(new.outputs, newOutput)
		
		cabel.Text = table.find(new.outputs, newOutput)
		
		cabel.MouseButton2Up:Once(function() 
			new.delOutput(newOutput)
		end)
		
		new.outputAdded.callbacks.fire(newOutput)
		
		return newOutput
	end
	function new.delOutput(output)
		output.cabel:Destroy()
		table.remove(new.outputs, table.find(new.outputs, output))
		
		for i,v in next, new.outputs do
			v.cabel.Text = i
		end
		
		new.outputRemoved.callbacks.fire(output)
	end
	
	local function getMousePosition(): NVector2.object
		local newPosition = --[[new]] NVector2()
		
		newPosition += window:GetRelativeMousePosition()
		newPosition -= shared.getAbsoluteGuiPosition(grid)
		newPosition += grid.CanvasPosition
		newPosition -= grid.AbsoluteCanvasSize/2
		newPosition *= rightsidedVector
		newPosition //= cellSize
		newPosition -= Vector2.yAxis
		
		return newPosition
	end
	local function setCabelPosition(cabel, point0, point1)
		local deltaPoint = point1 - point0

		deltaPoint *= rightsidedVector
		local magnitude = deltaPoint.Magnitude

		cabel.Size = UDim2.fromOffset(cabelWidth, magnitude)
		local rotation = 90 - math.deg(math.atan(deltaPoint.Y/deltaPoint.X))

		cabel.Rotation = rotation 
		local omegaDelta2 = (point0 + point1)/2

		local position = omegaDelta2 - gridAbsolutePosition + grid.CanvasPosition
		cabel.Position = UDim2.fromOffset(position.X, position.Y)
	end
	local function renameMarker()
		local name = instance.background.name
		
		name.TextEditable = true
		name:CaptureFocus()
		name.FocusLost:Wait()
		name.TextEditable = false
		
		new.setName(name.Text)
	end
	local function selectMarkerColor()
		local mouse = window:GetRelativeMousePosition()
		
		local newColor = shared.selectColor(new.color, mouse)
		
		new.setColor(newColor)
	end
	
	new.setSize(size)
	new.setPosition(position)
	new.setName(name)
	new.setColor(color)
	
	new.outputs = {}
	
	new.hash = hash or tostring(new):sub(8, -1)
	
	if nHaveInput then
		instance.input.Visible = false
	end
	if maxOutputs <= 0 then
		instance.output.Visible = false
	end
	
	local doubleClickedEvent: event.object<> = --[[new]] event()
	local outputAddedEvent: event.object<output> = --[[new]] event()
	local outputRemovedEvent: event.object<output> = --[[new]] event()
	local destroyedEvent: event.object<> = --[[new]] event()
	
	local markerConnect: SMKConnection.object = markersDecryptor.connect(new, new.hash)

	function new.destroy()
		for _,v in next, new.outputs do
			v.cabel:Destroy()
		end

		instance.Parent = nil
		new = nil

		markerConnect.disconnect()
		destroyedEvent.callbacks.fire()
	end
	
	local markerSections = {
		rename      = {title = 'Rename',       icon = 'rbxassetid://7130584205'},
		changeColor = {title = 'Change color', icon = 'rbxassetid://7130584205'},
		edit        = {title = 'Edit',         icon = 'rbxassetid://7130584205'},
		delete      = {title = 'Delete',       icon = ''},
	}
	
	local markerPin: pin.object = --[[new]] pin(instance.background.open, markerSections, true)
	
	if locked then
		for _,v in next, markerPin.sections do
			v.TextTransparency = .75
		end
	else
		markerPin.sections.rename.MouseButton1Up:Connect(renameMarker)
		markerPin.sections.delete.MouseButton1Up:Connect(new.destroy)
		markerPin.sections.changeColor.MouseButton1Up:Connect(selectMarkerColor)
	end
	
	new.pin = markerPin
	
	new.nHaveInput = nHaveInput
	new.maxOutputs = maxOutputs
	new.instance = instance
	
	new.position = position
	new.size = size
	
	new.tag = defaultTag
	
	new.opened = instance.background.open.MouseButton1Up
	new.clicked = instance.background.open.MouseButton1Down
	
	new.inputSelected = instance.input.MouseButton1Down
	new.outputSelected = instance.output.MouseButton1Down
	
	new.doubleClicked = doubleClickedEvent
	new.outputAdded = outputAddedEvent
	new.outputRemoved = outputRemovedEvent
	new.destroyed = destroyedEvent
	
	if outputs then
		for i,hash in next, outputs do
			local newCabel = cabelPattern:Clone()

			newCabel.Parent = grid.cabels
			newCabel.Visible = true

			new.addOutput(newCabel, hash)
		end
	end
	
	local absolutePosition = shared.getAbsoluteGuiPosition
	
	do -- events
		new.clicked:Connect(function() -- TODO: moving
			local alphaMouse = getMousePosition()
			local deltaPosition = alphaMouse - new.position

			local pressed = true
			task.spawn(function() 
				repeat task.wait()

					alphaMouse = getMousePosition() - deltaPosition
					new.setPosition(alphaMouse.toVector2())
				until not pressed
			end)

			new.opened:Wait()
			pressed = false
		end)
		new.clicked:Connect(function() -- TODO: double clicked
			local alphaTime = tick()
			local deltaTime

			local function timeCheck()
				deltaTime = tick()
				if deltaTime - alphaTime > doubleClickDelta then return true end
			end

			new.opened:Wait()
			if timeCheck() then return end
			new.clicked:Wait()
			if timeCheck() then return end
			new.opened:Wait()
			if timeCheck() then return end

			new.doubleClicked.callbacks.fire()
		end)
		new.outputSelected:Connect(function() -- TODO: input find
			local cabel = cabelPattern:Clone()

			cabel.Parent = grid.cabels
			cabel.Visible = true

			local selectedMarker
			local pressed = true
			local connects = {}

			local outputAbsolutePosition = absolutePosition(instance.output)

			local function markerInputSelectConstructor(marker: object)
				return function()
					selectedMarker = marker
					pressed = false
				end
			end

			for _,markerInstance in next, grid.markers:GetChildren() do
				if markerInstance == new.instance then continue end
				local hash = markerInstance:GetAttribute'hash'

				local marker: object = markersDecryptor.fire(hash)

				local connect = markerInstance.input.MouseButton1Up:Connect(
					markerInputSelectConstructor(marker)
				)
				table.insert(connects, connect)
			end
			table.insert(connects, 
				grid.mover.MouseButton1Up:Connect(markerInputSelectConstructor())
			)
			repeat task.wait()
				local mousePosition = window:GetRelativeMousePosition()
				local outputPosition: Vector2 = absolutePosition(instance.output)
				
				mousePosition = outputPosition:Lerp(mousePosition, .99)
				
				setCabelPosition(cabel, 
					outputPosition, 
					mousePosition
				)
			until not pressed

			for _,v in next, connects do
				v:Disconnect()
			end

			if selectedMarker then
				new.addOutput(cabel, selectedMarker.hash)
			else
				cabel:Destroy()
			end
		end)
	end
	
	do -- responsibilities
		coroutine.wrap(function() -- TODO: cabels update
			local deltas = {}
			
			while instance.Parent do
				for i,v in next, new.outputs do
					local hash = v.ancestor.hash
					local vinstance = v.ancestor.instance
					
					if not vinstance.Parent then
						table.remove(new.outputs, i)
						v.cabel:Destroy()
						deltas[hash] = nil
						continue
					end
					local delta = deltas[hash]
					if not delta then
						deltas[hash] = {}
						continue
					end
					if delta.input ~= vinstance.Position 
						or delta.output ~= instance.Position then
						setCabelPosition(v.cabel, 
							absolutePosition(instance.output),
							absolutePosition(vinstance.input)
						)
					end
					delta.input = vinstance.Position
					delta.output = instance.Position
				end
				task.wait()
			end
		end)()
	end
	
	instance:SetAttribute('hash', new.hash)
	
	local function tostringMarker(_)
		local result = '{'
		
		result ..= `color=Color3.new({new.color});`
		result ..= `name=\`{new.name}\`;`
		result ..= `position=Vector2.new({new.position});`
		result ..= `size=Vector2.new({new.size});`
		result ..= `maxOutputs={maxOutputs};`
		result ..= `locked={locked};`
		result ..= `nHaveInput={nHaveInput};`
			
		result ..= `outputs=\{`
		for i,v in next, new.outputs do
			result ..= `[{i}]=\`{v.ancestor.hash}\`;`
		end
		result ..= `\};`
		
		return `{result}\}`
	end
	
	local newMetatable: metatable.object = {}
	
	newMetatable.__tostring = tostringMarker
	
	new = setmetatable(new, newMetatable)
	
	return new
end

shared.markerConstructor = marker

return marker
