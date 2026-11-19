-- =====================================================================================
-- SlopCode Animatic  [SlopCode]
-- 1) FIRST it downloads the sounds from the SlopCode GitHub (AnimaticScriptSlopCode/stuff) into your executor workspace
--    folder with writefile (folder: SlopCodeAnimatic). Files that are already there are not downloaded again.
-- 2) then it becomes Canon Animatic (client-sided, only you see it).
-- =====================================================================================

pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "SlopCode made this!";
		Text = "SlopCode Animatic";
		Icon = "rbxthumb://type=Asset&id=8000227640&w=150&h=150";
		Duration = 5;
	})
end)

local FOLDER = "SlopCodeAnimatic"
local REPO_API = "https://api.github.com/repos/SlopCodeReal/AnimaticScriptSlopCode/contents/stuff"
local RAW_BASE = "https://raw.githubusercontent.com/SlopCodeReal/AnimaticScriptSlopCode/main/stuff/"
local KNOWN_SOUNDS = {                 -- used when the GitHub file list can't be read
	"exterminatedisable_93218827790086.mp3",
	"exterminateenable_87791481486562.mp3",
	"exterminationcubechase_85283702885491.mp3",
	"Animatic Battle OST HERE HE COMES.mp3",      -- (the real name in the GitHub folder has spaces)
	"exterminationcubecaught_86635411495114.mp3",
}
local KNOWN_MODELS = {
	"Canon Animatic Model.rbxm",
}

local SOUNDFILES = {}                  -- file name -> workspace path

local function httpGet(url)
	local ok, body = pcall(function() return game:HttpGet(url) end)
	if ok and type(body) == "string" and #body > 0 then return body end
	local req = (syn and syn.request) or http_request or request or (http and http.request) or (fluxus and fluxus.request)
	if req then
		local ok2, res = pcall(req, { Url = url, Method = "GET" })
		if ok2 and type(res) == "table" and res.StatusCode == 200 and type(res.Body) == "string" and #res.Body > 0 then return res.Body end
	end
	return nil
end

local function ensureFolder()
	if typeof(isfolder) == "function" and typeof(makefolder) == "function" then
		pcall(function() if not isfolder(FOLDER) then makefolder(FOLDER) end end)
	end
end

local function urlEncode(name)
	return (name:gsub("[^%w%-%._~]", function(c) return string.format("%%%02X", c:byte()) end))
end

-- local file names never contain spaces (some executors dislike them)
local function localName(name)
	return (name:gsub("%s+", "_"))
end

local function downloadSounds()
	if typeof(writefile) ~= "function" or typeof(isfile) ~= "function" then
		warn("[SlopCode Animatic] this executor has no writefile / isfile - nothing can be downloaded, the embedded model and rbxassetid sounds are used instead")
		return
	end
	ensureFolder()

	-- the file list of the GitHub folder: sounds + the model (falls back to the known files)
	local items = {}
	local body = httpGet(REPO_API .. "?ref=main")
	if body then
		local ok, data = pcall(function() return game:GetService("HttpService"):JSONDecode(body) end)
		if ok and type(data) == "table" then
			for _, it in ipairs(data) do
				if type(it) == "table" and it.type == "file" and type(it.name) == "string" then
					local ext = it.name:lower():match("%.(%w+)$")
					local kind = (ext == "mp3" or ext == "ogg" or ext == "wav") and "sound" or (ext == "rbxm" and "model") or nil
					if kind then
						items[#items + 1] = { name = it.name, kind = kind, url = (type(it.download_url) == "string" and it.download_url) or (RAW_BASE .. urlEncode(it.name)) }
					end
				end
			end
		end
	end
	if #items == 0 then
		for _, name in ipairs(KNOWN_SOUNDS) do items[#items + 1] = { name = name, kind = "sound", url = RAW_BASE .. urlEncode(name) } end
		for _, name in ipairs(KNOWN_MODELS) do items[#items + 1] = { name = name, kind = "model", url = RAW_BASE .. urlEncode(name) } end
	end

	local newFiles = 0
	for _, it in ipairs(items) do
		local lname = localName(it.name)
		local path = FOLDER .. "/" .. lname
		local have = false
		pcall(function() have = isfile(path) end)
		-- sounds are kept once downloaded; the model is fetched again every run so it stays up to date
		if it.kind == "model" or not have then
			local data = httpGet(it.url) or httpGet(RAW_BASE .. urlEncode(it.name))
			if data and (it.kind ~= "model" or data:sub(1, 8) == "<roblox!") then
				local ok = pcall(writefile, path, data)
				if ok then
					have = true
					newFiles += 1
				end
			else
				warn("[SlopCode Animatic] could not download " .. it.name)
			end
		end
		if have and it.kind == "sound" then SOUNDFILES[lname] = path end
	end
	if newFiles > 0 then
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = "SlopCode Animatic", Text = "Downloaded " .. newFiles .. " file(s) to your workspace folder", Duration = 4 })
		end)
	end
end

downloadSounds()

-- =====================================================================================

--[[
	SlopCode Animatic   [SlopCode]
	Canon Animatic (the Animatic skinned model) with the animations you found: idle, walk, chase run (running) and jump.
	The animations drive the model's 100 bones (Bone.Transform) straight from the Keyframe data in the animation files.
	Everything is CLIENT-SIDED and VISUAL ONLY: your real character is hidden on your screen, nobody else sees it.
	Standalone script (same style as the c00lkidd one) -- NOT an Uhhhhhh Reanimate moveset.

	The panel on the left has the three buttons of the original Animatic ability script (same names, same sounds):
	  Q  Start Extermination .... click a character: the EXTERMINATION CUBE flies to it (its chase sound plays ONLY while it is chasing).
	                              The moment it catches the victim the "cube caught" sound starts - it is the music of the extermination -
	                              the cube sits around the victim, the victim turns into a red silhouette and the whole world is blown
	                              out (white ground, black buildings, red trees, pink shadows, orange sunset sky with white sun rays) for
	                              as long as the music lasts (13 seconds); the victim turns white and vanishes, the music fades into the cube
	                              chase theme (which keeps looping while Extermination is on) and the world snaps back (only on YOUR screen)
	  E  Start Annihilation ..... click a character: the EXTERMINATION STAR (same mesh, its own sounds) chases it and the character
	                              shatters into pieces when it is caught (only on YOUR screen)
	  R  Start Recovery ......... brings back everything you exterminated / annihilated, and keeps bringing back new victims
	The enable / disable sounds play when you switch a mode on / off. The battle theme keeps playing (it is muted during an Extermination).
	If the cube's mesh/texture (they belong to the game) can't be loaded in the game you are in, a neon cube is shown instead.
	  T  Battle Theme ........... "Animatic Battle OST - HERE HE COMES" (from the same GitHub folder) loops the whole time; T turns it off / on

	Walking / running / jumping use your real character: idle when standing, walk, chase run when you run fast, the jump pose in the air.

	FILES: the model ("Canon Animatic Model.rbxm") is downloaded from the GitHub folder along with the sounds (an embedded copy is the
	fallback). The four animation files and the cube / star files are written into your workspace folder SlopCodeAnimatic by the
	standalone build. With the small loader build put them there yourself: Animatic_Idle.rbxm, Animatic_Walk.rbxm,
	Animatic_Chase.rbxm (animaticchaserun), Animatic_Jump.rbxm, Animatic_ExterminationCube.rbxm, Animatic_ExterminationStar.rbxm.
]]

