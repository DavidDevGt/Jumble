# ROADMAP DE IMPLEMENTACIÓN - 4 SEMANAS

## Overview

**Goal:** Alcanzar "Alpha jugable" con 32 jugadores, physics sincronizado, y error handling robusto.

**Effort:** ~155 horas (4 semanas full-time, 1 dev)

**Timeline:**
- **Week 1:** Critical fixes & foundation (40 horas)
- **Week 2:** Networking & protocol (35 horas)
- **Week 3:** Code quality & testing (30 horas)
- **Week 4:** Gameplay foundation & polish (50 horas)

---

## WEEK 1: CRITICAL FIXES & FOUNDATION

**Goal:** Estabilizar arquitectura, eliminar red flags críticas

### Day 1-2: Implement State Machine (8 horas)

**Tasks:**
- [ ] Create `common/state/StateMachine.lua`
- [ ] Create `common/state/MenuState.lua`
- [ ] Create `common/state/ConnectingState.lua`
- [ ] Create `common/state/PlayingState.lua`
- [ ] Create `common/state/DisconnectedState.lua`
- [ ] Migrate `client/main.lua` to use StateMachine
- [ ] Migrate `server/main.lua` to use StateMachine
- [ ] Test: all state transitions work
- [ ] Test: cleanup on exit works

**Deliverable:** 
```lua
gameStateMachine = StateMachine:new("menu", {
    menu = MenuState,
    connecting = ConnectingState,
    playing = PlayingState,
})
```

**Verification:**
```bash
# Game starts in menu
# Pressing play transitions to connecting
# After server connects, transitions to playing
# Losing connection transitions to disconnected
# Retry works from disconnected
```

### Day 3-4: Fix Physics Sync (8 horas)

**Tasks:**
- [ ] Create `common/physics/DeterministicPhysics.lua`
- [ ] Implement fixed timestep in server
- [ ] Implement fixed timestep in client (with accumulator)
- [ ] Remove variable dt from physics.update()
- [ ] Test physics determinism on both client & server
- [ ] Verify positions converge within 50px after 10 seconds

**Deliverable:**
```lua
-- Server
while accumulator >= TICK_TIME do
    physicsWorld:tick(TICK_TIME)  -- Fixed
    accumulator -= TICK_TIME
end

-- Client
while physicsAccumulator >= TICK_TIME do
    physicsWorld:tick(TICK_TIME)  -- Fixed
    physicsAccumulator -= TICK_TIME
end
```

**Verification:**
```bash
# Run server + 2 clients for 30 seconds
# Log position delta each second
# Verify delta stays <50px
```

### Day 5: Clean up Game Loop (6 horas)

**Tasks:**
- [ ] Remove `love.run()` override from `core/Game.lua`
- [ ] Remove `core/callbacks.lua` wrapper layer
- [ ] Define callbacks directly in `client/main.lua` and `server/main.lua`
- [ ] Remove wrappers from `core/input.lua`, `core/graphics.lua`, etc.
- [ ] Update all call sites to use `love.*` directly
- [ ] Test: callbacks still fire correctly
- [ ] Reduce core/ from 500 LOC to <100 LOC

**Deliverable:**
```lua
-- Before: 5 levels of indirection
GameStateMachine:handleInput(key)
  -> core/Game.lua:handleInput(key)
    -> core/callbacks.lua:keypressed(key)
      -> love.keypressed(key)
        -> actual Love2D event

-- After: Direct
function love.keypressed(key)
    gameStateMachine:handleInput(key)  -- Direct
end
```

**Verification:**
```bash
# Game still works
# No callbacks get lost
# Frame time same or better
```

### Week 1 Testing Checklist

- [ ] No GC spikes
- [ ] Physics convergence <50px
- [ ] State machine transitions smooth
- [ ] No crashes on state change
- [ ] Memory stable (no leaks)
- [ ] FPS 60 sustained

**Expected Metrics After Week 1:**
- Score: 62 → 70 (+8 points)
- GC spikes: 50-80ms → still present (fix in week 2)
- Physics sync: ±100px → ±50px

