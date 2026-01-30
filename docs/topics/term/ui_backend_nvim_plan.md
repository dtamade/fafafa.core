# Neovim RPC Backend Plan (IUiBackendV2)

Goal: Implement a backend that renders UI frames to Neovim via msgpack-rpc, leveraging the modernized IUiBackendV2 direct ops (WriteAt/FillRect) and capabilities.

## Interfaces
- IUiBackend (existing): BeginFrame/EndFrame, Size, Clear, Cursor/Write/Attr
- IUiBackendV2 (new): GetCapabilities, WriteAt, FillRect

Query pattern in ui_surface:
- If Supports(Current, IUiBackendV2) use V2 ops, else fallback to Cursor+Write

## Connection & Lifecycle
- Construction: CreateNvimBackend(endpoint: string) or (cmdline: string)
  - endpoint can be: `\"nvim --embed\"` (spawn) or an address for RPC attach
- Lazy-connect on first BeginFrame/Size
- BeginFrame: start ops batch; clear transient state
- EndFrame: flush ops batch via RPC; return success/failure (keep bool for future)
- Size: query/subscribe; fallback cached value; default 80x24 if unknown

## Capabilities
- CapTrueColor: if termguicolors enabled (or assume true)
- CapBatchWrite: backend buffers ops and flush at EndFrame
- CapClear, CapCursor: supported via RPC

GetCapabilities returns subset based on negotiated features (initially [CapBatchWrite, CapCursor, CapClear], TrueColor optional)

## Operation Mapping
- WriteAt(y, x, s): queue op {type: put, y, x, s}
- FillRect(x, y, w, h, ch):
  - If server supports fill, queue {type: fill, x, y, w, h, ch}
  - Else expand to h lines of put with repeated string
- Clear: queue {type: clear}
- CursorLine/Col/VisibleSet: queue {type: cursor, y/x/visible}
- Attr (future): add {type: attr, fg/bg/styles}

## Performance
- Batch all ops during frame; one rpc call at EndFrame
- Optionally coalesce consecutive WriteAt on same line
- Keep minimal string allocations; reuse buffers

## Error Handling
- EndFrame flush returns rpc status; on failure: mark disconnected; optionally buffer last frame for retry or drop silently
- If disconnected: Size returns false, write ops ignored; caller can switch backend or retry

## Testing Strategy
- Unit-test with a mock transport (in-memory msgpack recorder)
- Golden tests on serialized op sequence for simple scenes
- Do not require live Neovim in unit tests

## Incremental Delivery
1) Skeleton unit ui_backend_nvim.pas (compiles, no transport)
2) Define transport interface (INvimTransport: Connect/Request/Notify)
3) Implement op batching + mock transport tests
4) Add minimal real transport (spawn `nvim --embed`) guarded behind build tag or optional

## Risks / Open Questions
- Neovim API version compatibility (decide minimal version)
- TrueColor/style mapping details (defer until TUiAttr lands)
- Window resize events (subscribe/dispatch later)