--EMBEDDED_FILES

local function build()
	local m = {}

	local Players = game:GetService("Players")
	local UserInputService = game:GetService("UserInputService")
	local TweenService = game:GetService("TweenService")
	local Debris = game:GetService("Debris")
	local ContextActions = game:GetService("ContextActionService")
	local Lighting = game:GetService("Lighting")

	-- ===== config =====
	local FILES = {
		model = FOLDER .. "/Canon_Animatic_Model.rbxm",   -- downloaded from the GitHub folder (an embedded copy is the fallback)
		cube = FOLDER .. "/Animatic_ExterminationCube.rbxm",
		star = FOLDER .. "/Animatic_ExterminationStar.rbxm",
		idle = FOLDER .. "/Animatic_Idle.rbxm",
		walk = FOLDER .. "/Animatic_Walk.rbxm",
		chase = FOLDER .. "/Animatic_Chase.rbxm",
		jump = FOLDER .. "/Animatic_Jump.rbxm",
	}
	local MODELNAME = "Canon Animatic"
	local LIFT = 0                                   -- place the rig this many studs higher than the normal player
	local CHASESPEED = 15                            -- horizontal speed above this => chase run animation
	local GYRO_P, GYRO_D = 3000, 300                 -- turning damping (the BodyGyro values of the Robot 64 char part)
	local THEME_VOLUME = 0.5                         -- exterminationcubechase
	local BATTLE_VOLUME = 0.6                        -- Animatic Battle OST (HERE HE COMES), loops from the start
	local POSE_SCALE = 0.01                          -- the animation files store bone translations ~100x too big (Body y = 48, ArrowControl = 230...): scaled down to studs
	local BLEND = 0.2                                -- seconds the bones cross-fade when the animation changes
	local CLICK_COOLDOWN = 1                         -- seconds between two clicks, like the original
	local CUBE_SIZE = 7                              -- the Extermination Cube / Star grows from 0 to this size (7 studs in the game)
	local CUBE_SPEED = 45                            -- studs per second while it chases its target
	local CUBE_TIMEOUT = 15                          -- gives up after this many seconds
	local WALKSPEED = 50                             -- your WalkSpeed while Animatic is on (set to nil to leave it alone)
	local EXT_TIME = 13                              -- the Extermination sound is 13 seconds: the sequence lasts as long as it
	local CHASE_THEME_AFTER = true                   -- at the end the extermination music fades into the cube chase theme, which keeps looping while Extermination is on
	local CHASE_THEME_FADE = 2                       -- seconds of that crossfade
	local WORLD_RECOLOR = true                       -- during an Extermination the world turns white / black / red (only on your screen)
	local WORLD_RADIUS = 350                         -- how far around the victim parts get recoloured
	local WORLD_MAXPARTS = 5000
	local RAYS = true                                -- the sunburst rays in the sky
	local RECOVER_AFTER = 3                           -- seconds until the Recovery mode brings a victim back

	local plr = Players.LocalPlayer
	local mouse = plr:GetMouse()
	local ID = CFrame.new()
	local GYRO_TAU = GYRO_D / GYRO_P

	-- ===== state =====
	local char, hum, root
	local rig, rigRoot
	local bones = {}
	local frontYaw = 0
	local rigGround, offY, realGround = 6.85, 0, 3
	local OBJ = {}
	local anims = {}
	local hidden, conns = {}, {}
	local fxFolder
	local S = {
		ddt = nil, rot0 = true, yaw = nil, clocks = {},
		ext = false, ann = false, rec = false, busy = false, running = false, origWalk = nil, seq = 0,
		battle = true, cur = nil, switchT = 0,
	}
	local lastPose, snapPose = {}, {}
	local pending = {}       -- characters an Extermination Cube / Star is on its way to
	local cubes = {}
	local FXOBJ = { loaded = false, meshOk = true }
	local affected = {}      -- character -> { parts = { part -> {Transparency, Color, Material} }, since = os.clock() }
	local theme, battle, chaseMusic

	-- ===== helpers =====
	local function notify(title, text)
		pcall(function()
			game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = tostring(text):sub(1, 180), Duration = 6 })
		end)
	end

	local function b64decode(s, forceLua)
		local ok, r = false, nil
		if not forceLua then ok, r = pcall(function()
			if crypt and crypt.base64decode then return crypt.base64decode(s) end
			if crypt and crypt.base64 and crypt.base64.decode then return crypt.base64.decode(s) end
			if base64_decode then return base64_decode(s) end
			if base64 and base64.decode then return base64.decode(s) end
			if syn and syn.crypt and syn.crypt.base64 and syn.crypt.base64.decode then return syn.crypt.base64.decode(s) end
		end) end
		if ok and type(r) == "string" and #r > 0 then return r end
		local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
		local map = {}
		for i = 1, 64 do map[string.byte(chars, i)] = i - 1 end
		local parts, pn, len, n = {}, 0, #s, 0
		local i = 1
		while i <= len do
			local a, b, c, d = string.byte(s, i, i + 3)
			local v = (map[a] or 0) * 262144 + (map[b] or 0) * 4096 + (map[c] or 0) * 64 + (map[d] or 0)
			local b1, b2, b3 = v // 65536, (v // 256) % 256, v % 256
			pn += 1
			if c == 61 then
				parts[pn] = string.char(b1)
			elseif d == 61 then
				parts[pn] = string.char(b1, b2)
			else
				parts[pn] = string.char(b1, b2, b3)
			end
			i += 4
			n += 1
			if n % 30000 == 0 then task.wait() end
		end
		return table.concat(parts)
	end

	-- loads an rbxm from the workspace folder (writing the embedded copy first if there is one)
	local function loadFile(key)
		local file = FILES[key]
		local embedded = EMB and EMB[key]
		local hasFs = typeof(isfile) == "function" and typeof(writefile) == "function"
		local lastErr = file .. " is not in your workspace folder"
		local function writeEmbedded()
			if not (embedded and hasFs) then return false end
			ensureFolder()
			local ok, err = pcall(function()
				local data = b64decode(embedded)
				if data:sub(1, 8) ~= "<roblox!" then data = b64decode(embedded, true) end
				if data:sub(1, 8) ~= "<roblox!" then error("decoded data is not an rbxm file") end
				writefile(file, data)
			end)
			if not ok then lastErr = "writefile failed: " .. tostring(err) end
			return ok
		end
		if embedded and hasFs and not isfile(file) then writeEmbedded() end
		if typeof(getcustomasset) ~= "function" then return nil, "this executor has no getcustomasset" end
		if typeof(isfile) == "function" and isfile(file) then
			local ok, objs = pcall(function() return game:GetObjects(getcustomasset(file)) end)
			if not (ok and type(objs) == "table" and #objs > 0) and embedded and hasFs then
				if writeEmbedded() then
					ok, objs = pcall(function() return game:GetObjects(getcustomasset(file)) end)
				end
			end
			if ok and type(objs) == "table" and #objs > 0 then return objs end
			lastErr = "GetObjects(" .. file .. ") failed: " .. tostring(objs)
		end
		return nil, lastErr
	end

	-- ===== animations (read straight from the KeyframeSequences) =====
	local function compileSeq(ks)
		local frames = ks:GetKeyframes()
		table.sort(frames, function(a, b) return a.Time < b.Time end)
		local tracks, len = {}, 0
		for _, kf in ipairs(frames) do
			len = math.max(len, kf.Time)
			local function walk(list)
				for _, p in ipairs(list) do
					if p.Weight > 0 then
						local tr = tracks[p.Name]
						if not tr then
							tr = { ts = {}, cfs = {} }
							tracks[p.Name] = tr
						end
						tr.ts[#tr.ts + 1] = kf.Time
						local cf = p.CFrame
						tr.cfs[#tr.cfs + 1] = CFrame.new(cf.Position * POSE_SCALE) * (cf - cf.Position)
					end
					walk(p:GetSubPoses())
				end
			end
			walk(kf:GetPoses())
		end
		return { len = len, loop = ks.Loop, tracks = tracks }
	end

	local function loadAnim(key)
		local objs, err = loadFile(key)
		if not objs then return nil, err end
		local ks
		for _, o in ipairs(objs) do
			if o:IsA("KeyframeSequence") then ks = o break end
			local d = o:FindFirstChildWhichIsA("KeyframeSequence", true)
			if d then ks = d break end
		end
		if not ks then return nil, "no KeyframeSequence in " .. FILES[key] end
		local ok, res = pcall(compileSeq, ks)
		for _, o in ipairs(objs) do pcall(function() o:Destroy() end) end
		if not ok then return nil, tostring(res) end
		return res
	end

	local function sampleTrack(tr, t)
		local ts, cfs = tr.ts, tr.cfs
		local n = #ts
		if n == 1 or t <= ts[1] then return cfs[1] end
		if t >= ts[n] then return cfs[n] end
		local lo, hi = 1, n
		while hi - lo > 1 do
			local mid = (lo + hi) // 2
			if ts[mid] <= t then lo = mid else hi = mid end
		end
		return cfs[lo]:Lerp(cfs[hi], (t - ts[lo]) / (ts[hi] - ts[lo]))
	end

	local function clockOf(name, adv, dt)
		local c = anims[name]
		local t = (S.clocks[name] or 0) + adv * dt
		if c.len > 0 then
			if c.loop then t = t % c.len else t = math.min(t, c.len) end
		else
			t = 0
		end
		S.clocks[name] = t
		return t
	end

	-- ===== sounds =====
	local function soundEntry(prefix)
		for name, path in pairs(SOUNDFILES) do
			if name:lower():sub(1, #prefix) == prefix then return name, path end
		end
		for _, name in ipairs(KNOWN_SOUNDS) do
			local ln = localName(name)
			if ln:lower():sub(1, #prefix) == prefix then return ln, nil end
		end
	end

	local function makeSound(prefix, volume, looped)
		local name, path = soundEntry(prefix)
		if not name then return nil end
		local s = Instance.new("Sound")
		local id = name:match("_(%d+)%.%w+$")
		local ok = false
		if path and typeof(getcustomasset) == "function" then
			ok = pcall(function() s.SoundId = getcustomasset(path) end)
		end
		if not ok and id then s.SoundId = "rbxassetid://" .. id end
		s.Volume = volume or 0.5
		s.Looped = looped or false
		s.Parent = workspace
		return s
	end

	-- the playable id of one of the downloaded sounds (workspace file if possible, otherwise rbxassetid from the file name)
	local function soundIdFor(prefix)
		local name, path = soundEntry(prefix)
		if not name then return nil end
		if path and typeof(getcustomasset) == "function" then
			local ok, a = pcall(getcustomasset, path)
			if ok and a then return a end
		end
		local id = name:match("_(%d+)%.%w+$")
		return id and ("rbxassetid://" .. id) or nil
	end

	local function playOnce(prefix, volume)
		local s = makeSound(prefix, volume, false)
		if s then
			s:Play()
			s.Ended:Connect(function() s:Destroy() end)
			Debris:AddItem(s, 15)
		end
	end

	-- the battle theme is muted while an extermination runs and while the chase theme plays
	local function applyBattleVolume()
		if battle then pcall(function() battle.Volume = ((S.seq > 0) or chaseMusic) and 0 or BATTLE_VOLUME end) end
	end

	local function stopChaseTheme(fade)
		local cm = chaseMusic
		if not cm then return end
		chaseMusic = nil
		applyBattleVolume()
		if fade and fade > 0 then
			pcall(function() TweenService:Create(cm, TweenInfo.new(fade), { Volume = 0 }):Play() end)
			task.delay(fade + 0.1, function() pcall(function() cm:Stop() cm:Destroy() end) end)
		else
			pcall(function() cm:Stop() cm:Destroy() end)
		end
	end

	local function startChaseTheme(fade)
		if chaseMusic then return chaseMusic end
		local cm = makeSound("exterminationcubechase", 0, true)
		if not cm then return nil end
		chaseMusic = cm
		cm:Play()
		pcall(function() TweenService:Create(cm, TweenInfo.new(fade or 0.5), { Volume = THEME_VOLUME }):Play() end)
		applyBattleVolume()
		return cm
	end

	local function updateTheme()
		local battleWant = S.battle and rig ~= nil
		if battleWant and not battle then
			battle = makeSound("animatic_battle_ost", BATTLE_VOLUME, true)
			if battle then battle:Play() applyBattleVolume() end
		elseif not battleWant and battle then
			battle:Stop()
			battle:Destroy()
			battle = nil
		end
	end

	-- ===== effects (client only) =====
	local function fxParent()
		if not fxFolder or not fxFolder.Parent then
			fxFolder = Instance.new("Folder")
			fxFolder.Name = "AnimaticFX"
			fxFolder.Parent = workspace
		end
		return fxFolder
	end

	local function cube(pos, size, color, neon)
		local p = Instance.new("Part")
		p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
		p.Size, p.Color, p.CFrame = size, color, CFrame.new(pos) * CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6)
		p.Material = neon and Enum.Material.Neon or Enum.Material.SmoothPlastic
		p.Parent = fxParent()
		return p
	end

	local function burst(pos, count, spread, dark)
		for _ = 1, count do
			local s = 0.4 + math.random() * 0.9
			local c = dark and Color3.fromRGB(math.random(5, 25), 0, math.random(15, 40)) or Color3.fromRGB(150 + math.random(0, 80), 40, 200)
			local p = cube(pos + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5) * 2, Vector3.new(s, s, s), c, not dark)
			local dir = Vector3.new(math.random() - 0.5, math.random() * 0.8, math.random() - 0.5).Unit * spread * (0.5 + math.random())
			TweenService:Create(p, TweenInfo.new(0.9, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = p.CFrame + dir, Transparency = 1, Size = p.Size * 0.2,
			}):Play()
			Debris:AddItem(p, 1.2)
		end
	end

	local function characterOf(part)
		if not part then return nil end
		local x = part
		while x and x ~= workspace do
			if x:IsA("Model") and x:FindFirstChildOfClass("Humanoid") then return x end
			x = x.Parent
		end
		return nil
	end

	local function remember(target)
		local rec = affected[target]
		if rec then return rec end
		rec = { parts = {}, since = os.clock() }
		for _, d in ipairs(target:GetDescendants()) do
			if d:IsA("BasePart") then
				rec.parts[d] = { Transparency = d.Transparency, Color = d.Color, Material = d.Material, Tex = d:IsA("MeshPart") and d.TextureID or nil }
			elseif d:IsA("Decal") then
				rec.parts[d] = { Transparency = d.Transparency }
			elseif d:IsA("SpecialMesh") then
				rec.parts[d] = { TexId = d.TextureId }
			end
		end
		affected[target] = rec
		return rec
	end

	local function restore(target)
		local rec = affected[target]
		if not rec then return end
		for d, props in pairs(rec.parts) do
			if d.Parent then
				pcall(function()
					if props.Transparency then d.Transparency = props.Transparency end
					if props.Color then d.Color = props.Color end
					if props.Material then d.Material = props.Material end
					if props.Tex then d.TextureID = props.Tex end
					if props.TexId then d.TextureId = props.TexId end
				end)
			end
		end
		affected[target] = nil
	end

	local function restoreAll()
		local n = 0
		for target in pairs(affected) do
			if not pending[target] then
				restore(target)
				n += 1
			end
		end
		return n
	end

	local function exterminate(target)
		local rec = remember(target)
		local pos = (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")).Position
		for d in pairs(rec.parts) do
			if d:IsA("BasePart") then
				d.Color = Color3.fromRGB(10, 0, 18)
				d.Material = Enum.Material.Neon
				TweenService:Create(d, TweenInfo.new(0.8), { Transparency = 1 }):Play()
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end
		burst(pos, 16, 7, true)
	end

	local function annihilate(target)
		local rec = remember(target)
		local pos = (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")).Position
		local n = 0
		for d in pairs(rec.parts) do
			if d:IsA("BasePart") then
				n += 1
				if n <= 14 then
					local s = math.max(0.3, math.min(d.Size.X, d.Size.Y, d.Size.Z) * 0.6)
					for _ = 1, 3 do
						local p = cube(d.Position + Vector3.new(math.random() - 0.5, math.random() - 0.5, math.random() - 0.5), Vector3.new(s, s, s), d.Color, false)
						local dir = Vector3.new(math.random() - 0.5, math.random() * 0.6, math.random() - 0.5).Unit * (4 + math.random() * 8)
						TweenService:Create(p, TweenInfo.new(1.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
							CFrame = p.CFrame * CFrame.Angles(math.random() * 6, math.random() * 6, 0) + dir, Transparency = 1,
						}):Play()
						Debris:AddItem(p, 1.4)
					end
				end
				d.Transparency = 1
			elseif d:IsA("Decal") then
				d.Transparency = 1
			end
		end
		burst(pos, 10, 10, false)
	end

	-- ===== Extermination Cube / Annihilation Star =====
	-- From the game's files: a MeshPart that starts at size 0 and grows to 7 studs, its own looping chase sound (3D),
	-- a "caught" sound when it reaches the target, and a particle burst (ExterminationParticle) on the catch.
	local function loadCubeFx()
		if FXOBJ.loaded then return end
		FXOBJ.loaded = true
		for _, key in ipairs({ "cube", "star" }) do
			local objs = loadFile(key)
			if objs then
				for _, o in ipairs(objs) do
					if o:IsA("MeshPart") then FXOBJ[key] = o break end
				end
			end
		end
		-- the mesh / texture ids belong to the game; if they can't be loaded here a neon cube is shown instead
		local probe = FXOBJ.cube or FXOBJ.star
		if probe then
			local failed = false
			pcall(function()
				game:GetService("ContentProvider"):PreloadAsync({ probe }, function(id, status)
					if tostring(id):find("89365530075950", 1, true) and status == Enum.AssetFetchStatus.Failure then failed = true end
				end)
			end)
			FXOBJ.meshOk = not failed
		end
	end

	local function spawnCube(kind, target, onCaught, opts)
		loadCubeFx()
		local tpl = FXOBJ[kind]
		local startPos = (rigRoot and rigRoot.Position or root.Position) + Vector3.new(0, 3, 0)

		local main
		if tpl then
			main = tpl:Clone()
			for _, d in ipairs(main:GetDescendants()) do
				if d.Name == "SecondaryCube" or d:IsA("BaseScript") then pcall(function() d:Destroy() end) end
			end
		else
			main = Instance.new("Part")
			main.Material = Enum.Material.Neon
			main.Color = Color3.fromRGB(120, 40, 220)
		end
		main.Anchored, main.CanCollide, main.CanQuery, main.CanTouch, main.CastShadow = true, false, false, false, false
		main.Size = Vector3.new(0.05, 0.05, 0.05)
		main.CFrame = CFrame.new(startPos)
		main.Parent = fxParent()

		local block
		if tpl and not FXOBJ.meshOk then
			main.Transparency = 1
			block = Instance.new("Part")
			block.Anchored, block.CanCollide, block.CanQuery, block.CanTouch, block.CastShadow = true, false, false, false, false
			block.Material = Enum.Material.Neon
			block.Color = kind == "cube" and Color3.new(1, 1, 1) or Color3.fromRGB(255, 200, 80)
			block.Transparency = 0.7
			block.Size = main.Size
			block.CFrame = main.CFrame
			block.Parent = fxParent()
		end

		-- sounds (the ones in the file; the cube's use the downloaded mp3s when they exist)
		local chase = main:FindFirstChild("Sound")
		local caught = main:FindFirstChild("ExterminateSound")
		if not chase then
			chase = Instance.new("Sound")
			chase.Name = "Sound"
			chase.RollOffMinDistance, chase.RollOffMaxDistance, chase.Volume = 50, 500, 3
			chase.Parent = main
		end
		if not caught then
			caught = Instance.new("Sound")
			caught.Name = "ExterminateSound"
			caught.RollOffMinDistance, caught.RollOffMaxDistance, caught.Volume = 100, 500, 2
			caught.Parent = main
		end
		if kind == "cube" then
			local cid, xid = soundIdFor("exterminationcubechase"), soundIdFor("exterminationcubecaught")
			if cid then chase.SoundId = cid elseif chase.SoundId == "" then chase.SoundId = "rbxassetid://85283702885491" end
			if xid then caught.SoundId = xid elseif caught.SoundId == "" then caught.SoundId = "rbxassetid://86635411495114" end
		end
		chase.Looped = true
		chase:Play()

		local emitter = main:FindFirstChildWhichIsA("ParticleEmitter", true)
		if not emitter then
			local att = Instance.new("Attachment", main)
			emitter = Instance.new("ParticleEmitter")
			emitter.Texture = "http://www.roblox.com/asset/?id=1598630577"
			emitter.LightEmission = 5
			emitter.Enabled = false
			emitter.Parent = att
		end

		-- white outline + faint fill, so the cube reads as a see-through hexagon like in the video
		local hl = Instance.new("Highlight")
		hl.Adornee = block or main
		hl.FillColor = Color3.new(1, 1, 1)
		hl.FillTransparency = kind == "cube" and 0.8 or 0.6
		hl.OutlineColor = kind == "cube" and Color3.new(1, 1, 1) or Color3.fromRGB(255, 220, 120)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = main

		local hold = opts and opts.hold
		local tp0 = hold and target and target.Parent and (target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart"))
		local c = {
			main = main, block = block, target = target, onCaught = onCaught,
			t0 = os.clock(), scale = 0.05, state = hold and "hold" or "grow", pos = tp0 and tp0.Position or startPos, spin = 0,
			chase = chase, caught = caught, emitter = emitter, kind = kind, scaleFn = opts and opts.scaleFn, sequence = opts and opts.sequence,
		}
		cubes[#cubes + 1] = c
		return c
	end

	local function targetPos(target)
		if not (target and target.Parent) then return nil end
		local r = target:FindFirstChild("HumanoidRootPart") or target:FindFirstChildWhichIsA("BasePart")
		return r and r.Position or nil
	end

	local function updateCubes(dt)
		local now = os.clock()
		for i = #cubes, 1, -1 do
			local c = cubes[i]
			if not c.main.Parent then
				table.remove(cubes, i)
			else
				if c.state == "grow" then
					c.scale = math.min(CUBE_SIZE, c.scale + CUBE_SIZE * dt / 0.5)
					if c.scale >= CUBE_SIZE then c.state = "chase" end
				elseif c.state == "hold" then
					-- the cube stays on its target (the Extermination sequence controls its size and when it is done)
					local tp = targetPos(c.target)
					if tp then c.pos = c.pos:Lerp(tp + Vector3.new(0, 0.5, 0), math.min(1, dt * 14)) end
					if c.scaleFn then c.scale = c.scaleFn(now) end
					if c.done then c.state, c.tState = "vanish", now end
				elseif c.state == "chase" then
					local tp = targetPos(c.target)
					if not tp or now - c.t0 > CUBE_TIMEOUT then
						c.state, c.tState = "vanish", now
						c.chase:Stop()
						if c.target then pending[c.target] = nil end
					else
						local dir = tp - c.pos
						local dist = dir.Magnitude
						if dist <= c.scale * 0.5 + 3 then
							c.chase:Stop()          -- the chase sound only plays while it is chasing
							pcall(function() c.emitter:Emit(30) end)
							if c.sequence then
								-- Extermination: the cube stays on the victim and the sequence (with its music) starts right now
								c.state, c.tState = "hold", now
								if c.onCaught then task.spawn(c.onCaught, c.target, c) end
							else
								c.state, c.tState = "caught", now
								c.caught:Play()
								if c.onCaught then pcall(c.onCaught, c.target) end
							end
						else
							c.pos = c.pos + dir.Unit * math.min(dist, CUBE_SPEED * dt)
						end
					end
				else
					-- caught / vanish: shrink away, then remove (the caught sound keeps playing from the cube until it is gone)
					local k = math.clamp((now - c.tState) / (c.state == "caught" and 0.9 or 0.4), 0, 1)
					c.scale = CUBE_SIZE * (1 - k)
					if k >= 1 then
						c.chase:Stop()
						task.delay(3, function() pcall(function() c.main:Destroy() end) end)
						c.main.Transparency = 1
						if c.block then c.block:Destroy() end
						table.remove(cubes, i)
						continue
					end
				end
				c.spin += dt * 1.2
				local sz = math.max(0.05, c.scale)
				c.main.Size = Vector3.new(sz, sz, sz)
				c.main.CFrame = CFrame.new(c.pos) * CFrame.Angles(c.spin, c.spin * 0.7, 0)
				if c.block then
					c.block.Size = c.main.Size
					c.block.CFrame = c.main.CFrame
				end
			end
		end
	end

	-- ===== the Extermination sequence (what the video shows) =====
	-- a see-through cube around the victim, the victim a red silhouette (then white), the world blown out to
	-- white ground / black buildings / red trees with pink shadows under an orange sky full of white sun rays
	local WORLD = { on = false, count = 0, parts = {}, terrain = {}, light = {}, fx = {}, rays = {}, spin = 0 }
	local BLACK, WHITE, LEAFRED = Color3.fromRGB(12, 12, 14), Color3.fromRGB(255, 255, 255), Color3.fromRGB(150, 16, 24)

	local function mapWorldColor(c)
		local h, s, v = c:ToHSV()
		if v < 0.28 then return BLACK end
		if s > 0.22 and h > 0.17 and h < 0.5 then return LEAFRED end   -- greens (leaves) -> dark red
		if v > 0.55 then return WHITE end
		return BLACK
	end

	local function buildRays()
		for i = 0, 3 do
			for j = 0, 31 do
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
				p.Material = Enum.Material.Neon
				p.Color = (j % 2 == 0) and Color3.new(1, 1, 1) or Color3.fromRGB(255, 140, 30)
				p.Size = Vector3.new(70, 70, 2800)
				p.Parent = fxParent()
				WORLD.rays[#WORLD.rays + 1] = { part = p, fan = i, a = (j / 32) * math.pi * 2 }
			end
		end
	end

	local function updateWorld(dt)
		if not (WORLD.on and RAYS and #WORLD.rays > 0) then return end
		WORLD.spin += dt * 0.12
		local cam = workspace.CurrentCamera
		if not cam then return end
		local base = cam.CFrame.Position
		for _, r in ipairs(WORLD.rays) do
			local ang = r.fan * math.pi / 2
			local dir = Vector3.new(math.cos(ang), 0, math.sin(ang))
			local u = Vector3.new(-dir.Z, 0, dir.X)
			local fanCenter = base + dir * 2300 + Vector3.new(0, 450, 0)
			local a = r.a + WORLD.spin
			local d = u * math.cos(a) + Vector3.new(0, math.sin(a), 0)
			local center = fanCenter + d * 1400
			r.part.CFrame = CFrame.lookAt(center, center + d, dir)
		end
	end

	local function worldOn(center)
		if WORLD.on then
			WORLD.count += 1
			return
		end
		WORLD.on, WORLD.count = true, 1

		-- lighting: orange sunset sky, pink shadows, blown out
		WORLD.light = {
			Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness,
			ColorShift_Top = Lighting.ColorShift_Top, ExposureCompensation = Lighting.ExposureCompensation, ClockTime = Lighting.ClockTime,
		}
		pcall(function()
			Lighting.Ambient = Color3.fromRGB(255, 70, 200)
			Lighting.OutdoorAmbient = Color3.fromRGB(255, 70, 200)
			Lighting.Brightness = 3
			Lighting.ColorShift_Top = Color3.fromRGB(255, 170, 60)
			Lighting.ExposureCompensation = 0.4
			Lighting.ClockTime = 17.4
		end)
		local function mk(class, props)
			local i = Instance.new(class)
			for k, v in pairs(props) do i[k] = v end
			i.Parent = Lighting
			WORLD.fx[#WORLD.fx + 1] = i
			return i
		end
		mk("ColorCorrectionEffect", { TintColor = Color3.fromRGB(255, 235, 215), Contrast = 1, Saturation = 1, Brightness = 0.05 })
		mk("BloomEffect", { Intensity = 1.2, Size = 30, Threshold = 0.85 })
		mk("SunRaysEffect", { Intensity = 0.4, Spread = 1 })
		local atm = Lighting:FindFirstChildOfClass("Atmosphere")
		if atm then
			WORLD.atm = { inst = atm, Color = atm.Color, Decay = atm.Decay, Density = atm.Density, Haze = atm.Haze, Glare = atm.Glare, Offset = atm.Offset }
		else
			atm = mk("Atmosphere", {})
		end
		pcall(function()
			atm.Color, atm.Decay = Color3.fromRGB(255, 150, 50), Color3.fromRGB(255, 110, 40)
			atm.Density, atm.Haze, atm.Glare, atm.Offset = 0.1, 1, 0.4, 0.25
		end)

		-- terrain: everything white except rocky materials
		pcall(function()
			local T = workspace.Terrain
			for _, mat in ipairs(Enum.Material:GetEnumItems()) do
				local ok, old = pcall(function() return T:GetMaterialColor(mat) end)
				if ok and old then
					WORLD.terrain[mat] = old
					local n = mat.Name
					local dark = (n == "Rock" or n == "Basalt" or n == "Slate" or n == "CrackedLava" or n == "Asphalt")
					pcall(function() T:SetMaterialColor(mat, dark and BLACK or WHITE) end)
				end
			end
		end)

		if RAYS then buildRays() end

		if WORLD_RECOLOR then
			task.spawn(function()
				local params = OverlapParams.new()
				params.MaxParts = WORLD_MAXPARTS
				params.FilterType = Enum.RaycastFilterType.Exclude
				local ex = { rig, fxParent() }
				for _, pl in ipairs(Players:GetPlayers()) do
					if pl.Character then ex[#ex + 1] = pl.Character end
				end
				params.FilterDescendantsInstances = ex
				local ok, found = pcall(function() return workspace:GetPartBoundsInRadius(center, WORLD_RADIUS, params) end)
				if not ok or type(found) ~= "table" then return end
				for i, part in ipairs(found) do
					if not WORLD.on then break end
					if part.Parent and part.Transparency < 0.9 and not part:IsA("Terrain") then
						WORLD.parts[part] = part.Color
						pcall(function() part.Color = mapWorldColor(part.Color) end)
					end
					if i % 250 == 0 then task.wait() end
				end
			end)
		end
	end

	local function worldOff(immediate)
		if not WORLD.on then return end
		WORLD.count -= 1
		if WORLD.count > 0 and not immediate then return end
		WORLD.on, WORLD.count = false, 0

		pcall(function()
			for k, v in pairs(WORLD.light) do Lighting[k] = v end
		end)
		for _, i in ipairs(WORLD.fx) do pcall(function() i:Destroy() end) end
		table.clear(WORLD.fx)
		if WORLD.atm then
			local a = WORLD.atm
			pcall(function()
				a.inst.Color, a.inst.Decay, a.inst.Density, a.inst.Haze, a.inst.Glare, a.inst.Offset = a.Color, a.Decay, a.Density, a.Haze, a.Glare, a.Offset
			end)
			WORLD.atm = nil
		end
		pcall(function()
			local T = workspace.Terrain
			for mat, old in pairs(WORLD.terrain) do pcall(function() T:SetMaterialColor(mat, old) end) end
		end)
		table.clear(WORLD.terrain)
		for _, r in ipairs(WORLD.rays) do pcall(function() r.part:Destroy() end) end
		table.clear(WORLD.rays)

		-- the recoloured parts go back (in chunks so nothing freezes)
		local parts = WORLD.parts
		WORLD.parts = {}
		if immediate then
			for part, col in pairs(parts) do pcall(function() part.Color = col end) end
		else
			task.spawn(function()
				local n = 0
				for part, col in pairs(parts) do
					if part.Parent then pcall(function() part.Color = col end) end
					n += 1
					if n % 300 == 0 then task.wait() end
				end
			end)
		end
	end

	local function runExtermination(target, finished, cube)
		if not (target and target.Parent) then
			pending[target] = nil
			if cube then cube.done = true end
			if finished then finished(target) end
			return
		end
		local rec = remember(target)
		local tp = targetPos(target) or root.Position

		local function paint(color, material)
			for d in pairs(rec.parts) do
				if d:IsA("BasePart") then
					d.Color, d.Material = color, material
					if d:IsA("MeshPart") then d.TextureID = "" end
				elseif d:IsA("SpecialMesh") then
					d.TextureId = ""
				elseif d:IsA("Decal") then
					d.Transparency = 1
				end
			end
		end

		-- the "cube caught" sound is the music of the Extermination: it starts the moment the cube catches the victim
		local dur = EXT_TIME
		S.seq += 1
		stopChaseTheme(0.3)
		local music = makeSound("exterminationcubecaught", 2, false)
		if music then
			music:Play()
			music.Ended:Connect(function() music:Destroy() end)
		end
		applyBattleVolume()

		-- the victim: red silhouette with a black outline
		local hl = Instance.new("Highlight")
		hl.Adornee = target
		hl.FillTransparency = 1
		hl.OutlineColor = Color3.new(0, 0, 0)
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.Occluded
		hl.Parent = fxParent()
		paint(Color3.fromRGB(190, 12, 12), Enum.Material.SmoothPlastic)

		-- the cube that caught it stays around the victim, tilts and slowly shrinks
		local t0 = os.clock()
		if not cube then
			cube = spawnCube("cube", target, nil, { hold = true })
		end
		cube.scaleFn = function(now)
			local grow = math.min(1, (now - t0) / 0.25)
			local shrink = 1 - 0.6 * math.clamp((now - t0) / dur, 0, 1)
			return CUBE_SIZE * 1.15 * grow * shrink
		end
		worldOn(tp)

		local whitened, faded, crossfading = false, false, false
		while S.running and os.clock() - t0 < dur do
			-- the sequence is as long as the music (13 seconds)
			if music and music.TimeLength > 2 then dur = math.min(music.TimeLength, 40) end
			local age = os.clock() - t0
			-- the music fades into the cube chase theme
			if CHASE_THEME_AFTER and not crossfading and age >= dur - CHASE_THEME_FADE then
				crossfading = true
				if music then pcall(function() TweenService:Create(music, TweenInfo.new(CHASE_THEME_FADE), { Volume = 0 }):Play() end) end
				if S.ext then startChaseTheme(CHASE_THEME_FADE) end
			end
			if not whitened and age >= dur * 0.6 then
				whitened = true
				paint(Color3.new(1, 1, 1), Enum.Material.Neon)
				hl.OutlineColor = Color3.new(1, 1, 1)
				pcall(function() cube.emitter:Emit(30) end)
			end
			if not faded and age >= dur * 0.85 then
				faded = true
				for d in pairs(rec.parts) do
					if d:IsA("BasePart") then TweenService:Create(d, TweenInfo.new(0.7), { Transparency = 1 }):Play() end
				end
			end
			task.wait()
		end

		for d in pairs(rec.parts) do
			if d.Parent and (d:IsA("BasePart") or d:IsA("Decal")) then pcall(function() d.Transparency = 1 end) end
		end
		pcall(function() hl:Destroy() end)
		pcall(function() cube.emitter:Emit(20) end)
		cube.done = true
		worldOff()
		if music then pcall(function() music:Stop() music:Destroy() end) end
		S.seq = math.max(0, S.seq - 1)
		applyBattleVolume()
		pending[target] = nil
		if affected[target] then affected[target].since = os.clock() end
		if finished then finished(target) end
	end

	-- ===== rig =====
	local function hidePart(d)
		if (d:IsA("BasePart") or d:IsA("Decal")) and hidden[d] == nil then
			hidden[d] = d.Transparency
			d.Transparency = 1
		end
	end

	local function bottomY(p)
		local cf, s = p.CFrame, p.Size / 2
		local hy = math.abs(cf.RightVector.Y) * s.X + math.abs(cf.UpVector.Y) * s.Y + math.abs(cf.LookVector.Y) * s.Z
		return cf.Position.Y - hy
	end

	local function destroyRig()
		if rig then pcall(function() rig:Destroy() end) end
		rig, rigRoot = nil, nil
		table.clear(bones)
	end

	local function makeRig(src)
		destroyRig()
		local r = src:Clone()
		r.Name = "AnimaticSlopCode"
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("Humanoid") or d:IsA("Animator") or d:IsA("AnimationController") or d:IsA("BaseScript")
				or d:IsA("BodyColors") or d:IsA("ObjectValue") or d:IsA("CFrameValue") then
				pcall(function() d:Destroy() end)
			end
		end
		local hrp = r:FindFirstChild("HumanoidRootPart")
		if not hrp then
			r:Destroy()
			return false, "model has no HumanoidRootPart"
		end

		-- front of the model (where the Eyes are) -> -Z
		local eyes = r:FindFirstChild("Eyes", true)
		frontYaw = 0
		if eyes and eyes:IsA("BasePart") then
			local d = hrp.CFrame:VectorToObjectSpace(eyes.Position - hrp.Position)
			if math.abs(d.X) + math.abs(d.Z) > 0.01 then frontYaw = math.atan2(d.X, -d.Z) end
		end

		-- ground distance from the visible parts
		local low = math.huge
		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("BasePart") and d.Transparency < 1 then low = math.min(low, bottomY(d)) end
		end
		if low == math.huge then low = hrp.Position.Y - 3 end
		rigGround = hrp.Position.Y - low
		offY = rigGround - realGround + LIFT

		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CanCollide, d.CanQuery, d.CanTouch, d.Massless = false, false, false, true
				d.CastShadow = false
				d.Anchored = (d == hrp)
			end
		end
		r.PrimaryPart = hrp
		r.Parent = workspace
		rig, rigRoot = r, hrp

		for _, d in ipairs(r:GetDescendants()) do
			if d:IsA("Bone") and not bones[d.Name] then bones[d.Name] = d end
		end
		hrp.CFrame = root.CFrame * CFrame.new(0, offY, 0)
		S.yaw = nil
		return true
	end

	-- ===== ability panel (the three buttons of the original Animatic script) =====
	local gui
	local buttons = {}

	local function guiParent()
		if typeof(gethui) == "function" then
			local ok, h = pcall(gethui)
			if ok and h then return h end
		end
		local ok, cg = pcall(function() return game:GetService("CoreGui") end)
		if ok and cg then return cg end
		return plr:WaitForChild("PlayerGui")
	end

	local function refreshPanel()
		if buttons.ext then buttons.ext.Text = S.ext and "Stop Extermination" or "Start Extermination" end
		if buttons.ann then buttons.ann.Text = S.ann and "Stop Annihilation" or "Start Annihilation" end
		if buttons.rec then buttons.rec.Text = S.rec and "Stop Recovery" or "Start Recovery" end
		if buttons.bat then buttons.bat.Text = S.battle and "Battle Theme: ON" or "Battle Theme: OFF" end
	end

	local clickConn
	local function setClickHandler()
		if clickConn then clickConn:Disconnect() clickConn = nil end
		if not (S.ext or S.ann) then
			pcall(function() mouse.Icon = "" end)
			return
		end
		pcall(function() mouse.Icon = S.ext and "rbxassetid://122236413215702" or "" end)
		clickConn = mouse.Button1Down:Connect(function()
			if S.busy then return end
			local target = characterOf(mouse.Target)
			if not target or target == char or target == rig or affected[target] or pending[target] then return end
			S.busy = true
			local ext = S.ext
			pending[target] = true
			if ext then pcall(function() mouse.Icon = "rbxassetid://77332203654588" end) end
			local function after(t)
				if S.rec and affected[t] then
					task.delay(RECOVER_AFTER, function() restore(t) end)
				end
			end
			task.spawn(function()
				if ext then
					spawnCube("cube", target, function(t, cube)
						runExtermination(t, after, cube)
					end, { sequence = true })
				else
					spawnCube("star", target, function(t)
						pending[t] = nil
						annihilate(t)
						after(t)
					end)
				end
			end)
			task.wait(CLICK_COOLDOWN)
			S.busy = false
			if S.ext then pcall(function() mouse.Icon = "rbxassetid://122236413215702" end) end
		end)
	end

	local function toggleExt()
		S.ext = not S.ext
		S.ann = false
		if not S.ext then stopChaseTheme(0.6) end
		playOnce(S.ext and "exterminateenable" or "exterminatedisable", 0.5)
		refreshPanel()
		setClickHandler()
		updateTheme()
	end

	local function toggleAnn()
		S.ann = not S.ann
		S.ext = false
		stopChaseTheme(0.6)
		playOnce(S.ann and "exterminateenable" or "exterminatedisable", 0.5)
		refreshPanel()
		setClickHandler()
		updateTheme()
	end

	local function toggleBattle()
		S.battle = not S.battle
		refreshPanel()
		updateTheme()
	end

	local function toggleRec()
		S.rec = not S.rec
		playOnce(S.rec and "exterminateenable" or "exterminatedisable", 0.5)
		if S.rec then
			local n = restoreAll()
			if n > 0 then notify("SlopCode Animatic", "Recovered " .. n .. " character(s)") end
		end
		refreshPanel()
	end

	local function buildPanel()
		gui = Instance.new("ScreenGui")
		gui.Name = "SlopCodeAnimaticPanel"
		gui.ResetOnSpawn = false
		pcall(function() if syn and syn.protect_gui then syn.protect_gui(gui) end end)
		gui.Parent = guiParent()

		local frame = Instance.new("Frame")
		frame.BackgroundTransparency = 1
		frame.Position = UDim2.new(0, 12, 0.5, -100)
		frame.Size = UDim2.new(0, 190, 0, 200)
		frame.Parent = gui
		local layout = Instance.new("UIListLayout")
		layout.Padding = UDim.new(0, 8)
		layout.Parent = frame

		local function mk(key, fn)
			local b = Instance.new("TextButton")
			b.Size = UDim2.new(1, 0, 0, 40)
			b.BackgroundColor3 = Color3.fromRGB(35, 12, 55)
			b.TextColor3 = Color3.fromRGB(240, 220, 255)
			b.Font = Enum.Font.GothamBold
			b.TextSize = 14
			b.AutoButtonColor = true
			b.Parent = frame
			Instance.new("UICorner", b).CornerRadius = UDim.new(0, 8)
			local st = Instance.new("UIStroke", b)
			st.Color = Color3.fromRGB(150, 70, 255)
			st.Thickness = 2
			local gr = Instance.new("UIGradient", b)
			gr.Color = ColorSequence.new(Color3.fromRGB(70, 25, 110), Color3.fromRGB(25, 8, 40))
			gr.Rotation = 90
			buttons[key] = b
			table.insert(conns, b.MouseButton1Click:Connect(fn))
		end
		mk("ext", toggleExt)
		mk("ann", toggleAnn)
		mk("rec", toggleRec)
		mk("bat", toggleBattle)

		local tag = Instance.new("TextLabel")
		tag.BackgroundTransparency = 1
		tag.Size = UDim2.new(1, 0, 0, 16)
		tag.Font = Enum.Font.Gotham
		tag.TextSize = 11
		tag.TextColor3 = Color3.fromRGB(170, 140, 235)
		tag.Text = "SlopCode Animatic  [SlopCode]"
		tag.Parent = frame
		refreshPanel()
	end

	local function bind(name, kc, fn)
		local ok = pcall(function()
			ContextActions:BindAction(name, function(_, state)
				if state == Enum.UserInputState.Begin then fn() end
				return Enum.ContextActionResult.Pass
			end, false, kc)
		end)
		if not ok then
			table.insert(conns, UserInputService.InputBegan:Connect(function(i, gp)
				if not gp and i.KeyCode == kc then fn() end
			end))
		end
	end

	-- ===== lifecycle =====
	function m.Init()
		char = plr.Character or plr.CharacterAdded:Wait()
		hum = char:WaitForChild("Humanoid")
		root = char:WaitForChild("HumanoidRootPart")
		S.rot0 = hum.AutoRotate
		S.running = true

		-- walk speed
		if WALKSPEED then
			if not S.origWalk then S.origWalk = hum.WalkSpeed end
			hum.WalkSpeed = WALKSPEED
			table.insert(conns, hum:GetPropertyChangedSignal("WalkSpeed"):Connect(function()
				if S.running and hum.WalkSpeed ~= WALKSPEED then hum.WalkSpeed = WALKSPEED end
			end))
		end

		if not OBJ.model then
			local objs, err = loadFile("model")
			if not objs then
				warn("[SlopCode Animatic] " .. tostring(err))
				notify("Animatic model not loaded", err)
				return
			end
			OBJ.model = objs
		end
		if not next(anims) then
			for _, key in ipairs({ "idle", "walk", "chase", "jump" }) do
				local a, err = loadAnim(key)
				if a then
					anims[key] = a
				else
					warn("[SlopCode Animatic] animation '" .. key .. "': " .. tostring(err))
				end
			end
			if not anims.idle then notify("SlopCode Animatic", "The idle animation could not be loaded - the model will stay in its rest pose.") end
		end

		-- root -> ground distance of the real character, so the rig's feet land on the floor
		if hum.RigType == Enum.HumanoidRigType.R15 then
			realGround = root.Size.Y / 2 + hum.HipHeight
		else
			local leg = char:FindFirstChild("Left Leg")
			realGround = root.Size.Y / 2 + (leg and leg.Size.Y or 2) + hum.HipHeight
		end

		local model
		for _, o in ipairs(OBJ.model) do
			if o:IsA("Model") and o.Name == MODELNAME then model = o break end
			local d = o:FindFirstChild(MODELNAME, true)
			if d and d:IsA("Model") then model = d break end
		end
		model = model or OBJ.model[1]
		S.cur = nil
		table.clear(lastPose); table.clear(snapPose)
		local pok, ok, err2 = pcall(makeRig, model)
		if not (pok and ok) then
			local msg = pok and tostring(err2) or tostring(ok)
			warn("[SlopCode Animatic] rig failed: " .. msg)
			notify("Animatic rig failed", msg)
			return
		end

		-- hide the real character (local only)
		S.ddt = hum.DisplayDistanceType
		hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
		for _, d in ipairs(char:GetDescendants()) do hidePart(d) end
		table.insert(conns, char.DescendantAdded:Connect(hidePart))

		buildPanel()
		bind("animaticQ", Enum.KeyCode.Q, toggleExt)
		bind("animaticE", Enum.KeyCode.E, toggleAnn)
		bind("animaticR", Enum.KeyCode.R, toggleRec)
		bind("animaticT", Enum.KeyCode.T, toggleBattle)
		updateTheme()
	end

	function m.Update(dt)
		if not (rig and rig.Parent and rigRoot and root and root.Parent and hum) then return end
		dt = math.min(dt, 0.1)

		local vel = root.AssemblyLinearVelocity
		local speed = Vector3.new(vel.X, 0, vel.Z).Magnitude
		local air = hum.FloorMaterial == Enum.Material.Air

		-- pick the animation
		local name, t = "idle", 0
		if air and anims.jump then
			name = "jump"
			t = 0
		elseif speed > CHASESPEED and anims.chase then
			name = "chase"
			t = clockOf("chase", math.clamp(speed / 20, 0.7, 2.6), dt)
		elseif speed > 1 and anims.walk then
			name = "walk"
			t = clockOf("walk", math.clamp(speed / 10, 0.6, 1.6), dt)
		elseif anims.idle then
			t = clockOf("idle", 1, dt)
		end
		local a = anims[name]

		-- the bones: the pose is applied exactly as sampled (no per-bone smoothing, that distorts the skinned mesh);
		-- when the animation changes the old pose is cross-faded into the new one
		local now = os.clock()
		if S.cur ~= name then
			S.cur = name
			S.switchT = now
			snapPose = lastPose
			lastPose = {}
		end
		local blend = math.clamp((now - S.switchT) / BLEND, 0, 1)
		for bname, bone in pairs(bones) do
			local target = ID
			if a then
				local tr = a.tracks[bname]
				if tr then target = sampleTrack(tr, t) end
			end
			local val = target
			if blend < 1 then
				local from = snapPose[bname]
				if from then val = from:Lerp(target, blend) end
			end
			lastPose[bname] = val
			bone.Transform = val
		end

		-- the gyroscope: the model turns toward where it is moving, damped like the Robot 64 BodyGyro
		local look = root.CFrame.LookVector
		local heading = math.atan2(-look.X, -look.Z)
		if speed > 2 then heading = math.atan2(-vel.X, -vel.Z) end
		if not S.yaw then S.yaw = heading end
		local diff = (heading - S.yaw + math.pi) % (math.pi * 2) - math.pi
		S.yaw += diff * (1 - math.exp(-dt / GYRO_TAU))

		rigRoot.CFrame = CFrame.new(root.Position + Vector3.new(0, offY, 0)) * CFrame.Angles(0, S.yaw + frontYaw, 0)

		updateWorld(dt)
		updateCubes(dt)

		-- Recovery mode keeps bringing victims back
		if S.rec then
			local now = os.clock()
			for target, rec in pairs(affected) do
				if now - rec.since >= RECOVER_AFTER and not pending[target] then restore(target) end
			end
		end
	end

	function m.Destroy()
		S.running = false
		worldOff(true)
		if hum then
			if WALKSPEED and S.origWalk then hum.WalkSpeed = S.origWalk end
			hum.AutoRotate = S.rot0
			if S.ddt then hum.DisplayDistanceType = S.ddt end
		end
		if clickConn then clickConn:Disconnect() clickConn = nil end
		pcall(function() mouse.Icon = "" end)
		for _, c in ipairs(conns) do c:Disconnect() end
		for _, n in ipairs({ "animaticQ", "animaticE", "animaticR", "animaticT" }) do
			pcall(function() ContextActions:UnbindAction(n) end)
		end
		for inst, tr in pairs(hidden) do
			pcall(function() inst.Transparency = tr end)
		end
		restoreAll()
		S.ext, S.ann, S.rec = false, false, false
		if theme then pcall(function() theme:Stop() theme:Destroy() end) theme = nil end
		if battle then pcall(function() battle:Stop() battle:Destroy() end) battle = nil end
		if chaseMusic then pcall(function() chaseMusic:Stop() chaseMusic:Destroy() end) chaseMusic = nil end
		S.seq = 0
		if gui then pcall(function() gui:Destroy() end) gui = nil end
		table.clear(buttons)
		table.clear(cubes); table.clear(pending)
		if fxFolder then pcall(function() fxFolder:Destroy() end) fxFolder = nil end
		destroyRig()
		table.clear(conns); table.clear(hidden)
	end

	return m
end

-- ===== run =====
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local env = (typeof(getgenv) == "function" and getgenv()) or _G

if env.ANIMATICSTOP then pcall(env.ANIMATICSTOP) end

local inst = build()
task.spawn(inst.Init)

local rs = RunService.RenderStepped:Connect(function(dt)
	inst.Update(dt)
end)
local respawn = Players.LocalPlayer.CharacterAdded:Connect(function()
	task.wait(1)
	inst.Destroy()
	task.spawn(inst.Init)
end)

env.ANIMATICSTOP = function()
	rs:Disconnect()
	respawn:Disconnect()
	inst.Destroy()
	env.ANIMATICSTOP = nil
end