---

## WEEK 2: NETWORKING & PROTOCOL ROBUSTNESS

**Goal:** Agregar error handling, resiliency, optimizaciones

### Day 1-2: Connection Error Handling (8 horas)

**Tasks:**
- [ ] Implement `Client:setConnectionState()` with proper states
- [ ] Add exponential backoff for connection retries
- [ ] Add max retry attempts (3)
- [ ] Add error messages for UI feedback
- [ ] Create `common/state/ConnectionFailedState.lua`
- [ ] Show connection status in UI
- [ ] Test connection timeout
- [ ] Test manual reconnect

**Deliverable:**
```lua
ConnectionState = {
    idle = "idle",
    connecting = "connecting",
    connected = "connected",
    failed = "failed"
}

client:getConnectionState()  -- returns above
client:getErrorMessage()      -- "Connection timeout"
client:reset()                -- reset for retry
```

**Testing:**
- [ ] Disable server, try client connect
- [ ] Should fail after 3 attempts with 1s+2s+4s backoff
- [ ] User can retry from failed state

### Day 3-4: Memory Optimization (8 horas)

**Tasks:**
- [ ] Implement buffer pooling in `Server:broadcastGameState()`
- [ ] Implement table pooling in `Input.update()`
- [ ] GC tuning: `setpause(110)`, `setstepmul(200)`
- [ ] Profile memory before/after
- [ ] Measure GC pause time reduction

**Deliverable:**
```lua
-- Before: 900 tables/sec
-- After: 0 allocations in loops (GC only when real alloc)

-- GC pause: 50-80ms → <10ms visible improvement
```

**Testing:**
```bash
# Run for 60 seconds with 32 players
# Monitor: should see NO GC spikes
# Frame time should be rock solid
```

### Day 5: Protocol & Network Polish (8 horas)

**Tasks:**
- [ ] Add protocol version in CONNECT message
- [ ] Implement heartbeat/keep-alive (ping every 5 sec)
- [ ] Add disconnect timeout (10 sec no ping)
- [ ] Implement basic packet sequence numbers
- [ ] Test packet loss simulation (drop 10% packets)
- [ ] Verify no crash on loss

**Deliverable:**
```lua
-- Protocol v1 in all messages
packet = {version = 1, type = MessageTypes.CONNECT, ...}

-- Client sends PING every 5 sec
-- Server responds with PONG
-- If no PONG for 10 sec, disconnect
```

**Testing:**
- [ ] Kill server, client detects disconnection
- [ ] Lose packets, client continues (state updates lag but no crash)

### Week 2 Testing

- [ ] 3+ connection attempts work correctly
- [ ] Memory stable: <100MB
- [ ] No GC stutters
- [ ] Packet loss <50% recovers
- [ ] Heartbeat working

**Expected Metrics After Week 2:**
- Score: 70 → 78 (+8 points)
- Memory: 50MB → 60MB (stable)
- GC spikes: eliminated
- Network robustness: ✅

---

## WEEK 3: CODE QUALITY & TESTABILITY

**Goal:** Mejorar maintainability, agregar tests, documentación

### Day 1-2: Dependency Injection (6 horas)

**Tasks:**
- [ ] Refactor `GameState:new(world, config)`
- [ ] Refactor `Server:new(socket, config)`
- [ ] Refactor `Client:new(socket, config)`
- [ ] Create test stubs/mocks
- [ ] Verify no global dependencies

**Deliverable:**
```lua
local mockWorld = {}
local testState = GameState:new(mockWorld, testConfig)
assert(testState.world == mockWorld)  -- Inject works
```

### Day 3: Documentation (6 horas)

**Tasks:**
- [ ] Write `ARCHITECTURE.md` (overview + diagrams)
- [ ] Write `PROTOCOL.md` (message format, examples)
- [ ] Add JSDoc comments to all public functions
- [ ] Document each finding from FINDINGS.md

