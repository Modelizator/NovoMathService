local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MathService = {}

local function logMessage(kind, text)
	if not script:GetAttribute("Debugging") then return end
	local ts = os.date("%H:%M:%S")
	local w = 60
	local frame, writer, tag = {tl="-", tr="¬", bl="L", br="-", h="-", v="¦", ml="+", mr="+"}, print, "[OUT]"
	if kind == "Warning" then
		writer, tag = warn, "[WARNING]"
		frame = {tl="?", tr="?", bl="?", br="?", h="?", v="?", ml="?", mr="?"}
	elseif kind == "Error" then
		writer, tag = warn, "[ERROR]"
		frame = {tl="ã", tr="¬", bl="L", br="-", h="=", v="¦", ml="¦", mr="¦"}
	end
	local top = frame.tl .. string.rep(frame.h, w + 2) .. frame.tr
	local head = string.format("%s %s", tag, script.Name)
	local pad = w - #head - #ts - 1
	if pad < 0 then pad = 0 end
	local header = string.format("%s %s%s %s %s", frame.v, head, string.rep(" ", pad), ts, frame.v)
	local mid = frame.ml .. string.rep(frame.h, w + 2) .. frame.mr
	local body = " -> " .. text
	if #body > w then body = body:sub(1, w - 3) .. "..." end
	local bpad = w - #body + 1
	if bpad < 0 then bpad = 0 end
	local line = string.format("%s %s%s %s", frame.v, body, string.rep(" ", bpad), frame.v)
	local bot = frame.bl .. string.rep(frame.h, w + 2) .. frame.br
	writer(table.concat({"\n", top, header, mid, line, bot, "\n"}, "\n"))
end

