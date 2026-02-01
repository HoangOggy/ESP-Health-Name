-- settings
local settings = {
    defaultcolor = Color3.fromRGB(255,0,0),
    teamcheck = false,
    teamcolor = true,
    showName = true,
    showHealth = true
};

-- services
local runService = game:GetService("RunService");
local players = game:GetService("Players");

-- variables
local localPlayer = players.LocalPlayer;
local camera = workspace.CurrentCamera;

-- functions
local newVector2, newColor3, newDrawing = Vector2.new, Color3.new, Drawing.new;
local tan, rad = math.tan, math.rad;
local round = function(...) 
    local a = {}; 
    for i,v in next, table.pack(...) do 
        a[i] = math.round(v); 
    end 
    return unpack(a); 
end;

local wtvp = function(...)
    local a, b = camera:WorldToViewportPoint(...)
    return newVector2(a.X, a.Y), b, a.Z
end;

local espCache = {};

-- create esp
local function createEsp(player)
    local drawings = {};

    -- BOX
    drawings.box = newDrawing("Square");
    drawings.box.Thickness = 1;
    drawings.box.Filled = false;
    drawings.box.Color = settings.defaultcolor;
    drawings.box.Visible = false;
    drawings.box.ZIndex = 2;

    drawings.boxoutline = newDrawing("Square");
    drawings.boxoutline.Thickness = 3;
    drawings.boxoutline.Filled = false;
    drawings.boxoutline.Color = Color3.new(0,0,0);
    drawings.boxoutline.Visible = false;
    drawings.boxoutline.ZIndex = 1;

    -- NAME
    drawings.name = newDrawing("Text");
    drawings.name.Size = 13;
    drawings.name.Center = true;
    drawings.name.Outline = true;
    drawings.name.Font = 2;
    drawings.name.Visible = false;

    -- HEALTH BAR
    drawings.healthOutline = newDrawing("Square");
    drawings.healthOutline.Filled = false;
    drawings.healthOutline.Thickness = 1;
    drawings.healthOutline.Color = Color3.new(0,0,0);
    drawings.healthOutline.Visible = false;

    drawings.healthBar = newDrawing("Square");
    drawings.healthBar.Filled = true;
    drawings.healthBar.Color = Color3.fromRGB(0,255,0);
    drawings.healthBar.Visible = false;

    espCache[player] = drawings;
end

local function removeEsp(player)
    if espCache[player] then
        for _, drawing in pairs(espCache[player]) do
            drawing:Remove();
        end
        espCache[player] = nil;
    end
end

-- update esp
local function updateEsp(player, esp)
    local character = player.Character;
    local humanoid = character and character:FindFirstChildOfClass("Humanoid");
    local hrp = character and character:FindFirstChild("HumanoidRootPart");

    if not (character and humanoid and hrp) then
        for _,v in pairs(esp) do v.Visible = false end
        return;
    end

    local pos, visible, depth = wtvp(hrp.Position);
    if not visible then
        for _,v in pairs(esp) do v.Visible = false end
        return;
    end

    local scaleFactor = 1 / (depth * tan(rad(camera.FieldOfView / 2)) * 2) * 1000;
    local width, height = round(4 * scaleFactor, 5 * scaleFactor);
    local x, y = round(pos.X, pos.Y);

    -- BOX
    esp.box.Size = newVector2(width, height);
    esp.box.Position = newVector2(x - width/2, y - height/2);
    esp.box.Color = settings.teamcolor and player.TeamColor.Color or settings.defaultcolor;
    esp.box.Visible = true;

    esp.boxoutline.Size = esp.box.Size;
    esp.boxoutline.Position = esp.box.Position;
    esp.boxoutline.Visible = true;

    -- NAME
    if settings.showName then
        esp.name.Text = "@" .. player.Name
        esp.name.Position = newVector2(x, y - height/2 - 14)
        esp.name.Color = esp.box.Color
        esp.name.Visible = true
    else
        esp.name.Visible = false
    end

    -- HEALTH
    if settings.showHealth then
        local healthPercent = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1);
        local barHeight = height * healthPercent;

        esp.healthOutline.Size = newVector2(4, height);
        esp.healthOutline.Position = newVector2(x - width/2 - 6, y - height/2);
        esp.healthOutline.Visible = true;

        esp.healthBar.Size = newVector2(2, barHeight);
        esp.healthBar.Position = newVector2(
            x - width/2 - 5,
            y + height/2 - barHeight
        );

        esp.healthBar.Color = Color3.fromRGB(
            255 - (255 * healthPercent),
            255 * healthPercent,
            0
        );

        esp.healthBar.Visible = true
    else
        esp.healthBar.Visible = false
        esp.healthOutline.Visible = false
    end
end

-- init
for _, player in pairs(players:GetPlayers()) do
    if player ~= localPlayer then
        createEsp(player);
    end
end

players.PlayerAdded:Connect(createEsp);
players.PlayerRemoving:Connect(removeEsp);

runService:BindToRenderStep("esp", Enum.RenderPriority.Camera.Value, function()
    for player, drawings in pairs(espCache) do
        if settings.teamcheck and player.Team == localPlayer.Team then
            for _,v in pairs(drawings) do v.Visible = false end
            continue;
        end

        if player ~= localPlayer then
            updateEsp(player, drawings);
        end
    end
end)