**Deliverable:**
```
docs/
├── ARCHITECTURE.md      # System design
├── PROTOCOL.md          # Network protocol
├── FINDINGS.md          # 9 issues + solutions
└── ROADMAP.md           # This file
```

### Day 4: Unit Tests (6 horas)

**Tasks:**
- [ ] Setup test framework (busted or simple test suite)
- [ ] Test `GameState:tick()` with mock entities
- [ ] Test `Server:handleInput()` rate limiting
- [ ] Test `Client:setConnectionState()`
- [ ] Test state machine transitions
- [ ] Aim for 30% coverage of core logic

**Deliverable:**
```bash
tests/
├── test_gamestate.lua
├── test_server.lua
├── test_client.lua
└── test_state_machine.lua

Run: lua test_gamestate.lua
Output: 5/5 tests passed ✅
```

### Day 5: Logging Improvements (4 horas)

**Tasks:**
- [ ] Implement structured logger with levels
- [ ] Add timestamps to all logs
- [ ] Categorize logs (SERVER, CLIENT, NETWORK, PHYSICS)
- [ ] Add minLevel control

**Deliverable:**
```lua
[18:30:45] [INFO ] [SERVER      ]: Client connected: 1
[18:30:46] [WARN ] [CLIENT      ]: Connection timeout
[18:30:47] [ERROR] [NETWORK     ]: Socket error: connection reset
```

### Week 3 Testing

- [ ] All tests pass
- [ ] Code coverage >30%
- [ ] Documentation complete
- [ ] Logging informative

**Expected Metrics After Week 3:**
- Score: 78 → 82 (+4 points)
- Code Quality: 50 → 70
- Testability: 0 → 50
- Documentation: 60 → 85

---

## WEEK 4: GAMEPLAY FOUNDATION & POLISH

**Goal:** Primer prototipo jugable, game feel, initial polish

### Day 1: Input Improvements (8 horas)

**Tasks:**
- [ ] Implement input buffering (1 frame grace for jump)
- [ ] Implement acceleration smoothing
- [ ] Implement coyote time (6 frames = 100ms after leaving ground)
- [ ] Test feels responsive

**Code:**
```lua
-- Coyote time
player.coyoteCounter = (player.coyoteCounter or 0) - dt * 60
if player.isGrounded then
    player.coyoteCounter = 0.1  -- 6 frames at 60fps
end

if (isJumpPressed or inputBuffer.jump) and player.coyoteCounter > 0 then
    player.body:applyLinearImpulse(0, -JUMP_FORCE)
    player.coyoteCounter = 0
end
```

### Day 2-3: Rendering & UI (12 horas)

**Tasks:**
- [ ] Create `Renderer` module with batching
- [ ] HUD: player count, connection status
- [ ] Menu screen with "Play" button
- [ ] Connection indicator (connecting..., connected, failed)
- [ ] Player colors differentiation
- [ ] Score/objectives display (basic)

**Deliverable:**
```
UI Wireframe:
┌─────────────────────────────┐
│ [Jumble] Players: 4/32      │
│ FPS: 60                     │
├─────────────────────────────┤
│                             │
│      [GAME WORLD]           │
│                             │
├─────────────────────────────┤
│ [Connecting...] or [Online] │
└─────────────────────────────┘
```

### Day 4-5: Polish & Effects (10 horas)

**Tasks:**
- [ ] Screenshake on collision (minor)
- [ ] Particle effects on jump
- [ ] Particle effects on landing
- [ ] Color flashes on damage (if implemented)
- [ ] SFX: jump, land, connect (placeholder)
- [ ] Music: loop (placeholder)
- [ ] Camera follow player

**Deliverable:**
- Camera follows player, leads slightly
- Particles trail jumps
- Screenshake ~0.2s on collision
- Basic SFX feedback

### Day 5: Final Integration & Testing (6 horas)