local Debug = {}
MathService.Debug = Debug
function Debug.Enable() script:SetAttribute("Debugging", true) end
function Debug.Disable() script:SetAttribute("Debugging", false) end
function Debug.IsEnabled() return script:GetAttribute("Debugging") == true end
function Debug.Log(text) logMessage("Info", text) end
function Debug.Warn(text) logMessage("Warning", text) end
function Debug.Error(text) logMessage("Error", text) end
function Debug.Dump()
	local names = MathService.List()
	print(("-- Registered commands (%d) --"):format(#names))
	for i, n in ipairs(names) do print(("  %2d. %s"):format(i, n)) end
end

local function matchesType(v, typeStr)
	for t in string.gmatch(typeStr, "([^|]+)") do
		if typeof(v) == t:match("^%s*(.-)%s*$") then return true end
	end
	return false
end

local function checkRange(v, r)
	return type(v) == "number"
		and (not r[1] or v >= r[1])
		and (not r[2] or v <= r[2])
end

local function validateParams(params, spec)
	for name, rule in pairs(spec) do
		local v = params[name]
		if v == nil then
			if type(rule) == "table" and rule.required then
				return false, ("param '%s' is required"):format(name)
			end
		else
			local et, range
			if type(rule) == "string" then et = rule
			else et, range = rule.type, rule.range end
			if et and not matchesType(v, et) then
				return false, ("param '%s': expected %s, got %s"):format(name, et, typeof(v))
			end
			if range and not checkRange(v, range) then
				return false, ("param '%s': out of range"):format(name)
			end
		end
	end
	return true
end

local Registry = {}

function MathService.Register(name, spec, fn)
	assert(type(name) == "string" and type(fn) == "function")
	Registry[name] = { spec = spec, fn = fn }
end

function MathService.Unregister(n) Registry[n] = nil end
function MathService.Has(n) return Registry[n] ~= nil end

function MathService.List()
	local ns = {}
	for n in pairs(Registry) do table.insert(ns, n) end
	table.sort(ns)
	return ns
end

function MathService.Run(name, params)
	params = params or {}
	local cmd = Registry[name]
	if not cmd then
		local msg = ("unknown command: '%s'"):format(name)
		logMessage("Warning", msg)
		return nil, msg
	end
	if cmd.spec then
		local ok, err = validateParams(params, cmd.spec)
		if not ok then
			local msg = ("[%s] %s"):format(name, err)
			logMessage("Warning", msg)
			return nil, msg
		end
	end
	return cmd.fn(params)
end

function MathService.RunBatch(list)
	local out = {}
	for i, item in ipairs(list) do
		local packed = table.pack(MathService.Run(item.cmd or item.name, item.params))
		if packed[1] == nil and type(packed[2]) == "string" then
			return nil, ("batch %d: %s"):format(i, packed[2])
		end
		out[i] = (packed.n == 1) and packed[1] or packed
	end
	return out
end

local CmdClass = {}
CmdClass.__index = CmdClass
function CmdClass:with(t) for k, v in pairs(t) do self.params[k] = v end return self end
function CmdClass:set(k, v) self.params[k] = v return self end
function CmdClass:run() return MathService.Run(self.name, self.params) end
function MathService.Cmd(n) return setmetatable({ name = n, params = {} }, CmdClass) end

local function magnitude(x)
	return type(x) == "number" and math.abs(x) or x.Magnitude
end

local Angle = {}
MathService.Angle = Angle
function Angle.Normalize(r)
	local x = r % (2*math.pi)
	if x > math.pi then x = x - 2*math.pi end
	return x
end
function Angle.Delta(a, b) return Angle.Normalize(b - a) end
function Angle.RotateTowards(cur, tgt, maxA)
	local d = Angle.Delta(cur, tgt)
	if math.abs(d) <= maxA then return tgt end
	return cur + math.sign(d) * maxA
end

local Lerp = {}
MathService.Lerp = Lerp
function Lerp.Number(a, b, t) return a + (b - a) * t end
function Lerp.Vector(a, b, t) return a:Lerp(b, t) end
function Lerp.CFrame(a, b, t) return a:Lerp(b, t) end
function Lerp.Angle(a, b, t) return a + Angle.Delta(a, b) * t end
function MathService.LerpAngle(a, b, t) return Lerp.Angle(a, b, t) end

local Bezier = {}
MathService.Bezier = Bezier
function Bezier.Quadratic(t, p0, p1, p2)
	local u = 1 - t
	return u*u*p0 + 2*u*t*p1 + t*t*p2
end
function Bezier.Cubic(t, p0, p1, p2, p3)
	local u = 1 - t
	return u*u*u*p0 + 3*u*u*t*p1 + 3*u*t*t*p2 + t*t*t*p3
end
function Bezier.QuadraticDerivative(t, p0, p1, p2)
	return 2*(1 - t)*(p1 - p0) + 2*t*(p2 - p1)
end
function Bezier.CubicDerivative(t, p0, p1, p2, p3)
	local u = 1 - t
	return 3*u*u*(p1 - p0) + 6*u*t*(p2 - p1) + 3*t*t*(p3 - p2)
end
function Bezier.QuadraticCFrame(t, c0, c1, c2)
	local u = 1 - t
	local p = u*u*c0.Position + 2*u*t*c1.Position + t*t*c2.Position
	return CFrame.new(p) * (c0 - c0.Position):Lerp(c2 - c2.Position, t)
end
function Bezier.CubicCFrame(t, c0, c1, c2, c3)
	local u = 1 - t
	local p = u*u*u*c0.Position + 3*u*u*t*c1.Position
		+ 3*u*t*t*c2.Position + t*t*t*c3.Position
	return CFrame.new(p) * (c0 - c0.Position):Lerp(c3 - c3.Position, t)
end
function Bezier.CubicLookAt(t, p0, p1, p2, p3)
	local p = Bezier.Cubic(t, p0, p1, p2, p3)
	local tan = Bezier.CubicDerivative(t, p0, p1, p2, p3)
	if tan.Magnitude < 1e-6 then return CFrame.new(p) end
	return CFrame.lookAt(p, p + tan.Unit)
end

local Path = {}
Path.__index = Path

function Bezier.CompilePath(curveFn, points, samples)
	samples = samples or 200
	local s, total = {}, 0
	local prev = curveFn(0, table.unpack(points))
	s[1] = { t = 0, dist = 0 }
	for i = 1, samples do
		local t = i / samples
		local pos = curveFn(t, table.unpack(points))
		total += (pos - prev).Magnitude
		s[i + 1] = { t = t, dist = total }
		prev = pos
	end
	local p = setmetatable({
		curveFn = curveFn, points = points,
		samples = s, length = total,
	}, Path)
	logMessage("Info", ("Bezier.CompilePath: %d samples, length=%.2f"):format(samples, total))
	return p
end

function Path:AtDistance(d)
	d = math.clamp(d, 0, self.length)
	local lo, hi = 1, #self.samples
	while lo < hi do
		local mid = (lo + hi) // 2
		if self.samples[mid].dist < d then lo = mid + 1 else hi = mid end
	end
	if lo == 1 then return self.curveFn(0, table.unpack(self.points)) end
	local a, b = self.samples[lo - 1], self.samples[lo]
	local seg = b.dist - a.dist
	local lt = seg > 0 and (d - a.dist) / seg or 0
	local t = a.t + (b.t - a.t) * lt
	return self.curveFn(t, table.unpack(self.points))
end
function Path:AtPercent(p) return self:AtDistance(p * self.length) end
function Path:AtTime(e, dur) return self:AtPercent(math.clamp(e / dur, 0, 1)) end

local Easing = {}
MathService.Easing = Easing
Easing.linear    = function(t) return t end
Easing.quadIn    = function(t) return t*t end
Easing.quadOut   = function(t) return 1 - (1-t)*(1-t) end
Easing.quadInOut = function(t) return t < 0.5 and 2*t*t or 1 - (-2*t+2)^2/2 end
Easing.cubicIn   = function(t) return t*t*t end
Easing.cubicOut  = function(t) return 1 - (1-t)^3 end
Easing.cubicInOut= function(t) return t < 0.5 and 4*t*t*t or 1 - (-2*t+2)^3/2 end
Easing.quartIn   = function(t) return t^4 end
Easing.quartOut  = function(t) return 1 - (1-t)^4 end
Easing.quintIn   = function(t) return t^5 end
Easing.quintOut  = function(t) return 1 - (1-t)^5 end
Easing.sineIn    = function(t) return 1 - math.cos(t*math.pi/2) end
Easing.sineOut   = function(t) return math.sin(t*math.pi/2) end
Easing.sineInOut = function(t) return -(math.cos(math.pi*t) - 1)/2 end
Easing.expoIn    = function(t) return t == 0 and 0 or 2^(10*t - 10) end
Easing.expoOut   = function(t) return t == 1 and 1 or 1 - 2^(-10*t) end
Easing.expoInOut = function(t)
	if t == 0 then return 0 end
	if t == 1 then return 1 end
	return t < 0.5 and 2^(20*t - 10)/2 or (2 - 2^(-20*t + 10))/2
end
Easing.circIn    = function(t) return 1 - math.sqrt(1 - t*t) end
Easing.circOut   = function(t) return math.sqrt(1 - (t-1)^2) end
local c1, c3 = 1.70158, 2.70158
Easing.backIn    = function(t) return c3*t^3 - c1*t^2 end
Easing.backOut   = function(t) local u = t-1 return 1 + c3*u^3 + c1*u^2 end
Easing.backInOut = function(t)
	local c2 = c1 * 1.525
	if t < 0.5 then local u = 2*t return u*u*((c2+1)*u - c2)/2 end
	local u = 2*t - 2 return (u*u*((c2+1)*u + c2) + 2)/2
end
Easing.elasticOut = function(t)
	if t == 0 or t == 1 then return t end
	local c4 = 2*math.pi/3
	return 2^(-10*t) * math.sin((t*10 - 0.75) * c4) + 1
end
Easing.elasticIn = function(t)
	if t == 0 or t == 1 then return t end
	local c4 = 2*math.pi/3
	return -2^(10*t - 10) * math.sin((t*10 - 10.75) * c4)
end
Easing.bounceOut = function(t)
	local n, d = 7.5625, 2.75
	if t < 1/d then return n*t*t end
	if t < 2/d then local u = t - 1.5/d return n*u*u + 0.75 end
	if t < 2.5/d then local u = t - 2.25/d return n*u*u + 0.9375 end
	local u = t - 2.625/d return n*u*u + 0.984375
end
Easing.bounceIn = function(t) return 1 - Easing.bounceOut(1 - t) end

for en, fn in pairs(Easing) do
	local f = fn
	MathService.Register("ease." .. en,
		{ t = {type="number", required=true, range={0,1}} },
		function(p) return f(p.t) end)
end

local Noise = {}
MathService.Noise = Noise
function Noise.Perlin1D(x, seed)
	seed = seed or 0
	return math.noise(x + seed * 100.31, seed * 100.31)
end
function Noise.Perlin2D(x, y, seed)
	seed = seed or 0
	return math.noise(x + seed * 100.31, y + seed * 100.31)
end
function Noise.Perlin3D(x, y, z, seed)
	seed = seed or 0
	return math.noise(x + seed * 100.31, y + seed * 100.31, z + seed * 100.31)
end
function Noise.Fractal1D(x, o, p, l, seed)
	o, p, l = o or 4, p or 0.5, l or 2
	local t, f, a, m = 0, 1, 1, 0
	for i = 1, o do
		t += Noise.Perlin1D(x * f, (seed or 0) + i * 17.31) * a
		m += a; a *= p; f *= l
	end
	return t / m
end
function Noise.Fractal2D(x, y, o, p, l, seed)
	o, p, l = o or 4, p or 0.5, l or 2
	local t, f, a, m = 0, 1, 1, 0
	for i = 1, o do
		t += Noise.Perlin2D(x * f, y * f, (seed or 0) + i * 17.31) * a
		m += a; a *= p; f *= l
	end
	return t / m
end

function MathService.SmoothDamp(cur, tgt, vel, st, ms, dt)
	return TweenService:SmoothDamp(cur, tgt, vel, st, ms or math.huge, dt)
end

function MathService.Spring(cur, tgt, vel, k, d, dt)
	local ms = 1/240
	local n = math.max(1, math.ceil(dt / ms))
	local h = dt / n
	for _ = 1, n do
		local force = -k * (cur - tgt) - d * vel
		vel = vel + force * h
		cur = cur + vel * h
	end
	return cur, vel
end
function MathService.SpringSettled(cur, tgt, vel, pt, vt)
	return magnitude(cur - tgt) < (pt or 1e-3)
		and magnitude(vel) < (vt or 1e-3)
end

local SpringObject = {}
SpringObject.__index = SpringObject
MathService.SpringObject = SpringObject

function SpringObject.new(o)
	o = o or {}
	local v = o.value or 0
	local vel = o.velocity
	if vel == nil then vel = (type(v) == "number") and 0 or v * 0 end
	local self = setmetatable({
		value = v, target = o.target or v, velocity = vel,
		stiffness = o.stiffness or 150, damping = o.damping or 10,
	}, SpringObject)
	logMessage("Info", ("SpringObject.new: value=%s, target=%s, k=%.1f, d=%.1f")
		:format(tostring(self.value), tostring(self.target), self.stiffness, self.damping))
	return self
end
function SpringObject:SetTarget(v) self.target = v return self end
function SpringObject:Step(dt)
	self.value, self.velocity = MathService.Spring(
		self.value, self.target, self.velocity,
		self.stiffness, self.damping, dt)
	return self.value
end
function SpringObject:Settled()
	return MathService.SpringSettled(self.value, self.target, self.velocity)
end

local Utility = {}
MathService.Utility = Utility
function Utility.Clamp(v, lo, hi) return math.clamp(v, lo, hi) end
function Utility.InverseLerp(a, b, v) return a == b and 0 or (v - a)/(b - a) end
function Utility.Remap(v, imin, imax, omin, omax)
	return omin + (omax - omin) * Utility.InverseLerp(imin, imax, v)
end
function Utility.Smoothstep(t) t = math.clamp(t, 0, 1) return t*t*(3 - 2*t) end
function Utility.Smootherstep(t) t = math.clamp(t, 0, 1) return t^3*(t*(t*6 - 15) + 10) end
function Utility.Approach(cur, tgt, md)
	if type(cur) == "number" then
		if math.abs(tgt - cur) <= md then return tgt end
		return cur + math.sign(tgt - cur) * md
	else
		local d = tgt - cur
		local dist = d.Magnitude
		if dist <= md or dist < 1e-9 then return tgt end
		return cur + d.Unit * md
	end
end
function Utility.PingPong(t, len)
	t = t % (len * 2)
	return len - math.abs(t - len)
end

local Vector = {}
MathService.Vector = Vector
function Vector.ProjectOnLine(p, a, b)
	local ab = b - a
	local dn = ab:Dot(ab)
	if dn < 1e-12 then return a end
	return a + ab * ((p - a):Dot(ab) / dn)
end
function Vector.ProjectOnSegment(p, a, b)
	local ab = b - a
	local dn = ab:Dot(ab)
	if dn < 1e-12 then return a end
	local t = math.clamp((p - a):Dot(ab) / dn, 0, 1)
	return a + ab * t
end
function Vector.DistanceToLine(p, a, b) return (p - Vector.ProjectOnLine(p, a, b)).Magnitude end
function Vector.DistanceToSegment(p, a, b) return (p - Vector.ProjectOnSegment(p, a, b)).Magnitude end
function Vector.Reflect(inc, n) return inc - 2 * inc:Dot(n) * n end
function Vector.MoveTowards(c, t, md) return Utility.Approach(c, t, md) end

local Spline = {}
MathService.Spline = Spline
function Spline.CatmullRom(t, p0, p1, p2, p3)
	local t2, t3 = t*t, t*t*t
	return 0.5 * (2*p1 + (-p0 + p2)*t + (2*p0 - 5*p1 + 4*p2 - p3)*t2
		+ (-p0 + 3*p1 - 3*p2 + p3)*t3)
end
function Spline.CatmullRomChain(t, pts)
	local n = #pts
	if n == 0 then return nil end
	if n == 1 then return pts[1] end
	local sc = n - 1
	local scaled = math.clamp(t, 0, 1) * sc
	local seg = math.min(math.floor(scaled), sc - 1)
	local lt = scaled - seg
	return Spline.CatmullRom(lt,
		pts[math.max(seg, 1)], pts[seg + 1], pts[seg + 2],
		pts[math.min(seg + 3, n)])
end
function Spline.Hermite(t, p0, p1, m0, m1)
	local t2, t3 = t*t, t*t*t
	return (2*t3 - 3*t2 + 1)*p0 + (t3 - 2*t2 + t)*m0
		+ (-2*t3 + 3*t2)*p1 + (t3 - t2)*m1
end
local function bs(i, t)
	local t2, t3 = t*t, t*t*t
	if i == 0 then return (1 - t)^3 / 6 end
	if i == 1 then return (3*t3 - 6*t2 + 4) / 6 end
	if i == 2 then return (-3*t3 + 3*t2 + 3*t + 1) / 6 end
	return t3 / 6
end
function Spline.BSpline(t, p0, p1, p2, p3)
	return p0*bs(0, t) + p1*bs(1, t) + p2*bs(2, t) + p3*bs(3, t)
end
function Spline.FrenetFrame(curveFn, t, ...)
	local eps = 0.001
	local a = curveFn(math.max(0, t - eps), ...)
	local b = curveFn(t, ...)
	local c = curveFn(math.min(1, t + eps), ...)
	local tan = c - a
	if tan.Magnitude < 1e-6 then return CFrame.new(b) end
	tan = tan.Unit
	local right = tan:Cross(Vector3.yAxis)
	if right.Magnitude < 1e-4 then right = tan:Cross(Vector3.xAxis) end
	right = right.Unit
	local up = right:Cross(tan).Unit
	return CFrame.fromMatrix(b, right, up, -tan)
end

local Ballistics = {}
MathService.Ballistics = Ballistics
function Ballistics.Position(s, v, g, t) return s + v*t + 0.5*g*t*t end
function Ballistics.SolveAngle(s, tgt, speed, g)
	local gM = g.Magnitude
	if gM < 1e-6 then return nil end
	local d = tgt - s
	local x = Vector3.new(d.X, 0, d.Z).Magnitude
	local y = d.Y
	local v2 = speed*speed
	local v4 = v2*v2
	local disc = v4 - gM*(gM*x*x + 2*y*v2)
	if disc < 0 then return nil end
	local sq = math.sqrt(disc)
	return math.atan((v2 - sq)/(gM*x)), math.atan((v2 + sq)/(gM*x))
end
function Ballistics.TimeToHit(s, tgt, speed, g, high)
	local low, highA = Ballistics.SolveAngle(s, tgt, speed, g)
	local a = (high and highA) or low
	if not a then return nil end
	local x = Vector3.new(tgt.X - s.X, 0, tgt.Z - s.Z).Magnitude
	return x / (speed * math.cos(a))
end
function Ballistics.VelocityToHit(s, tgt, speed, g, high)
	local low, highA = Ballistics.SolveAngle(s, tgt, speed, g)
	local a = (high and highA) or low
	if not a then
		logMessage("Warning", "Ballistics: no solution for given speed/gravity")
		return nil
	end
	local d = tgt - s
	local flat = Vector3.new(d.X, 0, d.Z)
	flat = flat.Magnitude < 1e-6 and Vector3.xAxis or flat.Unit
	return flat * (speed * math.cos(a)) + Vector3.yAxis * (speed * math.sin(a))
end

local IK = {}
MathService.IK = IK
function IK.Solve2Bone(root, tgt, ul, ll, pole)
	local d = tgt - root
	local dist = math.max(d.Magnitude, 1e-6)
	local maxR = ul + ll - 1e-4
	local minR = math.abs(ul - ll) + 1e-4
	dist = math.clamp(dist, minR, maxR)
	local dir = d.Magnitude < 1e-6 and Vector3.xAxis or d.Unit
	local ca = (ul*ul + dist*dist - ll*ll) / (2*ul*dist)
	local ang = math.acos(math.clamp(ca, -1, 1))
	local p = pole - dir * pole:Dot(dir)
	if p.Magnitude < 1e-6 then
		p = dir:Cross(Vector3.yAxis)
		if p.Magnitude < 1e-6 then p = dir:Cross(Vector3.xAxis) end
	end
	p = p.Unit
	return root + dir*(ul*math.cos(ang)) + p*(ul*math.sin(ang))
end
function IK.Solve2BoneCFrames(root, tgt, ul, ll, pole)
	local j = IK.Solve2Bone(root, tgt, ul, ll, pole)
	return CFrame.lookAt((root + j)*0.5, j),
		CFrame.lookAt((j + tgt)*0.5, tgt), j
end

local SpringChain = {}
SpringChain.__index = SpringChain
MathService.SpringChain = SpringChain

function SpringChain.new(o)
	o = o or {}
	local n = o.points or 10
	local root = o.rootCFrame or CFrame.new()
	local sp = o.spacing or 1
	local segs = {}
	for i = 1, n do
		segs[i] = {
			pos = root.Position - root.LookVector * sp * (i - 1),
			vel = Vector3.zero,
		}
	end
	local self = setmetatable({
		segments = segs, rootCFrame = root, spacing = sp,
		stiffness = o.stiffness or 150,
		damping = o.damping or 10,
		gravity = o.gravity or Vector3.new(0, -20, 0),
	}, SpringChain)
	logMessage("Info", ("SpringChain.new: points=%d, spacing=%.2f, k=%.1f, d=%.1f")
		:format(n, sp, self.stiffness, self.damping))
	return self
end
function SpringChain:Update(dt)
	local segs = self.segments
	for i = 1, #segs do
		local seg = segs[i]
		local anchor = (i == 1) and self.rootCFrame.Position or segs[i - 1].pos
		local d = anchor - seg.pos
		local dist = d.Magnitude
		if dist > 1e-6 then
			local desired = anchor - d.Unit * self.spacing
			local force = (desired - seg.pos) * self.stiffness
			- seg.vel * self.damping + self.gravity
			seg.vel += force * dt
			seg.pos += seg.vel * dt
		end
	end
	return segs
end

local Shake = {}
Shake.__index = Shake
MathService.Shake = Shake

function Shake.new(o)
	o = o or {}
	local self = setmetatable({
		trauma = 0, decay = o.decay or 1.5,
		maxOffset = o.maxOffset or 1.5,
		maxRoll = o.maxRoll or 0.15,
		maxPitch = o.maxPitch or 0.1,
		maxYaw = o.maxYaw or 0.1,
		frequency = o.frequency or 25,
		seed = o.seed or math.random() * 1000,
		time = 0,
	}, Shake)
	logMessage("Info", ("Shake.new: decay=%.2f, maxOffset=%.2f, freq=%.1f")
		:format(self.decay, self.maxOffset, self.frequency))
	return self
end
function Shake:AddTrauma(v)
	local before = self.trauma
	self.trauma = math.clamp(self.trauma + v, 0, 1)
	if v >= 0.5 then
		logMessage("Info", ("Shake: trauma %.2f -> %.2f (+%.2f)")
			:format(before, self.trauma, v))
	end
end
function Shake:SetTrauma(v) self.trauma = math.clamp(v, 0, 1) end
function Shake:Update(dt)
	self.time += dt
	self.trauma = math.max(0, self.trauma - self.decay * dt)
	local s = self.trauma * self.trauma
	local t = self.time * self.frequency
	local sd = self.seed
	local off = Vector3.new(
		math.noise(t, sd), math.noise(t + 100, sd), math.noise(t + 200, sd)
	) * 2 * self.maxOffset * s
	local rot = CFrame.Angles(
		math.noise(t + 300, sd) * 2 * self.maxPitch * s,
		math.noise(t + 400, sd) * 2 * self.maxYaw   * s,
		math.noise(t + 500, sd) * 2 * self.maxRoll  * s)
	return CFrame.new(off) * rot
end

local Flight = {}
Flight.__index = Flight
MathService.Flight = Flight

function Flight.new(o)
	o = o or {}
	local self = setmetatable({
		curve = o.curve, points = o.points, path = o.path,
		duration = o.duration or 1,
		loop = o.loop or false,
		onUpdate = o.onUpdate, onComplete = o.onComplete,
		speed = o.speed or 1, elapsed = 0, playing = false, conn = nil,
	}, Flight)
	logMessage("Info", ("Flight.new: duration=%.2f, loop=%s, mode=%s")
		:format(self.duration, tostring(self.loop), self.path and "path" or "curve"))
	return self
end
function Flight:Play()
	if self.playing then return self end
	self.playing = true
	self.conn = RunService.Heartbeat:Connect(function(dt) self:Step(dt) end)
	logMessage("Info", ("Flight:Play (speed=%.2f)"):format(self.speed))
	return self
end
function Flight:Stop()
	if not self.playing then return self end
	self.playing = false
	if self.conn then self.conn:Disconnect() self.conn = nil end
	logMessage("Info", ("Flight:Stop at t=%.2f"):format(self.elapsed / self.duration))
	return self
end
function Flight:Reset() self.elapsed = 0 return self end
function Flight:SetSpeed(s)
	self.speed = s
	logMessage("Info", ("Flight:SetSpeed(%.2f)"):format(s))
	return self
end
function Flight:Step(dt)
	self.elapsed += dt * self.speed
	local raw = self.elapsed / self.duration
	local finished = false
	local t
	if self.loop then t = raw % 1
	else
		t = math.clamp(raw, 0, 1)
		if raw >= 1 then finished = true end
	end
	local value
	if self.path then value = self.path:AtPercent(t)
	elseif self.curve and self.points then
		value = self.curve(t, table.unpack(self.points))
	end
	if value ~= nil and self.onUpdate then self.onUpdate(value, t) end
	if finished then
		self:Stop()
		logMessage("Info", "Flight:complete")
		if self.onComplete then self.onComplete() end
	end
end

local RandomT = {}
MathService.Random = RandomT
function RandomT.InSphere(rng, r)
	while true do
		local p = Vector3.new(rng:NextNumber()*2-1, rng:NextNumber()*2-1, rng:NextNumber()*2-1)
		if p:Dot(p) <= 1 then return p * r end
	end
end
function RandomT.OnSphere(rng)
	local function n() return math.sqrt(-2*math.log(1 - rng:NextNumber())) * math.cos(2*math.pi*rng:NextNumber()) end
	local v = Vector3.new(n(), n(), n())
	return v.Magnitude < 1e-9 and Vector3.yAxis or v.Unit
end
function RandomT.InBox(rng, hs)
	return Vector3.new(
		(rng:NextNumber()*2 - 1) * hs.X,
		(rng:NextNumber()*2 - 1) * hs.Y,
		(rng:NextNumber()*2 - 1) * hs.Z)
end

local Stat = {}
MathService.Stat = Stat
function Stat.Mean(a)
	if #a == 0 then return 0 end
	local s = 0
	for _, v in ipairs(a) do s += v end
	return s / #a
end
function Stat.Median(a)
	if #a == 0 then return 0 end
	local c = table.clone(a); table.sort(c)
	local n = #c
	return n % 2 == 1 and c[(n+1)//2] or (c[n//2] + c[n//2+1]) / 2
end
function Stat.Variance(a)
	if #a == 0 then return 0 end
	local m = Stat.Mean(a)
	local s = 0
	for _, v in ipairs(a) do s += (v - m)^2 end
	return s / #a
end
function Stat.StdDev(a) return math.sqrt(Stat.Variance(a)) end
function Stat.Min(a) local m = math.huge for _, v in ipairs(a) do if v < m then m = v end end return m end
function Stat.Max(a) local m = -math.huge for _, v in ipairs(a) do if v > m then m = v end end return m end

local V3, NUM = "Vector3", "number"

MathService.Register("bezier.quadratic", {
	t={type=NUM, required=true, range={0,1}}, p0={type=V3, required=true},
	p1={type=V3, required=true}, p2={type=V3, required=true},
}, function(p) return Bezier.Quadratic(p.t, p.p0, p.p1, p.p2) end)

MathService.Register("bezier.cubic", {
	t={type=NUM, required=true, range={0,1}}, p0={type=V3, required=true},
	p1={type=V3, required=true}, p2={type=V3, required=true}, p3={type=V3, required=true},
}, function(p) return Bezier.Cubic(p.t, p.p0, p.p1, p.p2, p.p3) end)

MathService.Register("bezier.cubicLookAt", {
	t={type=NUM, required=true, range={0,1}}, p0={type=V3, required=true},
	p1={type=V3, required=true}, p2={type=V3, required=true}, p3={type=V3, required=true},
}, function(p) return Bezier.CubicLookAt(p.t, p.p0, p.p1, p.p2, p.p3) end)

MathService.Register("smoothdamp", {
	current={type="number|Vector2|Vector3|CFrame", required=true},
	target={type="number|Vector2|Vector3|CFrame", required=true},
	velocity={type="number|Vector2|Vector3|CFrame", required=true},
	smoothTime={type=NUM, required=true}, dt={type=NUM, required=true},
	maxSpeed={type=NUM},
}, function(p) return MathService.SmoothDamp(
	p.current, p.target, p.velocity, p.smoothTime, p.maxSpeed, p.dt) end)

MathService.Register("spring", {
	current={required=true}, target={required=true}, velocity={required=true},
	stiffness={type=NUM, required=true}, damping={type=NUM, required=true},
	dt={type=NUM, required=true},
}, function(p) return MathService.Spring(
	p.current, p.target, p.velocity, p.stiffness, p.damping, p.dt) end)

MathService.Register("lerp", {
	a={type=NUM, required=true}, b={type=NUM, required=true},
	t={type=NUM, required=true, range={0,1}},
}, function(p) return Lerp.Number(p.a, p.b, p.t) end)

MathService.Register("lerpAngle", {
	a={type=NUM, required=true}, b={type=NUM, required=true},
	t={type=NUM, required=true, range={0,1}},
}, function(p) return Lerp.Angle(p.a, p.b, p.t) end)

MathService.Register("clamp", {
	v={type=NUM, required=true}, lo={type=NUM, required=true}, hi={type=NUM, required=true},
}, function(p) return math.clamp(p.v, p.lo, p.hi) end)

MathService.Register("remap", {
	v={type=NUM, required=true},
	inMin={type=NUM, required=true}, inMax={type=NUM, required=true},
	outMin={type=NUM, required=true}, outMax={type=NUM, required=true},
}, function(p) return Utility.Remap(p.v, p.inMin, p.inMax, p.outMin, p.outMax) end)

MathService.Register("smoothstep",
	{ t={type=NUM, required=true, range={0,1}} },
	function(p) return Utility.Smoothstep(p.t) end)

MathService.Register("catmullRom", {
	t={type=NUM, required=true, range={0,1}},
	p0={type=V3, required=true}, p1={type=V3, required=true},
	p2={type=V3, required=true}, p3={type=V3, required=true},
}, function(p) return Spline.CatmullRom(p.t, p.p0, p.p1, p.p2, p.p3) end)

MathService.Register("hermite", {
	t={type=NUM, required=true, range={0,1}},
	p0={type=V3, required=true}, p1={type=V3, required=true},
	m0={type=V3, required=true}, m1={type=V3, required=true},
}, function(p) return Spline.Hermite(p.t, p.p0, p.p1, p.m0, p.m1) end)

MathService.Register("noise.perlin1d",
	{ x={type=NUM, required=true}, seed={type=NUM} },
	function(p) return Noise.Perlin1D(p.x, p.seed) end)

MathService.Register("noise.perlin2d",
	{ x={type=NUM, required=true}, y={type=NUM, required=true}, seed={type=NUM} },
	function(p) return Noise.Perlin2D(p.x, p.y, p.seed) end)

MathService.Register("noise.fractal1d", {
	x={type=NUM, required=true}, octaves={type=NUM}, persistence={type=NUM},
	lacunarity={type=NUM}, seed={type=NUM},
}, function(p) return Noise.Fractal1D(
	p.x, p.octaves, p.persistence, p.lacunarity, p.seed) end)

MathService.Register("ballistics.solveAngle", {
	start={type=V3, required=true}, target={type=V3, required=true},
	speed={type=NUM, required=true}, gravity={type=V3, required=true},
}, function(p)
	local low, high = Ballistics.SolveAngle(p.start, p.target, p.speed, p.gravity)
	return { low = low, high = high }
end)

MathService.Register("ik.solve2bone", {
	root={type=V3, required=true}, target={type=V3, required=true},
	upperLen={type=NUM, required=true}, lowerLen={type=NUM, required=true},
	pole={type=V3, required=true},
}, function(p) return IK.Solve2Bone(p.root, p.target, p.upperLen, p.lowerLen, p.pole) end)

MathService.Register("distanceToSegment",
	{ p={type=V3, required=true}, a={type=V3, required=true}, b={type=V3, required=true} },
	function(p) return Vector.DistanceToSegment(p.p, p.a, p.b) end)

MathService.Register("angleDelta",
	{ a={type=NUM, required=true}, b={type=NUM, required=true} },
	function(p) return Angle.Delta(p.a, p.b) end)

logMessage("Info", ("NovoMathService loaded: %d commands"):format(#MathService.List()))

return MathService