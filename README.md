[README.md](https://github.com/user-attachments/files/33956614/README.md)
# NovoMathService# MathService (Roblox)

Математическая библиотека для Roblox с реестром команд, валидацией параметров и отладочным выводом.

Поддерживает кривые Безье, сплайны, физику пружин, IK, баллистику, генерацию шума, тряску камеры и утилиты для плавного движения. Реализует единый реестр команд с проверкой типов, fluent построитель вызовов, пакетное выполнение и анимированные полёты по кривым.

## Содержание

- [Требования](#требования)
- [Установка](#установка)
- [Поля модуля](#поля-модуля)
- [API](#api)
  - [Register](#register)
  - [Unregister](#unregister)
  - [Has](#has)
  - [List](#list)
  - [Run](#run)
  - [RunBatch](#runbatch)
  - [Cmd](#cmd)
  - [Debug](#debug)
- [Валидация параметров](#валидация-параметров)
- [Подмодули](#подмодули)
  - [Angle](#angle)
  - [Lerp](#lerp)
  - [Bezier и Path](#bezier-и-path)
  - [Easing](#easing)
  - [Noise](#noise)
  - [Utility](#utility)
  - [Vector](#vector)
  - [Spline](#spline)
  - [Ballistics](#ballistics)
  - [IK](#ik)
- [Объекты состояния](#объекты-состояния)
  - [SpringObject](#springobject)
  - [SpringChain](#springchain)
  - [Shake](#shake)
  - [Flight](#flight)
- [Утилиты](#утилиты)
  - [SmoothDamp и Spring](#smoothdamp-и-spring)
  - [Random](#random)
  - [Stat](#stat)
- [Встроенные команды](#встроенные-команды)
- [Пример использования](#пример-использования)

---

## Требования

- Roblox Studio
- Модуль не имеет клиентских или серверных ограничений, работает в любом контексте
- Зависимости: `TweenService`, `RunService` из стандартного `game:GetService`

## Установка

1. Помести `MathService.luau` (или `ModuleScript`) в `ReplicatedStorage` или другую доступную папку.
2. Подключи модуль:

```lua
local MathService = require(path.to.MathService)
```

При загрузке модуль регистрирует встроенный набор команд и пишет в консоль строку `NovoMathService loaded: N commands`.

---

## Поля модуля

| Поле | Тип | Описание |
|---|---|---|
| `MathService.Debug` | `table` | Управление отладочным выводом |
| `MathService.Angle` | `table` | Утилиты для углов |
| `MathService.Lerp` | `table` | Интерполяция |
| `MathService.Bezier` | `table` | Кривые Безье и компиляция путей |
| `MathService.Easing` | `table` | Функции плавности |
| `MathService.Noise` | `table` | Шум Перлина и фракталы |
| `MathService.Utility` | `table` | Общие утилиты |
| `MathService.Vector` | `table` | Векторная геометрия |
| `MathService.Spline` | `table` | Сплайны |
| `MathService.Ballistics` | `table` | Баллистика |
| `MathService.IK` | `table` | Двухзвенная инверсная кинематика |
| `MathService.SpringObject` | `table` | Объект пружины |
| `MathService.SpringChain` | `table` | Цепочка пружинных сегментов |
| `MathService.Shake` | `table` | Генератор тряски |
| `MathService.Flight` | `table` | Аниматор полёта по кривой |
| `MathService.Random` | `table` | Случайные точки и направления |
| `MathService.Stat` | `table` | Статистика по массивам |
| `MathService.SmoothDamp` | `function` | Обёртка `TweenService:SmoothDamp` |
| `MathService.Spring` | `function` | Шаг интегратора пружины |
| `MathService.SpringSettled` | `function` | Проверка остановки пружины |
| `MathService.LerpAngle` | `function` | Алиас `Lerp.Angle` |

---

## API

### Register

```lua
MathService.Register(name: string, spec: table?, fn: function)
```

Регистрирует команду в глобальном реестре. Если `spec` передан, параметры будут провалидированы перед вызовом `fn`.

| Параметр | Тип | Описание |
|---|---|---|
| `name` | `string` | Уникальное имя команды |
| `spec` | `table?` | Спецификация параметров |
| `fn` | `function` | Функция, принимающая `params` |

```lua
MathService.Register("my.add", {
    a = { type = "number", required = true },
    b = { type = "number", required = true },
}, function(p) return p.a + p.b end)
```

### Unregister

```lua
MathService.Unregister(name: string)
```

Удаляет команду из реестра.

### Has

```lua
MathService.Has(name: string): boolean
```

Проверяет, зарегистрирована ли команда.

### List

```lua
MathService.List(): {string}
```

Возвращает отсортированный по алфавиту список имён всех команд.

### Run

```lua
MathService.Run(name: string, params: table?): any, string?
```

Выполняет команду. При ошибке валидации или неизвестной команде возвращает `nil, errorMessage`. Сама команда может вернуть несколько значений, они упаковываются через `table.pack`.

```lua
local res, err = MathService.Run("lerp", { a = 0, b = 10, t = 0.5 })
-- res == 5
```

### RunBatch

```lua
MathService.RunBatch(list: {{cmd: string, params: table?}}): {any} | nil, string?
```

Выполняет список команд по порядку. При первой ошибке прерывается и возвращает `nil, "<batch i>: <error>"`.

```lua
local results = MathService.RunBatch({
    { cmd = "clamp", params = { v = 5, lo = 0, hi = 3 } },
    { cmd = "lerp",  params = { a = 0, b = 10, t = 0.5 } },
})
```

### Cmd

```lua
MathService.Cmd(name: string): CmdClass
```

Возвращает fluent построитель для команды.

| Метод | Описание |
|---|---|
| `:with(table)` | Сливает таблицу в `params` |
| `:set(key, value)` | Устанавливает один параметр |
| `:run()` | Вызывает `MathService.Run` |

```lua
MathService.Cmd("lerp")
    :set("a", 0)
    :with({ b = 10, t = 0.5 })
    :run()
```

### Debug

Отладочный вывод с рамочным оформлением. Управляется атрибутом `Debugging` на скрипте модуля.

```lua
MathService.Debug.Enable()
MathService.Debug.Disable()
MathService.Debug.IsEnabled() -- boolean

MathService.Debug.Log("info")
MathService.Debug.Warn("warning")
MathService.Debug.Error("error")
MathService.Debug.Dump()
```

Пример вывода:

```
┌────────────────────────────────────────────────────────────┐
│ [OUT] ModuleName                             14:23:11      │
├────────────────────────────────────────────────────────────┤
│  -> your message                                           │
└────────────────────────────────────────────────────────────┘
```

---

## Валидация параметров

Спецификация команды это таблица `{ [paramName] = rule }`, где `rule` может быть:

- **строка**: тип (поддерживает объединения через `|`, например `"number|Vector3"`)
- **таблица**:
  - `type: string?` тип (может содержать `|`)
  - `range: {min?, max?}?` числовой диапазон
  - `required: boolean?` обязателен ли параметр

```lua
{
    t = { type = "number", required = true, range = { 0, 1 } },
    target = { type = "Vector3|CFrame", required = true },
    speed = { type = "number" },
}
```

Типы проверяются через `typeof`, поэтому работают `number`, `string`, `Vector3`, `CFrame`, `Instance`, `boolean` и другие.

---

## Подмодули

### Angle

Углы в радианах с нормализацией в `(-π, π]`.

```lua
MathService.Angle.Normalize(r)
MathService.Angle.Delta(from, to)
MathService.Angle.RotateTowards(cur, tgt, maxStep)
```

### Lerp

```lua
MathService.Lerp.Number(a, b, t)
MathService.Lerp.Vector(a, b, t)
MathService.Lerp.CFrame(a, b, t)
MathService.Lerp.Angle(a, b, t)
```

`Lerp.Angle` интерполирует по кратчайшему пути через `Angle.Delta`.

### Bezier и Path

```lua
MathService.Bezier.Quadratic(t, p0, p1, p2)
MathService.Bezier.Cubic(t, p0, p1, p2, p3)
MathService.Bezier.QuadraticDerivative(t, p0, p1, p2)
MathService.Bezier.CubicDerivative(t, p0, p1, p2, p3)
MathService.Bezier.QuadraticCFrame(t, c0, c1, c2)
MathService.Bezier.CubicCFrame(t, c0, c1, c2, c3)
MathService.Bezier.CubicLookAt(t, p0, p1, p2, p3)
```

Компиляция пути:

```lua
local path = MathService.Bezier.CompilePath(MathService.Bezier.Cubic, { p0, p1, p2, p3 }, 200)
```

Объект `Path` строит таблицу `samples` с накопленным расстоянием и позволяет делать равномерные выборки по длине.

| Метод | Описание |
|---|---|
| `path:AtDistance(d)` | Точка по расстоянию от начала |
| `path:AtPercent(p)` | Точка по проценту (0..1) |
| `path:AtTime(elapsed, duration)` | Точка по времени |

Поле `path.length` хранит общую длину кривой.

### Easing

Функции плавности с аргументом `t` в диапазоне `[0, 1]`.

Доступные имена: `linear`, `quadIn/Out/InOut`, `cubicIn/Out/InOut`, `quartIn/Out`, `quintIn/Out`, `sineIn/Out/InOut`, `expoIn/Out/InOut`, `circIn/Out`, `backIn/Out/InOut`, `elasticIn/Out`, `bounceIn/Out`.

```lua
local eased = MathService.Easing.cubicOut(0.4)
```

Каждая функция также доступна как команда `"ease.<name>"`, например `"ease.bounceOut"`.

### Noise

```lua
MathService.Noise.Perlin1D(x, seed?)
MathService.Noise.Perlin2D(x, y, seed?)
MathService.Noise.Perlin3D(x, y, z, seed?)
MathService.Noise.Fractal1D(x, octaves?, persistence?, lacunarity?, seed?)
MathService.Noise.Fractal2D(x, y, octaves?, persistence?, lacunarity?, seed?)
```

Значения фрактала по умолчанию: `octaves = 4`, `persistence = 0.5`, `lacunarity = 2`.

### Utility

```lua
MathService.Utility.Clamp(v, lo, hi)
MathService.Utility.InverseLerp(a, b, v)
MathService.Utility.Remap(v, inMin, inMax, outMin, outMax)
MathService.Utility.Smoothstep(t)
MathService.Utility.Smootherstep(t)
MathService.Utility.Approach(cur, tgt, maxDelta)
MathService.Utility.PingPong(t, length)
```

`Approach` принимает числа и векторы.

### Vector

```lua
MathService.Vector.ProjectOnLine(p, a, b)
MathService.Vector.ProjectOnSegment(p, a, b)
MathService.Vector.DistanceToLine(p, a, b)
MathService.Vector.DistanceToSegment(p, a, b)
MathService.Vector.Reflect(incident, normal)
MathService.Vector.MoveTowards(current, target, maxDelta)
```

### Spline

```lua
MathService.Spline.CatmullRom(t, p0, p1, p2, p3)
MathService.Spline.CatmullRomChain(t, points)
MathService.Spline.Hermite(t, p0, p1, m0, m1)
MathService.Spline.BSpline(t, p0, p1, p2, p3)
MathService.Spline.FrenetFrame(curveFn, t, ...)
```

`CatmullRomChain` принимает массив `points` и параметр `t` в `[0, 1]` по всей цепочке.

`FrenetFrame` строит CFrame с направлением по касательной.

### Ballistics

```lua
MathService.Ballistics.Position(start, velocity, gravity, t)
MathService.Ballistics.SolveAngle(start, target, speed, gravity)
MathService.Ballistics.TimeToHit(start, target, speed, gravity, high?)
MathService.Ballistics.VelocityToHit(start, target, speed, gravity, high?)
```

`SolveAngle` возвращает два угла (низкий и высокий) или `nil`, если решения нет.

### IK

```lua
MathService.IK.Solve2Bone(root, target, upperLen, lowerLen, pole)
MathService.IK.Solve2BoneCFrames(root, target, upperLen, lowerLen, pole)
```

`Solve2Bone` возвращает позицию сустава.

`Solve2BoneCFrames` возвращает `cframeUpper, cframeLower, jointPos`.

---

## Объекты состояния

### SpringObject

Пружина для одного значения (число, вектор, CFrame).

```lua
local s = MathService.SpringObject.new({
    value = 0,
    target = 100,
    stiffness = 150,
    damping = 10,
})

s:SetTarget(50)
s:Step(dt)
s:Settled()
```

| Метод | Описание |
|---|---|
| `:SetTarget(v)` | Устанавливает цель |
| `:Step(dt)` | Делает шаг симуляции, возвращает новое значение |
| `:Settled()` | Возвращает `true`, если пружина остановилась |

### SpringChain

Цепочка сегментов для волос, хвостов, верёвок.

```lua
local chain = MathService.SpringChain.new({
    points = 10,
    rootCFrame = rootCFrame,
    spacing = 0.5,
    stiffness = 150,
    damping = 10,
    gravity = Vector3.new(0, -20, 0),
})

chain:Update(dt)
for _, seg in ipairs(chain.segments) do
    -- seg.pos, seg.vel
end
```

### Shake

Генератор тряски на основе шума Перлина (модель "trauma" из доклада Squirrel Eiserloh).

```lua
local shake = MathService.Shake.new({
    decay = 1.5,
    maxOffset = 1.5,
    maxRoll = 0.15,
    maxPitch = 0.1,
    maxYaw = 0.1,
    frequency = 25,
})

shake:AddTrauma(0.4)
shake:SetTrauma(0.8)

local offset = shake:Update(dt)
camera.CFrame = camera.CFrame * offset
```

`AddTrauma` и `SetTrauma` принимают значение в `[0, 1]`, `Update` возвращает CFrame смещения.

### Flight

Аниматор полёта по кривой или `Path`.

```lua
local flight = MathService.Flight.new({
    path = path,
    -- или
    -- curve = MathService.Bezier.Cubic,
    -- points = { p0, p1, p2, p3 },
    duration = 2,
    loop = false,
    speed = 1,
    onUpdate = function(value, t) end,
    onComplete = function() end,
})

flight:Play()
flight:SetSpeed(0.5)
flight:Reset()
flight:Stop()
```

`Flight` использует `RunService.Heartbeat` и вызывает `onUpdate(value, t)` каждый кадр, где `t` нормализован в `[0, 1]`.

---

## Утилиты

### SmoothDamp и Spring

```lua
MathService.SmoothDamp(current, target, velocity, smoothTime, maxSpeed?, dt)
MathService.Spring(cur, tgt, vel, stiffness, damping, dt)
MathService.SpringSettled(cur, tgt, vel, posTolerance?, velTolerance?)
```

`SmoothDamp` оборачивает `TweenService:SmoothDamp`.

`Spring` возвращает `value, velocity`.

`SpringSettled` работает и с числами, и с векторами (через `magnitude`).

### Random

```lua
MathService.Random.InSphere(rng, radius)
MathService.Random.OnSphere(rng)
MathService.Random.InBox(rng, halfSize)
```

`rng` это объект `Random` (`Random.new()`), а не `math.random`.

### Stat

```lua
MathService.Stat.Mean(array)
MathService.Stat.Median(array)
MathService.Stat.Variance(array)
MathService.Stat.StdDev(array)
MathService.Stat.Min(array)
MathService.Stat.Max(array)
```

---

## Встроенные команды

Доступны через `MathService.Run(name, params)`.

| Имя | Параметры |
|---|---|
| `ease.<name>` | `t` |
| `bezier.quadratic` | `t, p0, p1, p2` |
| `bezier.cubic` | `t, p0, p1, p2, p3` |
| `bezier.cubicLookAt` | `t, p0, p1, p2, p3` |
| `smoothdamp` | `current, target, velocity, smoothTime, dt, maxSpeed?` |
| `spring` | `current, target, velocity, stiffness, damping, dt` |
| `lerp` | `a, b, t` |
| `lerpAngle` | `a, b, t` |
| `clamp` | `v, lo, hi` |
| `remap` | `v, inMin, inMax, outMin, outMax` |
| `smoothstep` | `t` |
| `catmullRom` | `t, p0, p1, p2, p3` |
| `hermite` | `t, p0, p1, m0, m1` |
| `noise.perlin1d` | `x, seed?` |
| `noise.perlin2d` | `x, y, seed?` |
| `noise.fractal1d` | `x, octaves?, persistence?, lacunarity?, seed?` |
| `ballistics.solveAngle` | `start, target, speed, gravity` |
| `ik.solve2bone` | `root, target, upperLen, lowerLen, pole` |
| `distanceToSegment` | `p, a, b` |
| `angleDelta` | `a, b` |

---

## Пример использования

```lua
local MathService = require(game.ReplicatedStorage.MathService)

MathService.Debug.Enable()

-- 1. Полёт по кривой Безье
local path = MathService.Bezier.CompilePath(
    MathService.Bezier.Cubic,
    {
        Vector3.new(0, 5, 0),
        Vector3.new(10, 20, 0),
        Vector3.new(20, 20, 0),
        Vector3.new(30, 5, 0),
    },
    300
)

MathService.Flight.new({
    path = path,
    duration = 3,
    onUpdate = function(pos) part.Position = pos end,
    onComplete = function() print("Прилетели") end,
}):Play()

-- 2. Пружина для позиции
local spring = MathService.SpringObject.new({
    value = part.Position,
    target = goal.Position,
    stiffness = 120,
    damping = 15,
})

game:GetService("RunService").Heartbeat:Connect(function(dt)
    spring:Step(dt)
    part.Position = spring.value
end)

-- 3. Баллистический выстрел
local velocity = MathService.Ballistics.VelocityToHit(
    turret.Position,
    target.Position,
    150,
    workspace.Gravity * Vector3.yAxis,
    false
)

if velocity then
    local proj = projectile:Clone()
    proj.Position = turret.Position
    proj.AssemblyLinearVelocity = velocity
    proj.Parent = workspace
end

-- 4. Тряска камеры
local shake = MathService.Shake.new({ decay = 2, maxOffset = 2, frequency = 30 })
shake:AddTrauma(0.7)

game:GetService("RunService").RenderStepped:Connect(function(dt)
    camera.CFrame = camera.CFrame * shake:Update(dt)
end)

-- 5. Двухзвенная IK
local cframeUpper, cframeLower = MathService.IK.Solve2BoneCFrames(
    Vector3.new(0, 5, 0),
    Vector3.new(0, 0, 0),
    2.5,
    2.5,
    Vector3.new(0, 0, -1)
)

upperBone.CFrame = cframeUpper
lowerBone.CFrame = cframeLower
```