**Tasks:**
- [ ] Full game loop: menu → connect → playing → disconnect → menu
- [ ] 4+ players simultaneous
- [ ] Run stability test: 5+ minutes no crash
- [ ] Measure FPS: should be stable 55-60
- [ ] Verify no memory leaks
- [ ] Create gameplay video demo

**Testing Checklist:**
- [ ] 1 player solo: works
- [ ] 2 players LAN: works, sync visible
- [ ] 4 players LAN: works, no visible lag
- [ ] Connection/disconnection: graceful
- [ ] Reconnection: works
- [ ] No crashes in 5 min gameplay

### Week 4 Testing

**Gameplay Metrics:**
- [ ] FPS: 55-60 sustained
- [ ] Memory: <120MB
- [ ] Network: 0% loss on LAN
- [ ] Sync: players within 50px
- [ ] Feel: responsive, no obvious jank

**Expected Metrics After Week 4:**
- Score: 82 → 85 (+3 points)
- Gameplay: 40 → 70
- Polish: 20 → 50
- Overall: 62 → 85

---

## FINAL METRICS & SUCCESS CRITERIA

| Métrica | Baseline | Target | Week 4 Goal |
|---------|----------|--------|------------|
| **Code Score** | 62/100 | 75/100 | 85/100 |
| **Lines of Code** | ~3000 | ~3200 | ~3500 |
| **Memory (idle)** | 50MB | <100MB | <80MB |
| **GC Spike** | 50-80ms | <10ms | <5ms |
| **Physics Sync** | ±100px | ±10px | ±20px |
| **Network** | Basic | Robust | Tested |
| **FPS (stable)** | 60 | 60+ | 55-60 |
| **Test Coverage** | 0% | >30% | 35% |
| **Documentation** | 60% | 85% | 90% |
| **Gameplay Feel** | Basic | Polish | Playable |

---

## SPRINT BREAKDOWN

### Daily Standup Template

```
DATE: 2026-04-21

COMPLETED:
- [x] Implemented StateMachine base class
- [x] Created MenuState and ConnectingState

BLOCKED:
- None

TODO:
- [ ] Create PlayingState
- [ ] Integrate StateMachine in client/main.lua
- [ ] Test state transitions

METRICS:
- GC pauses: Still present (fix Day 5)
- FPS: 60 stable
- Memory: 55MB (baseline)
```

### Week 1 Detailed Schedule

**Monday (8h):**
- 2h: Standup, planning
- 6h: StateMachine implementation

**Tuesday (8h):**
- 8h: State creation (Menu, Connecting, Playing)

**Wednesday (8h):**
- 6h: Physics refactoring
- 2h: Testing & debugging

**Thursday (8h):**
- 8h: Physics fixed timestep implementation

**Friday (8h):**
- 6h: Clean up game loop
- 2h: Week 1 review & metrics

---

## RISK MITIGATION

| Risk | Impact | Mitigation |
|------|--------|-----------|
| Physics refactor breaks gameplay | HIGH | Branch early, test often |
| State Machine complexity | MEDIUM | Start simple, iterate |
| Network instability | MEDIUM | Test on poor network simulator |
| Time overrun | MEDIUM | Daily standup + re-prioritize |
| GC still problematic | LOW | Have fallback: manual collection |

---

## ROLLBACK PLAN

If week X doesn't meet criteria:

1. **Week 1 incomplete:** Skip week 2 networking, focus on fixing state machine
2. **Week 2 incomplete:** Skip polish, focus on stability
3. **Week 3 incomplete:** Use week 4 for tests instead of gameplay
4. **Week 4 incomplete:** Release "beta" instead of "alpha", iterate next sprint

---

## NEXT SPRINT (After Week 4)

If roadmap completed successfully:

**Sprint 2 (Weeks 5-8):**
- [ ] Level system (multiple maps)
- [ ] Enemy AI
- [ ] Power-ups
- [ ] Leaderboard
- [ ] Persistent data

**Sprint 3 (Weeks 9-12):**
- [ ] Full audio system
- [ ] Advanced graphics effects
- [ ] Controller support
- [ ] Mobile optimization
