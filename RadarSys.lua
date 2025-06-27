-- This is a LocalScript

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

local gui = script.Parent
local radarFrame = gui:WaitForChild("Frame"):WaitForChild("Frame")
local centerDot = radarFrame:WaitForChild("CDot")
local dotTemplate = gui:WaitForChild("Dot")
dotTemplate.Visible = false

gui.Enabled = false

local radarDistance = 1000 -- Any entity past 1000 will not render if StreamingEnabled is active
local excluded = {}

-- Check if something is in the exclusion list
local function checkExcluded(val, item)
	for _, i in pairs(excluded) do
		if i == item then
			return false
		end
	end
	return val
end

-- Exclude seated players
for _, seat in pairs(workspace:GetDescendants()) do
	if seat:IsA("Seat") or seat:IsA("VehicleSeat") then
		seat.ChildAdded:Connect(function(child)
			if child.Name == "SeatWeld" and child.Part1 and child.Part1.Parent:FindFirstChild("HumanoidRootPart") then
				table.insert(excluded, child.Part1.Parent.HumanoidRootPart)
			end
		end)
	end
end

-- Get the radar origin from the player's aircraft
local radarRoot = nil
local function getRadarRoot()
	local seated = character:FindFirstChild("Humanoid") and character.Humanoid.SeatPart
	if seated and seated.Name == "PilotSeat" then
		local plane = seated:FindFirstAncestorOfClass("Model")
		if plane and plane:FindFirstChild("Body") and plane.Body:FindFirstChild("Radar") then
			radarRoot = plane:FindFirstChild("MainParts") and plane.MainParts:FindFirstChild("HumanoidRootPart") or seated
			return true
		end
	end
	return false
end

-- is player seated?
local function monitorSeat()
	while true do
		task.wait(0.5)
		local isSeated = getRadarRoot()
		gui.Enabled = isSeated
	end
end

task.spawn(monitorSeat)

-- Main Radar loop
while true do
	task.wait(0.1)

	if not gui.Enabled or not radarRoot then continue end

	-- Clear existing radar dots
	for _, child in ipairs(radarFrame:GetChildren()) do
		if child.Name == "Dot" then
			child:Destroy()
		end
	end

	-- Update center rotation
	centerDot.Rotation = -radarRoot.Orientation.Y

	for _, model in ipairs(workspace:GetChildren()) do
		if model:IsA("Model") and model ~= character then
			local engine = model:FindFirstChild("Engine", true)  -- true = recursive search
			if engine and engine:IsA("BasePart") then
				if checkExcluded(true, engine) then
					local distance = (engine.Position - radarRoot.Position).Magnitude
					if distance <= radarDistance then
						local dot = dotTemplate:Clone()
						dot.Visible = true
						dot.Name = "Dot"
						dot.Parent = radarFrame

						local offset = engine.Position - radarRoot.Position
						local posX = (offset.X / radarDistance) / 2
						local posY = (offset.Z / radarDistance) / 2

						dot.Position = UDim2.new(0.5 + posX, 0, 0.5 + posY, 0)
						dot.Dist.Text = math.floor(distance) .. "m"
					end
				end
			end
		end
	end
end
