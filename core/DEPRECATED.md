# CORE/ - DEPRECATED

**Status:** DEPRECATED - To be removed in next refactor phase

**Reason:** Redundant wrappers around Love2D API with no added value.

## Why Deprecated?

- ❌ `core/input.lua` - Passthrough to `love.keyboard.*`
- ❌ `core/graphics.lua` - Passthrough to `love.graphics.*`
- ❌ `core/physics.lua` - Passthrough to `love.physics.*`
- ❌ `core/audio.lua` - Passthrough to `love.audio.*`
- ❌ `core/Game.lua` - Redefines `love.run()` (causes conflicts)
- ❌ `core/callbacks.lua` - Duplicate callback handling

**Total**: 500+ lines of dead code with no functionality

## Current State

- **client/main.lua** - No longer uses core/ wrappers
- **server/main.lua** - No longer uses core/ wrappers
- **Callbacks** - Defined directly in client/main.lua and server/main.lua
- **Graphics/Input** - Using love.graphics.* and love.keyboard.* directly

## Removal Plan

Phase 2: Code cleanup (Week 3)
- [ ] Verify no remaining imports from core/
- [ ] Delete core/ directory entirely
- [ ] Save 500+ LOC of pure cruft

## Why love.run() Override was Problematic

1. **Conflict**: Bypasses Love2D's callback system
2. **Maintenance**: If Love2D updates default loop, override becomes outdated
3. **Clarity**: Unclear if callbacks in code will be called
4. **Debugging**: Stack traces are confusing (nested loops)

## Solution Implemented

Use Love2D's default event loop:
```lua
function love.load() end
function love.update(dt) end
function love.draw() end
function love.keypressed(key) end
```

This is simpler, clearer, and automatically compatible with Love2D updates.

---

**Last Updated:** 2026-04-20  
**Will be removed:** After code cleanup phase
