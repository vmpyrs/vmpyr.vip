local a, b, c, d = (function(e)
	local f = { [{}] = true }
	local g
	local h = {}
	local require
	local i = {}
	g = function(j, k)
		if not h[j] then
			h[j] = k
		end
	end
	require = function(j)
		local l = i[j]
		if l then
			if l == f then
				return nil
			end
		else
			if not h[j] then
				if not e then
					local m = type(j) == "string" and '"' .. j .. '"' or tostring(j)
					error("Tried to require " .. m .. ", but no such module has been registered")
				else
					return e(j)
				end
			end
			i[j] = f
			l = h[j](require, i, g, h)
			i[j] = l
		end
		return l
	end
	return require, i, g, h
end)(require)
c("__root", function(require, n, c, d)
	return require("deps.init")
end)
c("deps.init", function(require, n, c, d)
	local o = {}
	o._started = false
	o._globalRefreshRequested = false
	o._localRefreshActive = false
	o._widgets = {}
	o._rootConfig = {}
	o._config = o._rootConfig
	o._rootWidget = { ID = "R", type = "Root", Instance = o._rootInstance, ZIndex = 0 }
	o._states = {}
	o._IDStack = { "R" }
	o._usedIDs = {}
	o._stackIndex = 1
	o._cycleTick = 0
	o._widgetCount = 0
	o._postCycleCallbacks = {}
	o._connectedFunctions = {}
	function o._generateSelectionImageObject()
		if o.SelectionImageObject then
			o.SelectionImageObject:Destroy()
		end
		local p = Instance.new("Frame")
		o.SelectionImageObject = p
		p.BackgroundColor3 = o._config.SelectionImageObjectColor
		p.BackgroundTransparency = o._config.SelectionImageObjectTransparency
		p.Position = UDim2.fromOffset(-1, -1)
		p.Size = UDim2.new(1, 2, 1, 2)
		p.BorderSizePixel = 0
		local q = Instance.new("UIStroke")
		q.Thickness = 1
		q.Color = o._config.SelectionImageObjectBorderColor
		q.Transparency = o._config.SelectionImageObjectBorderColor
		q.LineJoinMode = Enum.LineJoinMode.Round
		q.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		q.Parent = p
		local r = Instance.new("UICorner")
		r.CornerRadius = UDim.new(0, 2)
		r.Parent = p
	end
	function o._generateRootInstance()
		o._rootInstance = o._widgets["Root"].Generate(o._widgets["Root"])
		o._rootInstance.Parent = o.parentInstance
		o._rootWidget.Instance = o._rootInstance
	end
	function o._deepCompare(s, t)
		for u, v in s do
			local w = t[u]
			if type(v) == "table" then
				if w and type(w) == "table" then
					if o._deepCompare(v, w) == false then
						return false
					end
				else
					return false
				end
			else
				if type(v) ~= type(w) or v ~= w then
					return false
				end
			end
		end
		return true
	end
	function o._getID(x)
		local u = 1 + (x or 1)
		local y = ""
		local z = debug.info(u, "l")
		while z ~= -1 and z ~= nil do
			y = y .. "+" .. z
			u = u + 1
			z = debug.info(u, "l")
		end
		if o._usedIDs[y] then
			o._usedIDs[y] = o._usedIDs[y] + 1
		else
			o._usedIDs[y] = 1
		end
		return y .. ":" .. o._usedIDs[y]
	end
	function o._generateEmptyVDOM()
		return { ["R"] = o._rootWidget }
	end
	o._lastVDOM = o._generateEmptyVDOM()
	o._VDOM = o._generateEmptyVDOM()
	function o._cycle()
		o._rootWidget.lastCycleTick = o._cycleTick
		if o._rootInstance == nil or o._rootInstance.Parent == nil then
			o.ForceRefresh()
		end
		for A, B in o._lastVDOM do
			if B.lastCycleTick ~= o._cycleTick then
				o._DiscardWidget(B)
			end
		end
		o._lastVDOM = o._VDOM
		o._VDOM = o._generateEmptyVDOM()
		for u, C in o._postCycleCallbacks do
			C()
		end
		if o._globalRefreshRequested then
			o._generateSelectionImageObject()
			o._globalRefreshRequested = false
			for u, B in o._lastVDOM do
				o._DiscardWidget(B)
			end
			o._generateRootInstance()
			o._lastVDOM = o._generateEmptyVDOM()
		end
		o._cycleTick = o._cycleTick + 1
		o._widgetCount = 0
		table.clear(o._usedIDs)
		if
			o.parentInstance:IsA("GuiBase2d")
			and math.min(o.parentInstance.AbsoluteSize.X, o.parentInstance.AbsoluteSize.Y) < 100
		then
			error("Iris Parent Instance is too small")
		end
		local D = o.parentInstance:IsA("GuiBase2d")
			or o.parentInstance:IsA("CoreGui")
			or o.parentInstance:IsA("PluginGui")
			or o.parentInstance:IsA("PlayerGui")
		if D == false then
			error("Iris Parent Instance cant contain GUI")
		end
		for A, E in o._connectedFunctions do
			local F, G = pcall(E)
			if not F then
				o._stackIndex = 1
				error(G, 0)
			end
			if o._stackIndex ~= 1 then
				o._stackIndex = 1
				error("Callback has too few calls to Iris.End()", 0)
			end
		end
	end
	function o._GetParentWidget()
		return o._VDOM[o._IDStack[o._stackIndex]]
	end
	o.Args = {}
	function o.ForceRefresh()
		o._globalRefreshRequested = true
	end
	function o._NoOp() end
	function o.WidgetConstructor(type, H, I, J)
		local K = {
			All = { Required = { "Generate", "Discard", "Update", "Args" }, Optional = {} },
			IfState = { Required = { "GenerateState", "UpdateState" }, Optional = {} },
			IfChildren = { Required = { "ChildAdded" }, Optional = { "ChildDiscarded" } },
		}
		local L = {}
		for A, B in K.All.Required do
			assert(J[B], B .. " is required for all widgets")
			L[B] = J[B]
		end
		for A, B in K.All.Optional do
			if J[B] == nil then
				L[B] = o._NoOp
			else
				L[B] = J[B]
			end
		end
		if H then
			for A, B in K.IfState.Required do
				assert(J[B], B .. " is required for all widgets with state")
				L[B] = J[B]
			end
			for A, B in K.IfState.Optional do
				if J[B] == nil then
					L[B] = o._NoOp
				else
					L[B] = J[B]
				end
			end
		end
		if I then
			for A, B in K.IfChildren.Required do
				assert(J[B], B .. " is required for all widgets with children")
				L[B] = J[B]
			end
			for A, B in K.IfChildren.Optional do
				if J[B] == nil then
					L[B] = o._NoOp
				else
					L[B] = J[B]
				end
			end
		end
		L.hasState = H
		L.hasChildren = I
		o._widgets[type] = L
		o.Args[type] = L.Args
		local M = {}
		for u, B in L.Args do
			M[B] = u
		end
		L.ArgNames = M
	end
	function o.UpdateGlobalConfig(N)
		for u, B in N do
			o._rootConfig[u] = B
		end
		o.ForceRefresh()
	end
	function o.PushConfig(N)
		local y = o.State(-1)
		if y.value == -1 then
			y:set(N)
		else
			if o._deepCompare(y:get(), N) == false then
				o._localRefreshActive = true
				y:set(N)
			end
		end
		o._config = setmetatable(N, { __index = o._config })
	end
	function o.PopConfig()
		o._localRefreshActive = false
		o._config = getmetatable(o._config).__index
	end
	local O = {}
	O.__index = O
	function O:get()
		return self.value
	end
	function O:set(P)
		self.value = P
		for A, L in self.ConnectedWidgets do
			o._widgets[L.type].UpdateState(L)
		end
		for A, Q in self.ConnectedFunctions do
			Q(P)
		end
		return self.value
	end
	function O:onChange(R)
		table.insert(self.ConnectedFunctions, R)
	end
	function o.State(S)
		local y = o._getID(2)
		if o._states[y] then
			return o._states[y]
		else
			o._states[y] = { value = S, ConnectedWidgets = {}, ConnectedFunctions = {} }
			setmetatable(o._states[y], O)
			return o._states[y]
		end
	end
	function o.ComputedState(T, U)
		local y = o._getID(2)
		if o._states[y] then
			return o._states[y]
		else
			o._states[y] = { value = U(T), ConnectedWidgets = {}, ConnectedFunctions = {} }
			T:onChange(function(P)
				o._states[y]:set(U(P))
			end)
			setmetatable(o._states[y], O)
			return o._states[y]
		end
	end
	function o._widgetState(L, V, S)
		local y = L.ID .. V
		if o._states[y] then
			o._states[y].ConnectedWidgets[L.ID] = L
			return o._states[y]
		else
			o._states[y] = { value = S, ConnectedWidgets = { [L.ID] = L }, ConnectedFunctions = {} }
			setmetatable(o._states[y], O)
			return o._states[y]
		end
	end
	function o.Init(W, X)
		if W == nil then
			W = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
		end
		if X == nil then
			X = game:GetService("RunService").Heartbeat
		end
		o.parentInstance = W
		assert(not o._started, "Iris.Connect can only be called once.")
		o._started = true
		o._generateRootInstance()
		o._generateSelectionImageObject()
		task.spawn(function()
			if typeof(X) == "function" then
				while true do
					X()
					o._cycle()
				end
			else
				X:Connect(function()
					o._cycle()
				end)
			end
		end)
		return o
	end
	function o:Connect(E)
		table.insert(o._connectedFunctions, E)
	end
	function o._DiscardWidget(Y)
		local Z = Y.parentWidget
		if Z then
			o._widgets[Z.type].ChildDiscarded(Z, Y)
		end
		o._widgets[Y.type].Discard(Y)
	end
	function o._GenNewWidget(_, a0, a1, y)
		local a2 = o._IDStack[o._stackIndex]
		local a3 = o._VDOM[a2]
		local a4 = o._widgets[_]
		local L = {}
		setmetatable(L, L)
		L.ID = y
		L.type = _
		L.parentWidget = a3
		L.events = {}
		local a5 = o._config.Parent and o._config.Parent or o._widgets[a3.type].ChildAdded(a3, L)
		L.ZIndex = a3.ZIndex + o._widgetCount * 0x40 + o._config.ZIndexOffset
		L.Instance = a4.Generate(L)
		L.Instance.Parent = a5
		L.arguments = a0
		a4.Update(L)
		if a4.hasState then
			if a1 then
				for u, B in a1 do
					if not (type(B) == "table" and getmetatable(B) == O) then
						a1[u] = o._widgetState(L, u, B)
					end
				end
				L.state = a1
				for u, B in a1 do
					B.ConnectedWidgets[L.ID] = L
				end
			else
				L.state = {}
			end
			a4.GenerateState(L)
			a4.UpdateState(L)
			L.stateMT = {}
			setmetatable(L.state, L.stateMT)
		end
		return L
	end
	function o._Insert(_, a6, a1)
		local L
		local y = o._getID(3)
		local a4 = o._widgets[_]
		o._widgetCount = o._widgetCount + 1
		if o._VDOM[y] then
			error("Multiple widgets cannot occupy the same ID", 3)
		end
		local a0 = {}
		if a6 ~= nil then
			if type(a6) ~= "table" then
				error("Args must be a table.", 3)
			end
			for u, B in a6 do
				a0[a4.ArgNames[u]] = B
			end
		end
		table.freeze(a0)
		if o._lastVDOM[y] and _ == o._lastVDOM[y].type then
			if o._localRefreshActive then
				o._DiscardWidget(o._lastVDOM[y])
			else
				L = o._lastVDOM[y]
			end
		end
		if L == nil then
			L = o._GenNewWidget(_, a0, a1, y)
		end
		if o._deepCompare(L.arguments, a0) == false then
			L.arguments = a0
			a4.Update(L)
		end
		local a7 = L.events
		L.events = {}
		if a4.hasState then
			L.__index = L.state
			L.stateMT.__index = a7
		else
			L.__index = a7
		end
		L.lastCycleTick = o._cycleTick
		if a4.hasChildren then
			o._stackIndex = o._stackIndex + 1
			o._IDStack[o._stackIndex] = L.ID
		end
		o._VDOM[y] = L
		return L
	end
	function o.Append(a8)
		local a3 = o._GetParentWidget()
		local a5
		if o._config.Parent then
			a5 = o._config.Parent
		else
			a5 = o._widgets[a3.type].ChildAdded(a3, { type = "userInstance" })
		end
		a8.Parent = a5
	end
	function o.End()
		if o._stackIndex == 1 then
			error("Callback has too many calls to Iris.End()", 2)
		end
		o._IDStack[o._stackIndex] = nil
		o._stackIndex = o._stackIndex - 1
	end
	o.TemplateConfig = require("deps.config")
	o.UpdateGlobalConfig(o.TemplateConfig.colorDark)
	o.UpdateGlobalConfig(o.TemplateConfig.sizeDefault)
	o.UpdateGlobalConfig(o.TemplateConfig.utilityDefault)
	o._globalRefreshRequested = false
	require("deps.widgets")(o)
	o.ShowDemoWindow = require("deps.demoWindow")(o)
	return o
end)
c("deps.demoWindow", function(require, n, c, d)
	return function(o)
		local a9 = o.State(false)
		local aa = o.State(false)
		local ab = o.State(false)
		local ac = o.State(false)
		local ad = o.State(false)
		local ae = {
			Basic = function()
				o.Tree({ "Basic" })
				o.Button({ "Button" })
				o.SmallButton({ "SmallButton" })
				o.Text({ "Text" })
				o.TextWrapped({ string.rep("Text Wrapped ", 5) })
				o.PushConfig({ TextColor = Color3.fromRGB(255, 128, 0) })
				o.Text({ "Colored Text" })
				o.PopConfig()
				o.End()
			end,
			Tree = function()
				o.Tree({ "Trees" })
				o.Tree({ "Tree using SpanAvailWidth", [o.Args.Tree.SpanAvailWidth] = true })
				o.End()
				local af = o.Tree({ "Tree with Children" })
				o.Text({ "Im inside the first tree!" })
				o.Button({ "Im a button inside the first tree!" })
				o.Tree({ "Im a tree inside the first tree!" })
				o.Text({ "I am the innermost text!" })
				o.End()
				o.End()
				o.Checkbox({ "Toggle above tree" }, { isChecked = af.state.isUncollapsed })
				o.End()
			end,
			Group = function()
				o.Tree({ "Groups" })
				o.SameLine()
				o.Group()
				o.Text({ "I am in group A" })
				o.Button({ "Im also in A" })
				o.End()
				o.Separator()
				o.Group()
				o.Text({ "I am in group B" })
				o.Button({ "Im also in B" })
				o.Button({ "Also group B" })
				o.End()
				o.End()
				o.End()
			end,
			Indent = function()
				o.Tree({ "Indents" })
				o.Text({ "Not Indented" })
				o.Indent()
				o.Text({ "Indented" })
				o.Indent({ 7 })
				o.Text({ "Indented by 7 more pixels" })
				o.End()
				o.Indent({ -7 })
				o.Text({ "Indented by 7 less pixels" })
				o.End()
				o.End()
				o.End()
			end,
			InputNum = function()
				o.Tree({ "Input Num" })
				local ag, ah, ai, aj, ak, al =
					o.State(false), o.State(false), o.State(0), o.State(100), o.State(1), o.State("%d")
				local am = o.InputNum({
					"Input Number",
					[o.Args.InputNum.NoField] = ag.value,
					[o.Args.InputNum.NoButtons] = ah.value,
					[o.Args.InputNum.Min] = ai.value,
					[o.Args.InputNum.Max] = aj.value,
					[o.Args.InputNum.Increment] = ak.value,
					[o.Args.InputNum.Format] = al.value,
				})
				o.Text({ string.format("The Value is: %d", am.number.value) })
				if o.Button({ "Randomize Number" }).clicked then
					am.number:set(math.random(1, 99))
				end
				o.Separator()
				o.Checkbox({ "NoField" }, { isChecked = ag })
				o.Checkbox({ "NoButtons" }, { isChecked = ah })
				o.End()
			end,
			InputText = function()
				o.Tree({ "Input Text" })
				o.PushConfig({ ContentWidth = UDim.new(0, 250) })
				local an = o.InputText({ "Input Text Test", [o.Args.InputText.TextHint] = "Input Text here" })
				o.PopConfig()
				o.Text({ string.format("The text is: %s", an.text.value) })
				o.End()
			end,
		}
		local ao = { "Basic", "Tree", "Group", "Indent", "InputNum", "InputText" }
		local function ap()
			local aq = o.Tree({ "Recursive Tree" })
			if aq.state.isUncollapsed.value then
				ap()
			end
			o.End()
		end
		local function ar(as)
			o.Window({ "Recursive Window" }, { size = o.State(Vector2.new(150, 100)), isOpened = as })
			local at = o.Checkbox({ "Recurse Again" })
			o.End()
			if at.isChecked.value then
				ar(at.isChecked)
			end
		end
		local function au()
			local function av(aw)
				o.Table({ #aw[1] })
				for u, B in aw do
					for u, w in B do
						o.NextColumn()
						o.Text({ tostring(w) })
					end
				end
				o.End()
			end
			o.Window({ "Widget Info" }, { size = o.State(Vector2.new(600, 300)), isOpened = aa })
			o.Text({ "information of Iris Widgets." })
			o.Table({ 1, [o.Args.Table.RowBg] = false })
			o.NextColumn()
			o.Tree({ "\nIris.Text\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" }, { "Text: String", "", "" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.TextWrapped\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" }, { "Text: String", "", "" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Button\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" }, { "Text: string", "clicked: boolean", "" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.SmallButton\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" }, { "Text: string", "clicked: boolean", "" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Separator\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Indent\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" }, { "Width: number", "", "" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.SameLine\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Width: number", "", "" },
				{ "VerticalAlignment: Enum.VerticalAlignment", "", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Group\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({ { "Arguments", "Events", "States" } })
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Checkbox\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Text: string", "checked: boolean", "isChecked: boolean" },
				{ "", "unchecked: boolean", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Tree\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Text: string", "collapsed: boolean", "isUncollapsed: boolean" },
				{ "SpanAvailWidth: boolean", "uncollapsed: boolean", "" },
				{ "NoIndent: boolean", "", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.InputNum\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Text: string", "numberChanged: boolean", "number: number" },
				{ "Increment: number", "", "" },
				{ "Min: number", "", "" },
				{ "Max: number", "", "" },
				{ "Format: string", "", "" },
				{ "NoButtons: boolean", "", "" },
				{ "NoField: boolean", "", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.InputText\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Text: string", "textChanged: boolean", "text: string" },
				{ "TextHint: string", "", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Table\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "NumColumns: number", "", "" },
				{ "RowBg: boolean", "", "" },
				{ "BordersOuter: boolean", "", "" },
				{ "BordersInner: boolean", "", "" },
			})
			o.End()
			o.NextColumn()
			o.Tree({ "\nIris.Window\n", [o.Args.Tree.NoIndent] = true, [o.Args.Tree.SpanAvailWidth] = true })
			av({
				{ "Arguments", "Events", "States" },
				{ "Title: string", "closed: boolean", "size: Vector2" },
				{ "NoTitleBar: boolean", "opened: boolean", "position: Vector2" },
				{ "NoBackground: boolean", "collapsed: boolean", "isUncollapsed: boolean" },
				{ "NoCollapse: boolean", "uncollapsed: boolean", "isOpened: boolean" },
				{ "NoClose: boolean", "", "scrollDistance: number" },
				{ "NoMove: boolean", "", "" },
				{ "NoScrollbar: boolean", "", "" },
				{ "NoResize: boolean", "", "" },
			})
			o.End()
			o.End()
			o.End()
		end
		local function ax()
			local ay = o.Window({ "Runtime Info" }, { isOpened = ab })
			local az = o._lastVDOM
			local aA = o._states
			local aB = o.State(0)
			local aC = o.State(os.clock())
			local aD = os.clock()
			local aE = aD - aC.value
			aB.value = aB.value + (aE - aB.value) * 0.2
			aC.value = aD
			o.Text({ string.format("Average %.3f ms/frame (%.1f FPS)", aB.value * 1000, 1 / aB.value) })
			o.Text({
				string.format(
					"Window Position: (%d, %d), Window Size: (%d, %d)",
					ay.position.value.X,
					ay.position.value.Y,
					ay.size.value.X,
					ay.size.value.Y
				),
			})
			o.PushConfig({ ItemWidth = UDim.new(0.5, 100) })
			local aF = o.InputText({ "Enter an ID to learn more about it." }, { text = o.State(ay.ID) }).text.value
			o.PopConfig()
			o.Indent()
			local aG = az[aF]
			local aH = aA[aF]
			if aG then
				o.Table({ 1, [o.Args.Table.RowBg] = false })
				o.Text({ string.format('The ID, "%s", is a widget', aF) })
				o.NextRow()
				o.Text({ string.format("Widget is type: %s", aG.type) })
				o.NextRow()
				o.Tree({ "Widget has Args:" }, { isUncollapsed = o.State(true) })
				for u, B in aG.arguments do
					o.Text({ u .. " - " .. tostring(B) })
				end
				o.End()
				o.NextRow()
				if aG.state then
					o.Tree({ "Widget has State:" }, { isUncollapsed = o.State(true) })
					for u, B in aG.state do
						o.Text({ u .. " - " .. tostring(B.value) })
					end
					o.End()
				end
				o.End()
			elseif aH then
				o.Table({ 1, [o.Args.Table.RowBg] = false })
				o.Text({ string.format('The ID, "%s", is a state', aF) })
				o.NextRow()
				o.Text({ string.format("Value is type: %s, Value = %s", typeof(aH.value), tostring(aH.value)) })
				o.NextRow()
				o.Tree({ "state has connected widgets:" }, { isUncollapsed = o.State(true) })
				for u, B in aH.ConnectedWidgets do
					o.Text({ u .. " - " .. B.type })
				end
				o.End()
				o.NextRow()
				o.Text({ string.format("state has: %d connected functions", #aH.ConnectedFunctions) })
				o.End()
			else
				o.Text({ string.format('The ID, "%s", is not a state or widget', aF) })
			end
			o.End()
			if o.Tree({ "Widgets" }).isUncollapsed.value then
				local aI = 0
				local aJ = ""
				for u, B in az do
					aI = aI + 1
					aJ = aJ .. "\n" .. B.ID .. " - " .. B.type
				end
				o.Text({ string.format("Number of Widgets: %d", aI) })
				o.Text({ aJ })
			end
			o.End()
			if o.Tree({ "States" }).isUncollapsed.value then
				local aK = 0
				local aL = ""
				for u, B in aA do
					aK = aK + 1
					aL = aL .. "\n" .. u .. " - " .. tostring(B.value)
				end
				o.Text({ string.format("Number of States: %d", aK) })
				o.Text({ aL })
			end
			o.End()
			o.End()
		end
		local aM
		do
			local aN = {}
			do
				for u, B in o._config do
					if typeof(B) == "Color3" then
						aN[u .. "R"] = o.State(B.R * 255)
						aN[u .. "G"] = o.State(B.G * 255)
						aN[u .. "B"] = o.State(B.B * 255)
					elseif typeof(B) == "UDim" then
						aN[u .. "Scale"] = o.State(B.Scale)
						aN[u .. "Offset"] = o.State(B.Offset)
					elseif typeof(B) == "Vector2" then
						aN[u .. "X"] = o.State(B.X)
						aN[u .. "Y"] = o.State(B.Y)
					elseif typeof(B) == "EnumItem" then
						aN[u] = o.State(B.Name)
					else
						aN[u] = o.State(B)
					end
				end
			end
			local function aO()
				for u, B in o._config do
					if typeof(B) == "Color3" then
						aN[u .. "R"]:set(B.R * 255)
						aN[u .. "G"]:set(B.G * 255)
						aN[u .. "B"]:set(B.B * 255)
					elseif typeof(B) == "UDim" then
						aN[u .. "Scale"]:set(B.Scale)
						aN[u .. "Offset"]:set(B.Offset)
					elseif typeof(B) == "Vector2" then
						aN[u .. "X"]:set(B.X)
						aN[u .. "Y"]:set(B.Y)
					elseif typeof(B) == "EnumItem" then
						aN[u]:set(B.Name)
					else
						aN[u]:set(B)
					end
				end
			end
			local function aP(j)
				o.PushConfig({ ContentWidth = UDim.new(0, 100 - o._config.ItemInnerSpacing.X) })
				o.SameLine()
				local aQ = o.InputNum(
					{ "", [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "X"] }
				)
				local aR = o.InputNum(
					{ j, [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "Y"] }
				)
				if aQ.numberChanged or aR.numberChanged then
					o.UpdateGlobalConfig({ [j] = Vector2.new(aQ.number.value, aR.number.value) })
				end
				o.End()
				o.PopConfig()
			end
			local function aS(j)
				o.PushConfig({ ContentWidth = UDim.new(0, 100 - o._config.ItemInnerSpacing.X) })
				o.SameLine()
				local aT = o.InputNum(
					{ "", [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "Scale"] }
				)
				local aU = o.InputNum(
					{ j, [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "Offset"] }
				)
				if aT.numberChanged or aU.numberChanged then
					o.UpdateGlobalConfig({ [j] = UDim.new(aT.number.value, aU.number.value) })
				end
				o.End()
				o.PopConfig()
			end
			local function aV(j, aW)
				o.PushConfig({ ContentWidth = UDim.new(0, 50 - o._config.ItemInnerSpacing.X) })
				o.SameLine()
				local aX = o.InputNum(
					{ "", [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "R"] }
				)
				local aY = o.InputNum(
					{ "", [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "G"] }
				)
				local aZ = o.InputNum(
					{ "", [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j .. "B"] }
				)
				local a_ = o.InputNum(
					{ j, [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%.3f" },
					{ number = aN[aW] }
				)
				if aX.numberChanged or aY.numberChanged or aZ.numberChanged or a_.numberChanged then
					o.UpdateGlobalConfig({
						[j] = Color3.fromRGB(aX.number.value, aY.number.value, aZ.number.value),
						[aW] = a_.number.value,
					})
				end
				o.End()
				o.PopConfig()
			end
			local function b0(j)
				o.PushConfig({ ContentWidth = UDim.new(0, 200) })
				local b1 = o.InputNum(
					{ j, [o.Args.InputNum.NoButtons] = true, [o.Args.InputNum.Format] = "%d" },
					{ number = aN[j] }
				)
				if b1.numberChanged then
					o.UpdateGlobalConfig({ [j] = b1.number.value })
				end
				o.PopConfig()
			end
			local function b2(j, b3, b4)
				o.PushConfig({ ContentWidth = UDim.new(0, 200) })
				local b5 = o.InputText({ j }, { text = aN[j] })
				if b5.textChanged then
					local b6 = false
					for A, b7 in ipairs(b3:GetEnumItems()) do
						if b7.Name == b5.text.value then
							b6 = true
							break
						end
					end
					if b6 then
						o.UpdateGlobalConfig({ [j] = b3[b5.text.value] })
					else
						o.UpdateGlobalConfig({ [j] = b4 })
						aN[j]:set(tostring(b4))
					end
				end
				o.PopConfig()
			end
			local b8 = {
				{
					[0] = "Sizes",
					function()
						o.Text({ "Main" })
						aP("WindowPadding")
						aP("WindowResizePadding")
						aP("FramePadding")
						aP("CellPadding")
						aP("ItemSpacing")
						aP("ItemInnerSpacing")
						b0("IndentSpacing")
						b0("ScrollbarSize")
						o.Text({ "Borders" })
						b0("WindowBorderSize")
						b0("FrameBorderSize")
						o.Text({ "Rounding" })
						b0("FrameRounding")
						o.Text({ "Alignment" })
						b2("WindowTitleAlign", Enum.LeftRight, Enum.LeftRight.Left)
						o.Text({ "Widths" })
						aS("ItemWidth")
						aS("ContentWidth")
					end,
				},
				{
					[0] = "Colors",
					function()
						aV("TextColor", "TextTransparency")
						aV("TextDisabledColor", "TextDisabledTransparency")
						aV("BorderColor", "BorderTransparency")
						aV("BorderActiveColor", "BorderActiveTransparency")
						aV("WindowBgColor", "WindowBgTransparency")
						aV("ScrollbarGrabColor", "ScrollbarGrabTransparency")
						aV("TitleBgColor", "TitleBgTransparnecy")
						aV("TitleBgActiveColor", "TitleBgActiveTransparency")
						aV("TitleBgCollapsedColor", "TitleBgCollapsedTransparency")
						aV("FrameBgColor", "FrameBgTransparency")
						aV("FrameBgHoveredColor", "FrameBgHoveredTransparency")
						aV("FrameBgActiveColor", "FrameBgActiveTransparency")
						aV("ButtonColor", "ButtonTransparency")
						aV("ButtonHoveredColor", "ButtonHoveredTransparency")
						aV("ButtonActiveColor", "ButtonActiveTransparency")
						aV("HeaderColor", "HeaderTransparency")
						aV("HeaderHoveredColor", "HeaderHoveredTransparency")
						aV("HeaderActiveColor", "HeaderActiveTransparency")
						aV("SelectionImageObjectColor", "SelectionImageObjectTransparency")
						aV("SelectionImageObjectBorderColor", "SelectionImageObjectBorderTransparency")
						aV("TableBorderStrongColor", "TableBorderStrongTransparency")
						aV("TableBorderLightColor", "TableBorderLightTransparency")
						aV("TableRowBgColor", "TableRowBgTransparency")
						aV("TableRowBgAltColor", "TableRowBgAltTransparency")
						aV("NavWindowingHighlightColor", "NavWindowingHighlightTransparency")
						aV("NavWindowingDimBgColor", "NavWindowingDimBgTransparency")
						aV("SeparatorColor", "SeparatorTransparency")
						aV("CheckMarkColor", "CheckMarkTransparency")
					end,
				},
				{
					[0] = "Fonts",
					function()
						b2("TextFont", Enum.Font, Enum.Font.Code)
						b0("TextSize")
					end,
				},
			}
			aM = function()
				local b9 = o.State(1)
				o.Window({ "Style Editor" }, { isOpened = ac })
				o.Text({ "Customize the look of Iris in realtime." })
				o.SameLine()
				if o.SmallButton({ "Light Theme" }).clicked then
					o.UpdateGlobalConfig(o.TemplateConfig.colorLight)
					aO()
				end
				if o.SmallButton({ "Dark Theme" }).clicked then
					o.UpdateGlobalConfig(o.TemplateConfig.colorDark)
					aO()
				end
				o.End()
				o.SameLine()
				if o.SmallButton({ "Classic Size" }).clicked then
					o.UpdateGlobalConfig(o.TemplateConfig.sizeDefault)
					aO()
				end
				if o.SmallButton({ "Larger Size" }).clicked then
					o.UpdateGlobalConfig(o.TemplateConfig.sizeClear)
					aO()
				end
				o.End()
				if o.SmallButton({ "Reset Everything" }).clicked then
					o.UpdateGlobalConfig(o.TemplateConfig.colorDark)
					o.UpdateGlobalConfig(o.TemplateConfig.sizeDefault)
					aO()
				end
				o.Separator()
				o.SameLine()
				for u, B in ipairs(b8) do
					if o.SmallButton({ B[0] }).clicked then
						b9:set(u)
					end
				end
				o.End()
				b8[b9:get()][1]()
				o.End()
			end
		end
		local function ba()
			o.Tree({ "Widget Event Interactivity" })
			local bb = o.State(0)
			if o.Button({ "Click to increase Number" }).clicked then
				bb:set(bb:get() + 1)
			end
			o.Text({ string.format("The Number is: %d", bb:get()) })
			local bc = o.State(0)
			o.SameLine()
			if o.Button({ "Click to show text for 20 frames" }).clicked then
				bc:set(20)
			end
			if bc:get() > 0 then
				o.Text({ "Here i am!" })
			end
			o.End()
			bc:set(math.max(0, bc:get() - 1))
			o.Text({ string.format("Text Timer: %d", bc:get()) })
			o.End()
		end
		local function bd()
			o.Tree({ "Widget State Interactivity" })
			local be = o.Checkbox({ "Widget-Generated State" })
			o.Text({ ("isChecked: %s\n"):format(tostring(be.state.isChecked.value)) })
			local bf = o.State(false)
			local bg = o.Checkbox({ "User-Generated State" }, { isChecked = bf })
			o.Text({ ("isChecked: %s\n"):format(tostring(bg.state.isChecked.value)) })
			local bh = o.Checkbox({ "Widget Coupled State" })
			local bi = o.Checkbox({ "Coupled to above Checkbox" }, { isChecked = bh.state.isChecked })
			o.Text({ ("isChecked: %s\n"):format(tostring(bi.state.isChecked.value)) })
			local bj = o.State(false)
			local bk = o.Checkbox({ "Widget and Code Coupled State" }, { isChecked = bj })
			local bl = o.Button({ "Click to toggle above checkbox" })
			if bl.clicked then
				bj:set(not bj:get())
			end
			o.Text({ ("isChecked: %s\n"):format(tostring(bj.value)) })
			local bm = o.State(true)
			local bn = o.ComputedState(bm, function(P)
				return not P
			end)
			local bo = o.Checkbox({ "ComputedState (dynamic coupling)" }, { isChecked = bm })
			local bo = o.Checkbox({ "Inverted of above checkbox" }, { isChecked = bn })
			o.Text({ ("isChecked: %s\n"):format(tostring(bn.value)) })
			o.End()
		end
		local function bp()
			o.Tree({ "Dynamic Styles" })
			local bq = o.State(0)
			o.SameLine()
			if o.Button({ "Change Color" }).clicked then
				bq:set(math.random())
			end
			o.Text({ string.format("Hue: %d", math.floor(bq:get() * 255)) })
			o.End()
			o.PushConfig({ TextColor = Color3.fromHSV(bq:get(), 1, 1) })
			o.Text({ "Text with a unique and changable color" })
			o.PopConfig()
			o.End()
		end
		local function br()
			local bs = o.State(false)
			o.Tree({ "Tables & Columns", [o.Args.Tree.NoIndent] = true }, { isUncollapsed = bs })
			if bs.value == false then
				o.End()
			else
				o.Text({ "Table using NextRow and NextColumn syntax:" })
				o.Table({ 3 })
				for u = 1, 4 do
					o.NextRow()
					for bt = 1, 3 do
						o.NextColumn()
						o.Text(({ "Row: %s, Column: %s" }):format(u, bt))
					end
				end
				o.End()
				o.Text({ "" })
				o.Text({ "Table using NextColumn only syntax:" })
				o.Table({ 2 })
				for u = 1, 4 do
					for bt = 1, 2 do
						o.NextColumn()
						o.Text({ ("Row: %s, Column: %s"):format(u, bt) })
					end
				end
				o.End()
				o.Separator()
				local bu = o.State(false)
				local bv = o.State(false)
				local bw = o.State(true)
				local bx = o.State(true)
				o.Text({ "Table with Customizable Arguments" })
				o.Table({
					4,
					[o.Args.Table.RowBg] = bu.value,
					[o.Args.Table.BordersOuter] = bv.value,
					[o.Args.Table.BordersInner] = bw.value,
				})
				for u = 1, 3 do
					for bt = 1, 4 do
						o.NextColumn()
						if bx.value then
							o.Button({ ("Month: %s, Week: %s"):format(u, bt) })
						else
							o.Text({ ("Month: %s, Week: %s"):format(u, bt) })
						end
					end
				end
				o.End()
				o.Checkbox({ "RowBg" }, { isChecked = bu })
				o.Checkbox({ "BordersOuter" }, { isChecked = bv })
				o.Checkbox({ "BordersInner" }, { isChecked = bw })
				o.Checkbox({ "Use Buttons" }, { isChecked = bx })
				o.End()
			end
		end
		local function by()
			o.PushConfig({ ItemWidth = UDim.new(0, 150) })
			o.TextWrapped({
				"Widgets which are placed outside of a window will appear on the top left side of the screen.",
			})
			o.Button()
			o.Tree()
			o.InputText()
			o.End()
			o.PopConfig()
		end
		return function()
			local bz = o.State(false)
			local bA = o.State(false)
			local bB = o.State(false)
			local bC = o.State(true)
			local bD = o.State(false)
			local bE = o.State(false)
			local bF = o.State(false)
			local bG = o.State(false)
			o.Window(
				{
					"Iris Demo Window (created by Alyrianix and bundled for exploit usage by littlemike57)",
					[o.Args.Window.NoTitleBar] = bz.value,
					[o.Args.Window.NoBackground] = bA.value,
					[o.Args.Window.NoCollapse] = bB.value,
					[o.Args.Window.NoClose] = bC.value,
					[o.Args.Window.NoMove] = bD.value,
					[o.Args.Window.NoScrollbar] = bE.value,
					[o.Args.Window.NoResize] = bF.value,
					[o.Args.Window.NoNav] = bG.value,
				},
				{ size = o.State(Vector2.new(600, 550)), position = o.State(Vector2.new(100, 25)) }
			)
			o.Text({ "Iris says hello!" })
			o.Separator()
			o.Table({ 3, false, false, false })
			o.NextColumn()
			o.Checkbox({ "Recursive Window" }, { isChecked = a9 })
			o.NextColumn()
			o.Checkbox({ "Widget Info" }, { isChecked = aa })
			o.NextColumn()
			o.Checkbox({ "Runtime Info" }, { isChecked = ab })
			o.NextColumn()
			o.Checkbox({ "Style Editor" }, { isChecked = ac })
			o.NextColumn()
			o.Checkbox({ "Windowless" }, { isChecked = ad })
			o.End()
			o.Separator()
			o.Tree({ "Window Options" })
			o.Table({ 3, false, false, false })
			o.NextColumn()
			o.Checkbox({ "NoTitleBar" }, { isChecked = bz })
			o.NextColumn()
			o.Checkbox({ "NoBackground" }, { isChecked = bA })
			o.NextColumn()
			o.Checkbox({ "NoCollapse" }, { isChecked = bB })
			o.NextColumn()
			o.Checkbox({ "NoClose" }, { isChecked = bC })
			o.NextColumn()
			o.Checkbox({ "NoMove" }, { isChecked = bD })
			o.NextColumn()
			o.Checkbox({ "NoScrollbar" }, { isChecked = bE })
			o.NextColumn()
			o.Checkbox({ "NoResize" }, { isChecked = bF })
			o.NextColumn()
			o.Checkbox({ "NoNav" }, { isChecked = bG })
			o.End()
			o.End()
			ba()
			bd()
			ap()
			bp()
			o.Separator()
			o.Tree({ "Widgets" })
			for A, j in ao do
				ae[j]()
			end
			o.End()
			br()
			o.End()
			if a9.value then
				ar(a9)
			end
			if aa.value then
				au()
			end
			if ab.value then
				ax()
			end
			if ac.value then
				aM()
			end
			if ad.value then
				by()
			end
		end
	end
end)
c("deps.widgets", function(require, n, c, d)
	local bH = game:GetService("GuiService")
	local bI = game:GetService("UserInputService")
	local bJ = {
		RIGHT_POINTING_TRIANGLE = "\u{25BA}",
		DOWN_POINTING_TRIANGLE = "\u{25BC}",
		MULTIPLICATION_SIGN = "\u{00D7}",
		BOTTOM_RIGHT_CORNER = "\u{25E2}",
		CHECK_MARK = "\u{2713}",
	}
	local function bK(bL, bM)
		local bK = Instance.new("UIPadding")
		bK.PaddingLeft = UDim.new(0, bM.X)
		bK.PaddingRight = UDim.new(0, bM.X)
		bK.PaddingTop = UDim.new(0, bM.Y)
		bK.PaddingBottom = UDim.new(0, bM.Y)
		bK.Parent = bL
		return bK
	end
	local function bN(bL)
		local bO = Instance.new("Folder")
		bO.Parent = bL
		return bO
	end
	local function bP(bL, bQ, bR)
		local bP = Instance.new("UISizeConstraint")
		bP.MinSize = bQ
		bP.MaxSize = bR
		bP.Parent = bL
		return bP
	end
	local function bS(bL, bT, bU)
		local bS = Instance.new("UIListLayout")
		bS.SortOrder = Enum.SortOrder.LayoutOrder
		bS.Padding = bU
		bS.FillDirection = bT
		bS.Parent = bL
		return bS
	end
	local function q(bL, bV, bW, bX)
		local q = Instance.new("UIStroke")
		q.Thickness = bV
		q.Color = bW
		q.Transparency = bX
		q.Parent = bL
		return q
	end
	local function bY(bL, bZ)
		local bY = Instance.new("UICorner")
		bY.CornerRadius = UDim.new(0, bZ)
		bY.Parent = bL
		return bY
	end
	local function b_(bL)
		local b_ = Instance.new("UITableLayout")
		b_.MajorAxis = Enum.TableMajorAxis.ColumnMajor
		b_.Parent = bL
		return b_
	end
	return function(o)
		local function c0(c1)
			c1.Font = o._config.TextFont
			c1.TextSize = o._config.TextSize
			c1.TextColor3 = o._config.TextColor
			c1.TextTransparency = o._config.TextTransparency
			c1.TextXAlignment = Enum.TextXAlignment.Left
			c1.AutoLocalize = false
			c1.RichText = false
		end
		local function c2(c3, c4, c5, c6)
			local c7 = false
			c3.MouseEnter:Connect(function()
				if c6 == "Text" then
					c4.TextColor3 = c5.ButtonHoveredColor
					c4.TextTransparency = c5.ButtonHoveredTransparency
				else
					c4.BackgroundColor3 = c5.ButtonHoveredColor
					c4.BackgroundTransparency = c5.ButtonHoveredTransparency
				end
				c7 = false
			end)
			c3.MouseLeave:Connect(function()
				if c6 == "Text" then
					c4.TextColor3 = c5.ButtonColor
					c4.TextTransparency = c5.ButtonTransparency
				else
					c4.BackgroundColor3 = c5.ButtonColor
					c4.BackgroundTransparency = c5.ButtonTransparency
				end
				c7 = true
			end)
			c3.InputBegan:Connect(function(c8)
				if
					not (
						c8.UserInputType == Enum.UserInputType.MouseButton1
						or c8.UserInputType == Enum.UserInputType.Gamepad1
					)
				then
					return
				end
				if c6 == "Text" then
					c4.TextColor3 = c5.ButtonActiveColor
					c4.TextTransparency = c5.ButtonActiveTransparency
				else
					c4.BackgroundColor3 = c5.ButtonActiveColor
					c4.BackgroundTransparency = c5.ButtonActiveTransparency
				end
			end)
			c3.InputEnded:Connect(function(c8)
				if
					not (
						c8.UserInputType == Enum.UserInputType.MouseButton1
						or c8.UserInputType == Enum.UserInputType.Gamepad1
					) or c7
				then
					return
				end
				if c8.UserInputType == Enum.UserInputType.MouseButton1 then
					if c6 == "Text" then
						c4.TextColor3 = c5.ButtonHoveredColor
						c4.TextTransparency = c5.ButtonHoveredTransparency
					else
						c4.BackgroundColor3 = c5.ButtonHoveredColor
						c4.BackgroundTransparency = c5.ButtonHoveredTransparency
					end
				end
				if c8.UserInputType == Enum.UserInputType.Gamepad1 then
					if c6 == "Text" then
						c4.TextColor3 = c5.ButtonColor
						c4.TextTransparency = c5.ButtonTransparency
					else
						c4.BackgroundColor3 = c5.ButtonColor
						c4.BackgroundTransparency = c5.ButtonTransparency
					end
				end
			end)
			c3.SelectionImageObject = o.SelectionImageObject
		end
		local function c9(c1, ca)
			local cb = o._config.FramePadding
			local cc = o._config.ButtonTransparency
			local cd = o._config.FrameBorderSize
			local ce = o._config.BorderColor
			local cf = o._config.FrameRounding
			if cd > 0 and cf > 0 then
				c1.BorderSizePixel = 0
				local q = Instance.new("UIStroke")
				q.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				q.LineJoinMode = Enum.LineJoinMode.Round
				q.Transparency = cc
				q.Thickness = cd
				q.Color = ce
				bY(c1, cf)
				q.Parent = c1
				if not ca then
					bK(c1, o._config.FramePadding)
				end
			elseif cd < 1 and cf > 0 then
				c1.BorderSizePixel = 0
				bY(c1, cf)
				if not ca then
					bK(c1, o._config.FramePadding)
				end
			elseif cf < 1 then
				c1.BorderSizePixel = cd
				c1.BorderColor3 = ce
				c1.BorderMode = Enum.BorderMode.Inset
				if not ca then
					bK(c1, cb - Vector2.new(cd, cd))
				else
					bK(c1, -Vector2.new(cd, cd))
				end
			end
		end
		local function cg()
			local c3 = Instance.new("TextButton")
			c3.Name = "Iris_Button"
			c3.Size = UDim2.fromOffset(0, 0)
			c3.BackgroundColor3 = o._config.ButtonColor
			c3.BackgroundTransparency = o._config.ButtonTransparency
			c3.AutoButtonColor = false
			c0(c3)
			c3.AutomaticSize = Enum.AutomaticSize.XY
			c9(c3)
			c2(
				c3,
				c3,
				{
					ButtonColor = o._config.ButtonColor,
					ButtonTransparency = o._config.ButtonTransparency,
					ButtonHoveredColor = o._config.ButtonHoveredColor,
					ButtonHoveredTransparency = o._config.ButtonHoveredTransparency,
					ButtonActiveColor = o._config.ButtonActiveColor,
					ButtonActiveTransparency = o._config.ButtonActiveTransparency,
				}
			)
			return c3
		end
		local function ch(L)
			for u, ci in L.state do
				ci.ConnectedWidgets[L.ID] = nil
			end
		end
		do
			local cj = 0
			o.WidgetConstructor("Root", false, true, {
				Args = {},
				Generate = function(L)
					local ck = Instance.new("Folder")
					ck.Name = "Iris_Root"
					local cl
					if o._config.UseScreenGUIs then
						cl = Instance.new("ScreenGui")
						cl.ResetOnSpawn = false
						cl.DisplayOrder = o._config.DisplayOrderOffset
					else
						cl = Instance.new("Folder")
					end
					cl.Name = "PseudoWindowScreenGui"
					cl.Parent = ck
					local cm = Instance.new("Frame")
					cm.Name = "PseudoWindow"
					cm.Size = UDim2.new(0, 0, 0, 0)
					cm.Position = UDim2.fromOffset(0, 22)
					cm.BorderSizePixel = o._config.WindowBorderSize
					cm.BorderColor3 = o._config.BorderColor
					cm.BackgroundTransparency = o._config.WindowBgTransparency
					cm.BackgroundColor3 = o._config.WindowBgColor
					cm.AutomaticSize = Enum.AutomaticSize.XY
					cm.Selectable = false
					cm.SelectionGroup = true
					cm.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
					cm.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
					cm.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
					cm.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
					cm.Visible = false
					bK(cm, o._config.WindowPadding)
					bS(cm, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.Y))
					cm.Parent = cl
					return ck
				end,
				Update = function(L)
					if cj > 0 then
						L.Instance.PseudoWindowScreenGui.PseudoWindow.Visible = true
					end
				end,
				Discard = function(L)
					cj = 0
					L.Instance:Destroy()
				end,
				ChildAdded = function(L, cn)
					if cn.type == "Window" then
						return L.Instance
					else
						cj = cj + 1
						L.Instance.PseudoWindowScreenGui.PseudoWindow.Visible = true
						return L.Instance.PseudoWindowScreenGui.PseudoWindow
					end
				end,
				ChildDiscarded = function(L, cn)
					if cn.type ~= "Window" then
						cj = cj - 1
						if cj == 0 then
							L.Instance.PseudoWindowScreenGui.PseudoWindow.Visible = false
						end
					end
				end,
			})
		end
		o.WidgetConstructor("Text", false, false, {
			Args = { ["Text"] = 1 },
			Generate = function(L)
				local co = Instance.new("TextLabel")
				co.Name = "Iris_Text"
				co.Size = UDim2.fromOffset(0, 0)
				co.BackgroundTransparency = 1
				co.BorderSizePixel = 0
				co.ZIndex = L.ZIndex
				co.LayoutOrder = L.ZIndex
				co.AutomaticSize = Enum.AutomaticSize.XY
				c0(co)
				bK(co, Vector2.new(0, 2))
				return co
			end,
			Update = function(L)
				local co = L.Instance
				if L.arguments.Text == nil then
					error("Iris.Text Text Argument is required", 5)
				end
				co.Text = L.arguments.Text
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
		})
		o.Text = function(a6)
			return o._Insert("Text", a6)
		end
		o.WidgetConstructor("TextWrapped", false, false, {
			Args = { ["Text"] = 1 },
			Generate = function(L)
				local cp = Instance.new("TextLabel")
				cp.Name = "Iris_Text"
				cp.Size = UDim2.new(o._config.ItemWidth, UDim.new(0, 0))
				cp.BackgroundTransparency = 1
				cp.BorderSizePixel = 0
				cp.ZIndex = L.ZIndex
				cp.LayoutOrder = L.ZIndex
				cp.AutomaticSize = Enum.AutomaticSize.Y
				cp.TextWrapped = true
				c0(cp)
				bK(cp, Vector2.new(0, 2))
				return cp
			end,
			Update = function(L)
				local cp = L.Instance
				if L.arguments.Text == nil then
					error("Iris.TextWrapped Text Argument is required", 5)
				end
				cp.Text = L.arguments.Text
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
		})
		o.TextWrapped = function(a6)
			return o._Insert("TextWrapped", a6)
		end
		o.WidgetConstructor("Button", false, false, {
			Args = { ["Text"] = 1 },
			Generate = function(L)
				local c3 = cg()
				c3.ZIndex = L.ZIndex
				c3.LayoutOrder = L.ZIndex
				c3.MouseButton1Click:Connect(function()
					L.events.clicked = true
				end)
				return c3
			end,
			Update = function(L)
				local c3 = L.Instance
				c3.Text = L.arguments.Text or "Button"
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
		})
		o.Button = function(a6)
			return o._Insert("Button", a6)
		end
		o.WidgetConstructor("SmallButton", false, false, {
			Args = { ["Text"] = 1 },
			Generate = function(L)
				local cq = cg()
				cq.Name = "Iris_SmallButton"
				cq.ZIndex = L.ZIndex
				cq.LayoutOrder = L.ZIndex
				cq.MouseButton1Click:Connect(function()
					L.events.clicked = true
				end)
				local bK = cq.UIPadding
				bK.PaddingLeft = UDim.new(0, 2)
				bK.PaddingRight = UDim.new(0, 2)
				bK.PaddingTop = UDim.new(0, 0)
				bK.PaddingBottom = UDim.new(0, 0)
				return cq
			end,
			Update = function(L)
				local cq = L.Instance
				cq.Text = L.arguments.Text or "SmallButton"
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
		})
		o.SmallButton = function(a6)
			return o._Insert("SmallButton", a6)
		end
		o.WidgetConstructor("Separator", false, false, {
			Args = {},
			Generate = function(L)
				local cr = Instance.new("Frame")
				cr.Name = "Iris_Separator"
				cr.BorderSizePixel = 0
				if L.parentWidget.type == "SameLine" then
					cr.Size = UDim2.new(0, 1, 1, 0)
				else
					cr.Size = UDim2.new(1, 0, 0, 1)
				end
				cr.ZIndex = L.ZIndex
				cr.LayoutOrder = L.ZIndex
				cr.BackgroundColor3 = o._config.SeparatorColor
				cr.BackgroundTransparency = o._config.SeparatorTransparency
				bS(cr, Enum.FillDirection.Vertical, UDim.new(0, 0))
				return cr
			end,
			Update = function(L) end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
		})
		o.Separator = function(a6)
			return o._Insert("Separator", a6)
		end
		o.WidgetConstructor("Indent", false, true, {
			Args = { ["Width"] = 1 },
			Generate = function(L)
				local cs = Instance.new("Frame")
				cs.Name = "Iris_Indent"
				cs.BackgroundTransparency = 1
				cs.BorderSizePixel = 0
				cs.ZIndex = L.ZIndex
				cs.LayoutOrder = L.ZIndex
				cs.Size = UDim2.fromScale(1, 0)
				cs.AutomaticSize = Enum.AutomaticSize.Y
				bS(cs, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.Y))
				bK(cs, Vector2.new(0, 0))
				return cs
			end,
			Update = function(L)
				local ct
				if L.arguments.Width then
					ct = L.arguments.Width
				else
					ct = o._config.IndentSpacing
				end
				L.Instance.UIPadding.PaddingLeft = UDim.new(0, ct)
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
			ChildAdded = function(L)
				return L.Instance
			end,
		})
		o.Indent = function(a6)
			return o._Insert("Indent", a6)
		end
		o.WidgetConstructor("SameLine", false, true, {
			Args = { ["Width"] = 1, ["VerticalAlignment"] = 2 },
			Generate = function(L)
				local cu = Instance.new("Frame")
				cu.Name = "Iris_SameLine"
				cu.BackgroundTransparency = 1
				cu.BorderSizePixel = 0
				cu.ZIndex = L.ZIndex
				cu.LayoutOrder = L.ZIndex
				cu.Size = UDim2.fromScale(1, 0)
				cu.AutomaticSize = Enum.AutomaticSize.Y
				bS(cu, Enum.FillDirection.Horizontal, UDim.new(0, 0))
				return cu
			end,
			Update = function(L)
				local cv
				local bS = L.Instance.UIListLayout
				if L.arguments.Width then
					cv = L.arguments.Width
				else
					cv = o._config.ItemSpacing.X
				end
				bS.Padding = UDim.new(0, cv)
				if L.arguments.VerticalAlignment then
					bS.VerticalAlignment = L.arguments.VerticalAlignment
				else
					bS.VerticalAlignment = Enum.VerticalAlignment.Center
				end
			end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
			ChildAdded = function(L)
				return L.Instance
			end,
		})
		o.SameLine = function(a6)
			return o._Insert("SameLine", a6)
		end
		o.WidgetConstructor("Group", false, true, {
			Args = {},
			Generate = function(L)
				local cw = Instance.new("Frame")
				cw.Name = "Iris_Group"
				cw.Size = UDim2.fromOffset(0, 0)
				cw.BackgroundTransparency = 1
				cw.BorderSizePixel = 0
				cw.ZIndex = L.ZIndex
				cw.LayoutOrder = L.ZIndex
				cw.AutomaticSize = Enum.AutomaticSize.XY
				local bS = bS(cw, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.X))
				return cw
			end,
			Update = function(L) end,
			Discard = function(L)
				L.Instance:Destroy()
			end,
			ChildAdded = function(L)
				return L.Instance
			end,
		})
		o.Group = function(a6)
			return o._Insert("Group", a6)
		end
		o.WidgetConstructor("Checkbox", true, false, {
			Args = { ["Text"] = 1 },
			Generate = function(L)
				local cx = Instance.new("TextButton")
				cx.Name = "Iris_Checkbox"
				cx.BackgroundTransparency = 1
				cx.BorderSizePixel = 0
				cx.Size = UDim2.fromOffset(0, 0)
				cx.Text = ""
				cx.AutomaticSize = Enum.AutomaticSize.XY
				cx.ZIndex = L.ZIndex
				cx.AutoButtonColor = false
				cx.LayoutOrder = L.ZIndex
				local cy = Instance.new("TextLabel")
				cy.Name = "CheckboxBox"
				cy.AutomaticSize = Enum.AutomaticSize.None
				local cz = o._config.TextSize + 2 * o._config.FramePadding.Y
				cy.Size = UDim2.fromOffset(cz, cz)
				cy.TextSize = cz
				cy.LineHeight = 1.1
				cy.ZIndex = L.ZIndex + 1
				cy.LayoutOrder = L.ZIndex + 1
				cy.Parent = cx
				cy.TextColor3 = o._config.CheckMarkColor
				cy.TextTransparency = o._config.CheckMarkTransparency
				cy.BackgroundColor3 = o._config.FrameBgColor
				cy.BackgroundTransparency = o._config.FrameBgTransparency
				c9(cy, true)
				c2(
					cx,
					cy,
					{
						ButtonColor = o._config.FrameBgColor,
						ButtonTransparency = o._config.FrameBgTransparency,
						ButtonHoveredColor = o._config.FrameBgHoveredColor,
						ButtonHoveredTransparency = o._config.FrameBgHoveredTransparency,
						ButtonActiveColor = o._config.FrameBgActiveColor,
						ButtonActiveTransparency = o._config.FrameBgActiveTransparency,
					}
				)
				cx.MouseButton1Click:Connect(function()
					local cA = L.state.isChecked.value
					L.state.isChecked:set(not cA)
				end)
				local cB = Instance.new("TextLabel")
				cB.Name = "TextLabel"
				c0(cB)
				cB.Position = UDim2.new(0, cz + o._config.ItemInnerSpacing.X, 0.5, 0)
				cB.ZIndex = L.ZIndex + 1
				cB.LayoutOrder = L.ZIndex + 1
				cB.AutomaticSize = Enum.AutomaticSize.XY
				cB.AnchorPoint = Vector2.new(0, 0.5)
				cB.BackgroundTransparency = 1
				cB.BorderSizePixel = 0
				cB.Parent = cx
				return cx
			end,
			Update = function(L)
				L.Instance.TextLabel.Text = L.arguments.Text or "Checkbox"
			end,
			Discard = function(L)
				L.Instance:Destroy()
				ch(L)
			end,
			GenerateState = function(L)
				if L.state.isChecked == nil then
					L.state.isChecked = o._widgetState(L, "checked", false)
				end
			end,
			UpdateState = function(L)
				local cx = L.Instance.CheckboxBox
				if L.state.isChecked.value then
					cx.Text = bJ.CHECK_MARK
					L.events.checked = true
				else
					cx.Text = ""
					L.events.unchecked = true
				end
			end,
		})
		o.Checkbox = function(a6, ci)
			return o._Insert("Checkbox", a6, ci)
		end
		o.WidgetConstructor("Tree", true, true, {
			Args = { ["Text"] = 1, ["SpanAvailWidth"] = 2, ["NoIndent"] = 3 },
			Generate = function(L)
				local cC = Instance.new("Frame")
				cC.Name = "Iris_Tree"
				cC.BackgroundTransparency = 1
				cC.BorderSizePixel = 0
				cC.ZIndex = L.ZIndex
				cC.LayoutOrder = L.ZIndex
				cC.Size = UDim2.new(o._config.ItemWidth, UDim.new(0, 0))
				cC.AutomaticSize = Enum.AutomaticSize.Y
				L.hasChildren = false
				bS(cC, Enum.FillDirection.Vertical, UDim.new(0, 0))
				local cD = Instance.new("Frame")
				cD.Name = "ChildContainer"
				cD.BackgroundTransparency = 1
				cD.BorderSizePixel = 0
				cD.ZIndex = L.ZIndex + 1
				cD.LayoutOrder = L.ZIndex + 1
				cD.Size = UDim2.fromScale(1, 0)
				cD.AutomaticSize = Enum.AutomaticSize.Y
				cD.Visible = false
				cD.Parent = cC
				bS(cD, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.Y))
				local cE = bK(cD, Vector2.new(0, 0))
				cE.PaddingTop = UDim.new(0, o._config.ItemSpacing.Y)
				local cF = Instance.new("Frame")
				cF.Name = "Header"
				cF.BackgroundTransparency = 1
				cF.BorderSizePixel = 0
				cF.ZIndex = L.ZIndex
				cF.LayoutOrder = L.ZIndex
				cF.Size = UDim2.fromScale(1, 0)
				cF.AutomaticSize = Enum.AutomaticSize.Y
				cF.Parent = cC
				local c3 = Instance.new("TextButton")
				c3.Name = "Button"
				c3.BackgroundTransparency = 1
				c3.BorderSizePixel = 0
				c3.ZIndex = L.ZIndex
				c3.LayoutOrder = L.ZIndex
				c3.AutoButtonColor = false
				c3.Text = ""
				c3.Parent = cF
				c2(
					c3,
					cF,
					{
						ButtonColor = Color3.fromRGB(0, 0, 0),
						ButtonTransparency = 1,
						ButtonHoveredColor = o._config.HeaderHoveredColor,
						ButtonHoveredTransparency = o._config.HeaderHoveredTransparency,
						ButtonActiveColor = o._config.HeaderActiveColor,
						ButtonActiveTransparency = o._config.HeaderActiveTransparency,
					}
				)
				local cG = bS(c3, Enum.FillDirection.Horizontal, UDim.new(0, 0))
				cG.VerticalAlignment = Enum.VerticalAlignment.Center
				local cH = Instance.new("TextLabel")
				cH.Name = "Arrow"
				cH.Size = UDim2.fromOffset(o._config.TextSize, 0)
				cH.BackgroundTransparency = 1
				cH.BorderSizePixel = 0
				cH.ZIndex = L.ZIndex
				cH.LayoutOrder = L.ZIndex
				cH.AutomaticSize = Enum.AutomaticSize.Y
				c0(cH)
				cH.TextXAlignment = Enum.TextXAlignment.Center
				cH.TextSize = o._config.TextSize - 4
				cH.Text = bJ.RIGHT_POINTING_TRIANGLE
				cH.Parent = c3
				local cB = Instance.new("TextLabel")
				cB.Name = "TextLabel"
				cB.Size = UDim2.fromOffset(0, 0)
				cB.BackgroundTransparency = 1
				cB.BorderSizePixel = 0
				cB.ZIndex = L.ZIndex
				cB.LayoutOrder = L.ZIndex
				cB.AutomaticSize = Enum.AutomaticSize.XY
				cB.Parent = c3
				local cI = bK(cB, Vector2.new(0, 0))
				cI.PaddingRight = UDim.new(0, 21)
				c0(cB)
				c3.MouseButton1Click:Connect(function()
					L.state.isUncollapsed:set(not L.state.isUncollapsed.value)
				end)
				return cC
			end,
			Update = function(L)
				local c3 = L.Instance.Header.Button
				local cD = L.Instance.ChildContainer
				c3.TextLabel.Text = L.arguments.Text or "Tree"
				if L.arguments.SpanAvailWidth then
					c3.AutomaticSize = Enum.AutomaticSize.Y
					c3.Size = UDim2.fromScale(1, 0)
				else
					c3.AutomaticSize = Enum.AutomaticSize.XY
					c3.Size = UDim2.fromScale(0, 0)
				end
				if L.arguments.NoIndent then
					cD.UIPadding.PaddingLeft = UDim.new(0, 0)
				else
					cD.UIPadding.PaddingLeft = UDim.new(0, o._config.IndentSpacing)
				end
			end,
			Discard = function(L)
				L.Instance:Destroy()
				ch(L)
			end,
			ChildAdded = function(L)
				local cD = L.Instance.ChildContainer
				local cJ = L.state.isUncollapsed.value
				L.hasChildren = true
				cD.Visible = cJ and L.hasChildren
				return L.Instance.ChildContainer
			end,
			UpdateState = function(L)
				local cJ = L.state.isUncollapsed.value
				local cH = L.Instance.Header.Button.Arrow
				local cD = L.Instance.ChildContainer
				cH.Text = cJ and bJ.DOWN_POINTING_TRIANGLE or bJ.RIGHT_POINTING_TRIANGLE
				if cJ then
					L.events.uncollapsed = true
				else
					L.events.collapsed = true
				end
				cD.Visible = cJ and L.hasChildren
			end,
			GenerateState = function(L)
				if L.state.isUncollapsed == nil then
					L.state.isUncollapsed = o._widgetState(L, "isUncollapsed", false)
				end
			end,
		})
		o.Tree = function(a6, ci)
			return o._Insert("Tree", a6, ci)
		end
		o.WidgetConstructor("InputNum", true, false, {
			Args = { ["Text"] = 1, ["Increment"] = 2, ["Min"] = 3, ["Max"] = 4, ["Format"] = 5, ["NoButtons"] = 6, ["NoField"] = 7 },
			Generate = function(L)
				local am = Instance.new("Frame")
				am.Name = "Iris_InputNum"
				am.Size = UDim2.new(o._config.ContentWidth, UDim.new(0, 0))
				am.BackgroundTransparency = 1
				am.BorderSizePixel = 0
				am.ZIndex = L.ZIndex
				am.LayoutOrder = L.ZIndex
				am.AutomaticSize = Enum.AutomaticSize.Y
				bS(am, Enum.FillDirection.Horizontal, UDim.new(0, o._config.ItemInnerSpacing.X))
				local cK = o._config.TextSize
				local cL = cK + o._config.FramePadding.Y * 2
				local cM = Instance.new("TextBox")
				cM.Name = "InputField"
				c9(cM)
				c0(cM)
				cM.UIPadding.PaddingLeft = UDim.new(0, o._config.ItemInnerSpacing.X)
				cM.ZIndex = L.ZIndex + 1
				cM.LayoutOrder = L.ZIndex + 1
				cM.AutomaticSize = Enum.AutomaticSize.Y
				cM.BackgroundColor3 = o._config.FrameBgColor
				cM.BackgroundTransparency = o._config.FrameBgTransparency
				cM.TextTruncate = Enum.TextTruncate.AtEnd
				cM.Parent = am
				cM.FocusLost:Connect(function()
					local P = tonumber(cM.Text)
					if P ~= nil then
						P = math.clamp(P, L.arguments.Min or -math.huge, L.arguments.Max or math.huge)
						L.state.number:set(P)
						L.events.numberChanged = true
					else
						cM.Text = L.state.number.value
					end
				end)
				local cN = cg()
				cN.Name = "SubButton"
				cN.ZIndex = L.ZIndex + 2
				cN.LayoutOrder = L.ZIndex + 2
				cN.TextXAlignment = Enum.TextXAlignment.Center
				cN.Text = "-"
				cN.Size = UDim2.fromOffset(cK - 2, cK)
				cN.Parent = am
				cN.MouseButton1Click:Connect(function()
					local P = L.state.number.value - (L.arguments.Increment or 1)
					P = math.clamp(P, L.arguments.Min or -math.huge, L.arguments.Max or math.huge)
					L.state.number:set(P)
					L.events.numberChanged = true
				end)
				local cO = cg()
				cO.Name = "AddButton"
				cO.ZIndex = L.ZIndex + 3
				cO.LayoutOrder = L.ZIndex + 3
				cO.TextXAlignment = Enum.TextXAlignment.Center
				cO.Text = "+"
				cO.Size = UDim2.fromOffset(cK - 2, cK)
				cO.Parent = am
				cO.MouseButton1Click:Connect(function()
					local P = L.state.number.value + (L.arguments.Increment or 1)
					P = math.clamp(P, L.arguments.Min or -math.huge, L.arguments.Max or math.huge)
					L.state.number:set(P)
					L.events.numberChanged = true
				end)
				local cB = Instance.new("TextLabel")
				cB.Name = "TextLabel"
				cB.Size = UDim2.fromOffset(0, cL)
				cB.BackgroundTransparency = 1
				cB.BorderSizePixel = 0
				cB.ZIndex = L.ZIndex + 4
				cB.LayoutOrder = L.ZIndex + 4
				cB.AutomaticSize = Enum.AutomaticSize.X
				c0(cB)
				cB.Parent = am
				return am
			end,
			Update = function(L)
				local cB = L.Instance.TextLabel
				cB.Text = L.arguments.Text or "Input Num"
				L.Instance.SubButton.Visible = not L.arguments.NoButtons
				L.Instance.AddButton.Visible = not L.arguments.NoButtons
				local cM = L.Instance.InputField
				cM.Visible = not L.arguments.NoField
				local cP = o._config.TextSize * 2 + o._config.ItemInnerSpacing.X * 2 + o._config.WindowPadding.X + 4
				if L.arguments.NoButtons then
					cM.Size = UDim2.new(1, 0, 0, 0)
				else
					cM.Size = UDim2.new(1, -cP, 0, 0)
				end
			end,
			Discard = function(L)
				L.Instance:Destroy()
				ch(L)
			end,
			GenerateState = function(L)
				if L.state.number == nil then
					L.state.number = o._widgetState(L, "number", 0)
				end
			end,
			UpdateState = function(L)
				local cM = L.Instance.InputField
				cM.Text = string.format(L.arguments.Format or "%f", L.state.number.value)
			end,
		})
		o.InputNum = function(a6, ci)
			return o._Insert("InputNum", a6, ci)
		end
		o.WidgetConstructor("InputText", true, false, {
			Args = { ["Text"] = 1, ["TextHint"] = 2 },
			Generate = function(L)
				local cL = o._config.TextSize
				local an = Instance.new("Frame")
				an.Name = "Iris_InputText"
				an.Size = UDim2.new(o._config.ContentWidth, UDim.new(0, 0))
				an.BackgroundTransparency = 1
				an.BorderSizePixel = 0
				an.ZIndex = L.ZIndex
				an.LayoutOrder = L.ZIndex
				an.AutomaticSize = Enum.AutomaticSize.Y
				bS(an, Enum.FillDirection.Horizontal, UDim.new(0, o._config.ItemInnerSpacing.X))
				local cM = Instance.new("TextBox")
				cM.Name = "InputField"
				c9(cM)
				c0(cM)
				cM.UIPadding.PaddingLeft = UDim.new(0, o._config.ItemInnerSpacing.X)
				cM.UIPadding.PaddingRight = UDim.new(0, 0)
				cM.ZIndex = L.ZIndex + 1
				cM.LayoutOrder = L.ZIndex + 1
				cM.AutomaticSize = Enum.AutomaticSize.Y
				cM.Size = UDim2.new(o._config.ContentWidth, UDim.new(0, 0))
				cM.BackgroundColor3 = o._config.FrameBgColor
				cM.BackgroundTransparency = o._config.FrameBgTransparency
				cM.ClearTextOnFocus = false
				cM.Text = ""
				cM.PlaceholderColor3 = o._config.TextDisabledColor
				cM.TextTruncate = Enum.TextTruncate.AtEnd
				cM.FocusLost:Connect(function()
					L.state.text:set(cM.Text)
					L.events.textChanged = true
				end)
				cM.Parent = an
				local cB = Instance.new("TextLabel")
				cB.Name = "TextLabel"
				cB.Position = UDim2.new(1, o._config.ItemInnerSpacing.X, 0, 0)
				cB.Size = UDim2.fromOffset(0, cL)
				cB.BackgroundTransparency = 1
				cB.BorderSizePixel = 0
				cB.ZIndex = L.ZIndex + 2
				cB.LayoutOrder = L.ZIndex + 2
				cB.AutomaticSize = Enum.AutomaticSize.X
				c0(cB)
				cB.Parent = an
				return an
			end,
			Update = function(L)
				local cB = L.Instance.TextLabel
				cB.Text = L.arguments.Text or "Input Text"
				L.Instance.InputField.PlaceholderText = L.arguments.TextHint or ""
			end,
			Discard = function(L)
				L.Instance:Destroy()
				ch(L)
			end,
			GenerateState = function(L)
				if L.state.text == nil then
					L.state.text = o._widgetState(L, "text", "")
				end
			end,
			UpdateState = function(L)
				L.Instance.InputField.Text = L.state.text.value
			end,
		})
		o.InputText = function(a6, ci)
			return o._Insert("InputText", a6, ci)
		end
		do
			local cQ = {}
			table.insert(o._postCycleCallbacks, function()
				for u, B in cQ do
					B.RowColumnIndex = 0
				end
			end)
			o.NextColumn = function()
				o._GetParentWidget().RowColumnIndex = o._GetParentWidget().RowColumnIndex + 1
			end
			o.SetColumnIndex = function(cR)
				local cS = o._GetParentWidget()
				assert(cR >= cS.InitialNumColumns, "Iris.SetColumnIndex Argument must be in column range")
				cS.RowColumnIndex = math.floor(cS.RowColumnIndex / cS.InitialNumColumns) + cR - 1
			end
			o.NextRow = function()
				local cS = o._GetParentWidget()
				local cT = cS.InitialNumColumns
				local cU = math.floor((cS.RowColumnIndex + 1) / cT) * cT
				cS.RowColumnIndex = cU
			end
			o.WidgetConstructor("Table", false, true, {
				Args = { ["NumColumns"] = 1, ["RowBg"] = 2, ["BordersOuter"] = 3, ["BordersInner"] = 4 },
				Generate = function(L)
					cQ[L.ID] = L
					L.InitialNumColumns = -1
					L.RowColumnIndex = 0
					L.ColumnInstances = {}
					L.CellInstances = {}
					local cV = Instance.new("Frame")
					cV.Name = "Iris_Table"
					cV.Size = UDim2.new(o._config.ItemWidth, UDim.new(0, 0))
					cV.BackgroundTransparency = 1
					cV.BorderSizePixel = 0
					cV.ZIndex = L.ZIndex + 1024
					cV.LayoutOrder = L.ZIndex
					cV.AutomaticSize = Enum.AutomaticSize.Y
					bS(cV, Enum.FillDirection.Horizontal, UDim.new(0, 0))
					q(cV, 1, o._config.TableBorderStrongColor, o._config.TableBorderStrongTransparency)
					return cV
				end,
				Update = function(L)
					local cW = L.Instance
					local cX = L.ColumnInstances
					if L.arguments.BordersOuter == false then
						cW.UIStroke.Thickness = 0
					else
						L.Instance.UIStroke.Thickness = 1
					end
					if L.InitialNumColumns == -1 then
						if L.arguments.NumColumns == nil then
							error("Iris.Table NumColumns argument is required", 5)
						end
						L.InitialNumColumns = L.arguments.NumColumns
						for u = 1, L.InitialNumColumns do
							local cY = Instance.new("Frame")
							cY.Name = "Column_" .. u
							cY.BackgroundTransparency = 1
							cY.BorderSizePixel = 0
							local cZ = L.ZIndex + 1 + u
							cY.ZIndex = cZ
							cY.LayoutOrder = cZ
							cY.AutomaticSize = Enum.AutomaticSize.Y
							cY.Size = UDim2.new(1 / L.InitialNumColumns, 0, 0, 0)
							bS(cY, Enum.FillDirection.Vertical, UDim.new(0, 0))
							cX[u] = cY
							cY.Parent = cW
						end
					elseif L.arguments.NumColumns ~= L.InitialNumColumns then
						error("Iris.Table NumColumns Argument must be static")
					end
					if L.arguments.RowBg == false then
						for A, B in L.CellInstances do
							B.BackgroundTransparency = 1
						end
					else
						for c_, B in L.CellInstances do
							local d0 = math.ceil(c_ / L.InitialNumColumns)
							B.BackgroundTransparency = d0 % 2 == 0 and o._config.TableRowBgAltTransparency
								or o._config.TableRowBgTransparency
						end
					end
					if L.arguments.BordersInner == false then
						for A, B in L.CellInstances do
							B.UIStroke.Thickness = 0
						end
					else
						for A, B in L.CellInstances do
							B.UIStroke.Thickness = 0.5
						end
					end
				end,
				Discard = function(L)
					cQ[L.ID] = nil
					L.Instance:Destroy()
				end,
				ChildAdded = function(L)
					if L.RowColumnIndex == 0 then
						L.RowColumnIndex = 1
					end
					local d1 = L.CellInstances[L.RowColumnIndex]
					if d1 then
						return d1
					end
					local d2 = Instance.new("Frame")
					d2.AutomaticSize = Enum.AutomaticSize.Y
					d2.Size = UDim2.new(1, 0, 0, 0)
					d2.BackgroundTransparency = 1
					d2.BorderSizePixel = 0
					bK(d2, o._config.CellPadding)
					local d3 = L.ColumnInstances[(L.RowColumnIndex - 1) % L.InitialNumColumns + 1]
					local d4 = d3.ZIndex + L.RowColumnIndex
					d2.ZIndex = d4
					d2.LayoutOrder = d4
					d2.Name = "Cell_" .. L.RowColumnIndex
					bS(d2, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.Y))
					if L.arguments.BordersInner == false then
						q(d2, 0, o._config.TableBorderLightColor, o._config.TableBorderLightTransparency)
					else
						q(d2, 0.5, o._config.TableBorderLightColor, o._config.TableBorderLightTransparency)
					end
					if L.arguments.RowBg ~= false then
						local d0 = math.ceil(L.RowColumnIndex / L.InitialNumColumns)
						local d5 = d0 % 2 == 0 and o._config.TableRowBgAltColor or o._config.TableRowBgColor
						local d6 = d0 % 2 == 0 and o._config.TableRowBgAltTransparency
							or o._config.TableRowBgTransparency
						d2.BackgroundColor3 = d5
						d2.BackgroundTransparency = d6
					end
					L.CellInstances[L.RowColumnIndex] = d2
					d2.Parent = d3
					return d2
				end,
			})
			o.Table = function(a6, ci)
				return o._Insert("Table", a6, ci)
			end
		end
		do
			local d7 = 0
			local d8
			local d9 = false
			local da
			local db
			local dc = false
			local dd = false
			local de = false
			local df = Enum.TopBottom.Top
			local dg = Enum.LeftRight.Left
			local dh
			local di
			local dj = false
			local dk = {}
			local function dl(L)
				local dm
				if L.usesScreenGUI then
					dm = L.Instance.AbsoluteSize
				else
					local dn = L.Instance.Parent
					if dn:IsA("GuiBase2d") then
						dm = dn.AbsoluteSize
					else
						if dn.Parent:IsA("GuiBase2d") then
							dm = dn.AbsoluteSize
						else
							dm = workspace.CurrentCamera.ViewportSize
						end
					end
				end
				return dm
			end
			local function dp()
				if o._config.UseScreenGUIs == false then
					return
				end
				local dq = 0xFFFF
				local dr
				for u, B in dk do
					if B.state.isOpened.value and not B.arguments.NoNav then
						local ds = B.Instance.DisplayOrder
						if ds < dq then
							dq = ds
							dr = B
						end
					end
				end
				if dr.state.isUncollapsed.value == false then
					dr.state.isUncollapsed:set(true)
				end
				o.SetFocusedWindow(dr)
			end
			local function dt(L, du)
				local dv = Vector2.new(L.state.position.value.X, L.state.position.value.Y)
				local dw = (o._config.TextSize + o._config.FramePadding.Y * 2) * 2
				local dx = dl(L)
				local dy = dx - dv - Vector2.new(o._config.WindowBorderSize, o._config.WindowBorderSize)
				return Vector2.new(math.clamp(du.X, dw, math.max(dy.X, dw)), math.clamp(du.Y, dw, math.max(dy.Y, dw)))
			end
			local function dz(L, dA)
				local cW = L.Instance
				local dx = dl(L)
				return Vector2.new(
					math.clamp(
						dA.X,
						o._config.WindowBorderSize,
						math.max(
							o._config.WindowBorderSize,
							dx.X - cW.WindowButton.AbsoluteSize.X - o._config.WindowBorderSize
						)
					),
					math.clamp(
						dA.Y,
						o._config.WindowBorderSize,
						math.max(
							o._config.WindowBorderSize,
							dx.Y - cW.WindowButton.AbsoluteSize.Y - o._config.WindowBorderSize
						)
					)
				)
			end
			o.SetFocusedWindow = function(L)
				if di == L then
					return
				end
				if dj then
					if dk[di.ID] ~= nil then
						local dB = di.Instance.WindowButton.TitleBar
						if di.state.isUncollapsed.value then
							dB.BackgroundColor3 = o._config.TitleBgColor
							dB.BackgroundTransparency = o._config.TitleBgTransparency
						else
							dB.BackgroundColor3 = o._config.TitleBgCollapsedColor
							dB.BackgroundTransparency = o._config.TitleBgCollapsedTransparency
						end
						di.Instance.WindowButton.UIStroke.Color = o._config.BorderColor
					end
					dj = false
					di = nil
				end
				if L ~= nil then
					dj = true
					di = L
					local dB = di.Instance.WindowButton.TitleBar
					dB.BackgroundColor3 = o._config.TitleBgActiveColor
					dB.BackgroundTransparency = o._config.TitleBgActiveTransparency
					di.Instance.WindowButton.UIStroke.Color = o._config.BorderActiveColor
					d7 = d7 + 1
					if L.usesScreenGUI then
						di.Instance.DisplayOrder = d7 + o._config.DisplayOrderOffset
					end
					if L.state.isUncollapsed.value == false then
						L.state.isUncollapsed:set(true)
					end
					local dC = bH.SelectedObject
					if dC then
						if di.Instance.TitleBar.Visible then
							bH:Select(di.Instance.TitleBar)
						else
							bH:Select(di.Instance.ChildContainer)
						end
					end
				end
			end
			bI.InputBegan:Connect(function(c8, dD)
				if not dD and c8.UserInputType == Enum.UserInputType.MouseButton1 then
					o.SetFocusedWindow(nil)
				end
				if
					c8.KeyCode == Enum.KeyCode.Tab
					and (bI:IsKeyDown(Enum.KeyCode.LeftControl) or bI:IsKeyDown(Enum.KeyCode.RightControl))
				then
					dp()
				end
				if c8.UserInputType == Enum.UserInputType.MouseButton1 then
					if dd and not de and dj then
						local dE = di.state.position.value + di.state.size.value / 2
						local dF = bI:getMouseLocation() - Vector2.new(0, 36) - dE
						if math.abs(dF.X) * di.state.size.value.Y >= math.abs(dF.Y) * di.state.size.value.X then
							df = Enum.TopBottom.Center
							dg = math.sign(dF.X) == -1 and Enum.LeftRight.Left or Enum.LeftRight.Right
						else
							dg = Enum.LeftRight.Center
							df = math.sign(dF.Y) == -1 and Enum.TopBottom.Top or Enum.TopBottom.Bottom
						end
						dc = true
						db = di
					end
				end
			end)
			bI.TouchTapInWorld:Connect(function(c8, dD)
				if not dD then
					o.SetFocusedWindow(nil)
				end
			end)
			bI.InputChanged:Connect(function(c8)
				if d9 then
					local dG
					if c8.UserInputType == Enum.UserInputType.Touch then
						local dH = c8.Position
						dG = Vector2.new(dH.X, dH.Y)
					else
						dG = bI:getMouseLocation()
					end
					local dI = d8.Instance.WindowButton
					local dA = dG - da
					local dJ = dz(d8, dA)
					dI.Position = UDim2.fromOffset(dJ.X, dJ.Y)
					d8.state.position.value = dJ
				end
				if dc then
					local dK = db.Instance.WindowButton
					local dL = Vector2.new(dK.Position.X.Offset, dK.Position.Y.Offset)
					local dv = Vector2.new(dK.Size.X.Offset, dK.Size.Y.Offset)
					local dM
					if c8.UserInputType == Enum.UserInputType.Touch then
						dM = c8.Delta
					else
						dM = bI:GetMouseLocation() - dh
					end
					local dA = dL
						+ Vector2.new(dg == Enum.LeftRight.Left and dM.X or 0, df == Enum.TopBottom.Top and dM.Y or 0)
					local dN = dv
						+ Vector2.new(
							dg == Enum.LeftRight.Left and -dM.X or dg == Enum.LeftRight.Right and dM.X or 0,
							df == Enum.TopBottom.Top and -dM.Y or df == Enum.TopBottom.Bottom and dM.Y or 0
						)
					local dO = dt(db, dN)
					local dP = dz(db, dA)
					dK.Size = UDim2.fromOffset(dO.X, dO.Y)
					db.state.size.value = dO
					dK.Position = UDim2.fromOffset(dP.X, dP.Y)
					db.state.position.value = dP
				end
				dh = bI:getMouseLocation()
			end)
			bI.InputEnded:Connect(function(c8, dD)
				if
					(
						c8.UserInputType == Enum.UserInputType.MouseButton1
						or c8.UserInputType == Enum.UserInputType.Touch
					) and d9
				then
					local dI = d8.Instance.WindowButton
					d9 = false
					d8.state.position:set(Vector2.new(dI.Position.X.Offset, dI.Position.Y.Offset))
				end
				if
					(
						c8.UserInputType == Enum.UserInputType.MouseButton1
						or c8.UserInputType == Enum.UserInputType.Touch
					) and dc
				then
					dc = false
					db.state.size:set(db.Instance.WindowButton.AbsoluteSize)
				end
				if c8.KeyCode == Enum.KeyCode.ButtonX then
					dp()
				end
			end)
			o.WidgetConstructor("Window", true, true, {
				Args = {
					["Title"] = 1,
					["NoTitleBar"] = 2,
					["NoBackground"] = 3,
					["NoCollapse"] = 4,
					["NoClose"] = 5,
					["NoMove"] = 6,
					["NoScrollbar"] = 7,
					["NoResize"] = 8,
					["NoNav"] = 9,
				},
				Generate = function(L)
					L.usesScreenGUI = o._config.UseScreenGUIs
					dk[L.ID] = L
					local dQ
					if L.usesScreenGUI then
						dQ = Instance.new("ScreenGui")
						dQ.ResetOnSpawn = false
						dQ.DisplayOrder = o._config.DisplayOrderOffset
					else
						dQ = Instance.new("Folder")
					end
					dQ.Name = "Iris_Window"
					local dR = Instance.new("TextButton")
					dR.Name = "WindowButton"
					dR.BackgroundTransparency = 1
					dR.BorderSizePixel = 0
					dR.ZIndex = L.ZIndex + 1
					dR.LayoutOrder = L.ZIndex + 1
					dR.Size = UDim2.fromOffset(0, 0)
					dR.AutomaticSize = Enum.AutomaticSize.None
					dR.ClipsDescendants = false
					dR.Text = ""
					dR.AutoButtonColor = false
					dR.Active = false
					dR.Selectable = false
					dR.SelectionImageObject = o.SelectionImageObject
					dR.Parent = dQ
					dR.SelectionGroup = true
					dR.SelectionBehaviorUp = Enum.SelectionBehavior.Stop
					dR.SelectionBehaviorDown = Enum.SelectionBehavior.Stop
					dR.SelectionBehaviorLeft = Enum.SelectionBehavior.Stop
					dR.SelectionBehaviorRight = Enum.SelectionBehavior.Stop
					dR.InputBegan:Connect(function(c8)
						if
							c8.UserInputType == Enum.UserInputType.MouseMovement
							or c8.UserInputType == Enum.UserInputType.Keyboard
						then
							return
						end
						if L.state.isUncollapsed.value then
							o.SetFocusedWindow(L)
						end
						if not L.arguments.NoMove and c8.UserInputType == Enum.UserInputType.MouseButton1 then
							d8 = L
							d9 = true
							da = bI:getMouseLocation() - L.state.position.value
						end
					end)
					local q = Instance.new("UIStroke")
					q.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
					q.LineJoinMode = Enum.LineJoinMode.Miter
					q.Color = o._config.BorderColor
					q.Thickness = o._config.WindowBorderSize
					q.Parent = dR
					local cD = Instance.new("ScrollingFrame")
					cD.Name = "ChildContainer"
					cD.Position = UDim2.fromOffset(0, 0)
					cD.BorderSizePixel = 0
					cD.ZIndex = L.ZIndex + 2
					cD.LayoutOrder = L.ZIndex + 2
					cD.AutomaticSize = Enum.AutomaticSize.None
					cD.Size = UDim2.fromScale(1, 1)
					cD.Selectable = false
					cD.AutomaticCanvasSize = Enum.AutomaticSize.Y
					cD.ScrollBarImageTransparency = o._config.ScrollbarGrabTransparency
					cD.ScrollBarImageColor3 = o._config.ScrollbarGrabColor
					cD.CanvasSize = UDim2.fromScale(0, 1)
					cD.BackgroundColor3 = o._config.WindowBgColor
					cD.BackgroundTransparency = o._config.WindowBgTransparency
					cD.Parent = dR
					bK(cD, o._config.WindowPadding)
					cD:getPropertyChangedSignal("CanvasPosition"):Connect(function()
						L.state.scrollDistance.value = cD.CanvasPosition.Y
					end)
					cD.InputBegan:Connect(function(c8)
						if
							c8.UserInputType == Enum.UserInputType.MouseMovement
							or c8.UserInputType == Enum.UserInputType.Keyboard
						then
							return
						end
						if L.state.isUncollapsed.value then
							o.SetFocusedWindow(L)
						end
					end)
					local dS = Instance.new("Frame")
					dS.Name = "TerminatingFrame"
					dS.BackgroundTransparency = 1
					dS.LayoutOrder = 0x7FFFFFF0
					dS.BorderSizePixel = 0
					dS.Size = UDim2.fromOffset(0, o._config.WindowPadding.Y + o._config.FramePadding.Y)
					dS.Parent = cD
					local dT = bS(cD, Enum.FillDirection.Vertical, UDim.new(0, o._config.ItemSpacing.Y))
					dT.VerticalAlignment = Enum.VerticalAlignment.Top
					local dB = Instance.new("Frame")
					dB.Name = "TitleBar"
					dB.BorderSizePixel = 0
					dB.ZIndex = L.ZIndex + 1
					dB.LayoutOrder = L.ZIndex + 1
					dB.AutomaticSize = Enum.AutomaticSize.Y
					dB.Size = UDim2.fromScale(1, 0)
					dB.ClipsDescendants = true
					dB.Parent = dR
					dB.InputBegan:Connect(function(c8)
						if c8.UserInputType == Enum.UserInputType.Touch then
							if not L.arguments.NoMove then
								d8 = L
								d9 = true
								local dH = c8.Position
								da = Vector2.new(dH.X, dH.Y) - L.state.position.value
							end
						end
					end)
					local dU = o._config.TextSize + (o._config.FramePadding.Y - 1) * 2
					local dV = Instance.new("TextButton")
					dV.Name = "CollapseArrow"
					dV.Size = UDim2.fromOffset(dU, dU)
					dV.Position = UDim2.new(0, o._config.FramePadding.X + 1, 0.5, 0)
					dV.AnchorPoint = Vector2.new(0, 0.5)
					dV.AutoButtonColor = false
					dV.BackgroundTransparency = 1
					dV.BorderSizePixel = 0
					dV.ZIndex = L.ZIndex + 4
					dV.AutomaticSize = Enum.AutomaticSize.None
					c0(dV)
					dV.TextXAlignment = Enum.TextXAlignment.Center
					dV.TextSize = o._config.TextSize
					dV.Parent = dB
					dV.MouseButton1Click:Connect(function()
						L.state.isUncollapsed:set(not L.state.isUncollapsed.value)
					end)
					bY(dV, 1e9)
					c2(
						dV,
						dV,
						{
							ButtonColor = o._config.ButtonColor,
							ButtonTransparency = 1,
							ButtonHoveredColor = o._config.ButtonHoveredColor,
							ButtonHoveredTransparency = o._config.ButtonHoveredTransparency,
							ButtonActiveColor = o._config.ButtonActiveColor,
							ButtonActiveTransparency = o._config.ButtonActiveTransparency,
						}
					)
					local dW = Instance.new("TextButton")
					dW.Name = "CloseIcon"
					dW.Size = UDim2.fromOffset(dU, dU)
					dW.Position = UDim2.new(1, -(o._config.FramePadding.X + 1), 0.5, 0)
					dW.AnchorPoint = Vector2.new(1, 0.5)
					dW.AutoButtonColor = false
					dW.BackgroundTransparency = 1
					dW.BorderSizePixel = 0
					dW.ZIndex = L.ZIndex + 4
					dW.AutomaticSize = Enum.AutomaticSize.None
					c0(dW)
					dW.TextXAlignment = Enum.TextXAlignment.Center
					dW.Font = Enum.Font.Code
					dW.TextSize = o._config.TextSize * 2
					dW.Text = bJ.MULTIPLICATION_SIGN
					dW.Parent = dB
					bY(dW, 1e9)
					dW.MouseButton1Click:Connect(function()
						L.state.isOpened:set(false)
					end)
					c2(
						dW,
						dW,
						{
							ButtonColor = o._config.ButtonColor,
							ButtonTransparency = 1,
							ButtonHoveredColor = o._config.ButtonHoveredColor,
							ButtonHoveredTransparency = o._config.ButtonHoveredTransparency,
							ButtonActiveColor = o._config.ButtonActiveColor,
							ButtonActiveTransparency = o._config.ButtonActiveTransparency,
						}
					)
					local dX = Instance.new("TextLabel")
					dX.Name = "Title"
					dX.BorderSizePixel = 0
					dX.BackgroundTransparency = 1
					dX.ZIndex = L.ZIndex + 3
					dX.AutomaticSize = Enum.AutomaticSize.XY
					c0(dX)
					dX.Parent = dB
					local dY
					if o._config.WindowTitleAlign == Enum.LeftRight.Left then
						dY = 0
					elseif o._config.WindowTitleAlign == Enum.LeftRight.Center then
						dY = 0.5
					else
						dY = 1
					end
					dX.Position = UDim2.fromScale(dY, 0)
					dX.AnchorPoint = Vector2.new(dY, 0)
					bK(dX, o._config.FramePadding)
					local dZ = o._config.TextSize + o._config.FramePadding.X
					local d_ = Instance.new("TextButton")
					d_.Name = "ResizeGrip"
					d_.AnchorPoint = Vector2.new(1, 1)
					d_.Size = UDim2.fromOffset(dZ, dZ)
					d_.AutoButtonColor = false
					d_.BorderSizePixel = 0
					d_.BackgroundTransparency = 1
					d_.Text = bJ.BOTTOM_RIGHT_CORNER
					d_.ZIndex = L.ZIndex + 3
					d_.Position = UDim2.fromScale(1, 1)
					d_.TextSize = dZ
					d_.TextColor3 = o._config.ButtonColor
					d_.TextTransparency = o._config.ButtonTransparency
					d_.LineHeight = 1.10
					d_.Selectable = false
					c2(
						d_,
						d_,
						{
							ButtonColor = o._config.ButtonColor,
							ButtonTransparency = o._config.ButtonTransparency,
							ButtonHoveredColor = o._config.ButtonHoveredColor,
							ButtonHoveredTransparency = o._config.ButtonHoveredTransparency,
							ButtonActiveColor = o._config.ButtonActiveColor,
							ButtonActiveTransparency = o._config.ButtonActiveTransparency,
						},
						"Text"
					)
					d_.MouseButton1Down:Connect(function()
						if not dj or not (di == L) then
							o.SetFocusedWindow(L)
						end
						dc = true
						df = Enum.TopBottom.Bottom
						dg = Enum.LeftRight.Right
						db = L
					end)
					local e0 = Instance.new("TextButton")
					e0.Name = "ResizeBorder"
					e0.BackgroundTransparency = 1
					e0.BorderSizePixel = 0
					e0.ZIndex = L.ZIndex
					e0.LayoutOrder = L.ZIndex
					e0.Size = UDim2.new(1, o._config.WindowResizePadding.X * 2, 1, o._config.WindowResizePadding.Y * 2)
					e0.Position = UDim2.fromOffset(-o._config.WindowResizePadding.X, -o._config.WindowResizePadding.Y)
					dR.AutomaticSize = Enum.AutomaticSize.None
					e0.ClipsDescendants = false
					e0.Text = ""
					e0.AutoButtonColor = false
					e0.Active = true
					e0.Selectable = false
					e0.Parent = dR
					e0.MouseEnter:Connect(function()
						if di == L then
							dd = true
						end
					end)
					e0.MouseLeave:Connect(function()
						if di == L then
							dd = false
						end
					end)
					dR.MouseEnter:Connect(function()
						if di == L then
							de = true
						end
					end)
					dR.MouseLeave:Connect(function()
						if di == L then
							de = false
						end
					end)
					d_.Parent = dR
					return dQ
				end,
				Update = function(L)
					local dR = L.Instance.WindowButton
					local dB = dR.TitleBar
					local dX = dB.Title
					local cD = dR.ChildContainer
					local d_ = dR.ResizeGrip
					local e1 = o._config.TextSize + o._config.FramePadding.Y * 2
					d_.Visible = not L.arguments.NoResize
					if L.arguments.NoScrollbar then
						cD.ScrollBarThickness = 0
					else
						cD.ScrollBarThickness = o._config.ScrollbarSize
					end
					if L.arguments.NoTitleBar then
						dB.Visible = false
						cD.Size = UDim2.new(1, 0, 1, 0)
						cD.CanvasSize = UDim2.new(0, 0, 1, 0)
						cD.Position = UDim2.fromOffset(0, 0)
					else
						dB.Visible = true
						cD.Size = UDim2.new(1, 0, 1, -e1)
						cD.CanvasSize = UDim2.new(0, 0, 1, -e1)
						cD.Position = UDim2.fromOffset(0, e1)
					end
					if L.arguments.NoBackground then
						cD.BackgroundTransparency = 1
					else
						cD.BackgroundTransparency = o._config.WindowBgTransparency
					end
					local e2 = o._config.FramePadding.X + o._config.TextSize + o._config.FramePadding.X * 2
					if L.arguments.NoCollapse then
						dB.CollapseArrow.Visible = false
						dB.Title.UIPadding.PaddingLeft = UDim.new(0, o._config.FramePadding.X)
					else
						dB.CollapseArrow.Visible = true
						dB.Title.UIPadding.PaddingLeft = UDim.new(0, e2)
					end
					if L.arguments.NoClose then
						dB.CloseIcon.Visible = false
						dB.Title.UIPadding.PaddingRight = UDim.new(0, o._config.FramePadding.X)
					else
						dB.CloseIcon.Visible = true
						dB.Title.UIPadding.PaddingRight = UDim.new(0, e2)
					end
					dX.Text = L.arguments.Title or ""
				end,
				Discard = function(L)
					if di == L then
						di = nil
						dj = false
					end
					if d8 == L then
						d8 = nil
						d9 = false
					end
					if db == L then
						db = nil
						dc = false
					end
					dk[L.ID] = nil
					L.Instance:Destroy()
					ch(L)
				end,
				ChildAdded = function(L)
					return L.Instance.WindowButton.ChildContainer
				end,
				UpdateState = function(L)
					local e3 = L.state.size.value
					local e4 = L.state.position.value
					local e5 = L.state.isUncollapsed.value
					local e6 = L.state.isOpened.value
					local e7 = L.state.scrollDistance.value
					local dR = L.Instance.WindowButton
					dR.Size = UDim2.fromOffset(e3.X, e3.Y)
					dR.Position = UDim2.fromOffset(e4.X, e4.Y)
					local dB = dR.TitleBar
					local cD = dR.ChildContainer
					local d_ = dR.ResizeGrip
					if e6 then
						if L.usesScreenGUI then
							L.Instance.Enabled = true
							dR.Visible = true
						else
							dR.Visible = true
						end
						L.events.opened = true
					else
						if L.usesScreenGUI then
							L.Instance.Enabled = false
							dR.Visible = false
						else
							dR.Visible = false
						end
						L.events.closed = true
					end
					if e5 then
						dB.CollapseArrow.Text = bJ.DOWN_POINTING_TRIANGLE
						cD.Visible = true
						if L.arguments.NoResize == false then
							d_.Visible = true
						end
						dR.AutomaticSize = Enum.AutomaticSize.None
						L.events.uncollapsed = true
					else
						local e8 = o._config.TextSize + o._config.FramePadding.Y * 2
						dB.CollapseArrow.Text = bJ.RIGHT_POINTING_TRIANGLE
						cD.Visible = false
						d_.Visible = false
						dR.Size = UDim2.fromOffset(e3.X, e8)
						L.events.collapsed = true
					end
					if e6 and e5 then
						o.SetFocusedWindow(L)
					else
						dB.BackgroundColor3 = o._config.TitleBgCollapsedColor
						dB.BackgroundTransparency = o._config.TitleBgCollapsedTransparency
						dR.UIStroke.Color = o._config.BorderColor
						o.SetFocusedWindow(nil)
					end
					if e7 and e7 ~= 0 then
						local e9 = #o._postCycleCallbacks + 1
						local ea = o._cycleTick + 1
						o._postCycleCallbacks[e9] = function()
							if o._cycleTick == ea then
								cD.CanvasPosition = Vector2.new(0, e7)
								o._postCycleCallbacks[e9] = nil
							end
						end
					end
				end,
				GenerateState = function(L)
					if L.state.size == nil then
						L.state.size = o._widgetState(L, "size", Vector2.new(400, 300))
					end
					if L.state.position == nil then
						L.state.position = o._widgetState(
							L,
							"position",
							dj and di.state.position.value + Vector2.new(15, 45) or Vector2.new(150, 250)
						)
					end
					L.state.position.value = dz(L, L.state.position.value)
					L.state.size.value = dt(L, L.state.size.value)
					if L.state.isUncollapsed == nil then
						L.state.isUncollapsed = o._widgetState(L, "isUncollapsed", true)
					end
					if L.state.isOpened == nil then
						L.state.isOpened = o._widgetState(L, "isOpened", true)
					end
					if L.state.scrollDistance == nil then
						L.state.scrollDistance = o._widgetState(L, "scrollDistance", 0)
					end
				end,
			})
			o.Window = function(a6, ci)
				return o._Insert("Window", a6, ci)
			end
		end
	end
end)
c("deps.config", function(require, n, c, d)
	local eb = {
		colorDark = {
			TextColor = Color3.fromRGB(255, 255, 255),
			TextTransparency = 0,
			TextDisabledColor = Color3.fromRGB(128, 128, 128),
			TextDisabledTransparency = 0,
			BorderColor = Color3.fromRGB(110, 110, 125),
			BorderActiveColor = Color3.fromRGB(160, 160, 175),
			BorderTransparency = 0,
			BorderActiveTransparency = 0,
			WindowBgColor = Color3.fromRGB(15, 15, 15),
			WindowBgTransparency = 0.072,
			ScrollbarGrabColor = Color3.fromRGB(128, 128, 128),
			ScrollbarGrabTransparency = 0,
			TitleBgColor = Color3.fromRGB(10, 10, 10),
			TitleBgTransparency = 0,
			TitleBgActiveColor = Color3.fromRGB(41, 74, 122),
			TitleBgActiveTransparency = 0,
			TitleBgCollapsedColor = Color3.fromRGB(0, 0, 0),
			TitleBgCollapsedTransparency = 0.5,
			FrameBgColor = Color3.fromRGB(41, 74, 122),
			FrameBgTransparency = 0.46,
			FrameBgHoveredColor = Color3.fromRGB(66, 150, 250),
			FrameBgHoveredTransparency = 0.46,
			FrameBgActiveColor = Color3.fromRGB(66, 150, 250),
			FrameBgActiveTransparency = 0.33,
			ButtonColor = Color3.fromRGB(66, 150, 250),
			ButtonTransparency = 0.6,
			ButtonHoveredColor = Color3.fromRGB(66, 150, 250),
			ButtonHoveredTransparency = 0,
			ButtonActiveColor = Color3.fromRGB(15, 135, 250),
			ButtonActiveTransparency = 0,
			HeaderColor = Color3.fromRGB(66, 150, 250),
			HeaderTransparency = 0.31,
			HeaderHoveredColor = Color3.fromRGB(66, 150, 250),
			HeaderHoveredTransparency = 0.2,
			HeaderActiveColor = Color3.fromRGB(66, 150, 250),
			HeaderActiveTransparency = 0,
			SelectionImageObjectColor = Color3.fromRGB(255, 255, 255),
			SelectionImageObjectTransparency = 0.8,
			SelectionImageObjectBorderColor = Color3.fromRGB(255, 255, 255),
			SelectionImageObjectBorderTransparency = 0,
			TableBorderStrongColor = Color3.fromRGB(79, 79, 89),
			TableBorderStrongTransparency = 0,
			TableBorderLightColor = Color3.fromRGB(59, 59, 64),
			TableBorderLightTransparency = 0,
			TableRowBgColor = Color3.fromRGB(0, 0, 0),
			TableRowBgTransparency = 1,
			TableRowBgAltColor = Color3.fromRGB(255, 255, 255),
			TableRowBgAltTransparency = 0.94,
			NavWindowingHighlightColor = Color3.fromRGB(255, 255, 255),
			NavWindowingHighlightTransparency = 0.3,
			NavWindowingDimBgColor = Color3.fromRGB(204, 204, 204),
			NavWindowingDimBgTransparency = 0.65,
			SeparatorColor = Color3.fromRGB(110, 110, 128),
			SeparatorTransparency = 0.5,
			CheckMarkColor = Color3.fromRGB(66, 150, 250),
			CheckMarkTransparency = 0,
		},
		colorLight = {
			TextColor = Color3.fromRGB(0, 0, 0),
			TextTransparency = 0,
			TextDisabledColor = Color3.fromRGB(153, 153, 153),
			TextDisabledTransparency = 0,
			BorderColor = Color3.fromRGB(64, 64, 64),
			BorderActiveColor = Color3.fromRGB(64, 64, 64),
			WindowBgColor = Color3.fromRGB(240, 240, 240),
			WindowBgTransparency = 0,
			TitleBgColor = Color3.fromRGB(245, 245, 245),
			TitleBgTransparency = 0,
			TitleBgActiveColor = Color3.fromRGB(209, 209, 209),
			TitleBgActiveTransparency = 0,
			TitleBgCollapsedColor = Color3.fromRGB(255, 255, 255),
			TitleBgCollapsedTransparency = 0.5,
			ScrollbarGrabColor = Color3.fromRGB(96, 96, 96),
			ScrollbarGrabTransparency = 0,
			FrameBgColor = Color3.fromRGB(255, 255, 255),
			FrameBgTransparency = 0.6,
			FrameBgHoveredColor = Color3.fromRGB(66, 150, 250),
			FrameBgHoveredTransparency = 0.6,
			FrameBgActiveColor = Color3.fromRGB(66, 150, 250),
			FrameBgActiveTransparency = 0.33,
			ButtonColor = Color3.fromRGB(66, 150, 250),
			ButtonTransparency = 0.6,
			ButtonHoveredColor = Color3.fromRGB(66, 150, 250),
			ButtonHoveredTransparency = 0,
			ButtonActiveColor = Color3.fromRGB(15, 135, 250),
			ButtonActiveTransparency = 0,
			HeaderColor = Color3.fromRGB(66, 150, 250),
			HeaderTransparency = 0.31,
			HeaderHoveredColor = Color3.fromRGB(66, 150, 250),
			HeaderHoveredTransparency = 0.2,
			HeaderActiveColor = Color3.fromRGB(66, 150, 250),
			HeaderActiveTransparency = 0,
			SelectionImageObjectColor = Color3.fromRGB(0, 0, 0),
			SelectionImageObjectTransparency = 0.8,
			SelectionImageObjectBorderColor = Color3.fromRGB(0, 0, 0),
			SelectionImageObjectBorderTransparency = 0,
			TableBorderStrongColor = Color3.fromRGB(145, 145, 163),
			TableBorderStrongTransparency = 0,
			TableBorderLightColor = Color3.fromRGB(173, 173, 189),
			TableBorderLightTransparency = 0,
			TableRowBgColor = Color3.fromRGB(0, 0, 0),
			TableRowBgTransparency = 1,
			TableRowBgAltColor = Color3.fromRGB(77, 77, 77),
			TableRowBgAltTransparency = 0.91,
			NavWindowingHighlightColor = Color3.fromRGB(179, 179, 179),
			NavWindowingHighlightTransparency = 0.3,
			NavWindowingDimBgColor = Color3.fromRGB(51, 51, 51),
			NavWindowingDimBgTransparency = 0.8,
			SeparatorColor = Color3.fromRGB(99, 99, 99),
			SeparatorTransparency = 0.38,
			CheckMarkColor = Color3.fromRGB(66, 150, 250),
			CheckMarkTransparency = 0,
		},
		sizeDefault = {
			ItemWidth = UDim.new(1, 0),
			ContentWidth = UDim.new(0, 125),
			WindowPadding = Vector2.new(8, 8),
			WindowResizePadding = Vector2.new(6, 6),
			FramePadding = Vector2.new(4, 3),
			ItemSpacing = Vector2.new(8, 4),
			ItemInnerSpacing = Vector2.new(4, 4),
			CellPadding = Vector2.new(4, 2),
			IndentSpacing = 21,
			TextFont = Enum.Font.Code,
			TextSize = 13,
			FrameBorderSize = 0,
			FrameRounding = 0,
			WindowBorderSize = 1,
			WindowTitleAlign = Enum.LeftRight.Left,
			ScrollbarSize = 7,
		},
		sizeClear = {
			ItemWidth = UDim.new(1, 0),
			ContentWidth = UDim.new(0, 125),
			WindowPadding = Vector2.new(12, 8),
			WindowResizePadding = Vector2.new(8, 8),
			FramePadding = Vector2.new(6, 4),
			ItemSpacing = Vector2.new(8, 8),
			ItemInnerSpacing = Vector2.new(8, 8),
			CellPadding = Vector2.new(4, 4),
			IndentSpacing = 25,
			TextFont = Enum.Font.Nunito,
			TextSize = 17,
			FrameBorderSize = 1,
			FrameRounding = 4,
			WindowBorderSize = 1,
			WindowTitleAlign = Enum.LeftRight.Center,
			ScrollbarSize = 9,
		},
		utilityDefault = { UseScreenGUIs = true, Parent = nil, DisplayOrderOffset = 127, ZIndexOffset = 0 },
	}
	return eb
end)
return a("__root")
