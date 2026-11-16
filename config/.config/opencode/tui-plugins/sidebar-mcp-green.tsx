/** @jsxImportSource @opentui/solid */
// Replacement for the built-in sidebar MCP section (internal:sidebar-mcp, disabled in tui.json).
// Identical to upstream v1.18.34 except connected server names are drawn in theme.success (green).
import type { TuiPlugin, TuiPluginApi, TuiPluginModule } from "@opencode-ai/plugin/tui"
import { createMemo, createSignal, For, Match, Show, Switch } from "solid-js"

function View(props: { api: TuiPluginApi }) {
  const [open, setOpen] = createSignal(true)
  const theme = () => props.api.theme.current
  const list = createMemo(() => props.api.state.mcp())
  const on = createMemo(() => list().filter((i) => i.status === "connected").length)
  const bad = createMemo(
    () =>
      list().filter((i) => i.status === "failed" || i.status === "needs_auth" || i.status === "needs_client_registration")
        .length,
  )
  const dot = (s: string) => {
    if (s === "connected") return theme().success
    if (s === "failed" || s === "needs_client_registration") return theme().error
    if (s === "needs_auth") return theme().warning
    return theme().textMuted
  }
  const name = (s: string) => {
    if (s === "connected") return theme().success
    if (s === "disabled") return theme().textMuted
    return theme().text
  }

  return (
    <Show when={list().length > 0}>
      <box>
        <box flexDirection="row" gap={1} onMouseDown={() => list().length > 2 && setOpen((x) => !x)}>
          <Show when={list().length > 2}>
            <text fg={theme().text}>{open() ? "▼" : "▶"}</text>
          </Show>
          <text fg={theme().text}>
            <b>MCP</b>
            <Show when={!open()}>
              <span style={{ fg: theme().textMuted }}>
                {" "}({on()} active{bad() > 0 ? `, ${bad()} error${bad() > 1 ? "s" : ""}` : ""})
              </span>
            </Show>
          </text>
        </box>
        <Show when={list().length <= 2 || open()}>
          <For each={list()}>
            {(item) => (
              <box flexDirection="row" gap={1}>
                <text flexShrink={0} style={{ fg: dot(item.status) }}>
                  •
                </text>
                <text fg={name(item.status)} wrapMode="word">
                  {item.name}{" "}
                  <span style={{ fg: theme().textMuted }}>
                    <Switch fallback={item.status}>
                      <Match when={item.status === "connected"}>Connected</Match>
                      <Match when={item.status === "failed"}>
                        <i>{item.error}</i>
                      </Match>
                      <Match when={item.status === "disabled"}>Disabled</Match>
                      <Match when={item.status === "needs_auth"}>Needs auth</Match>
                      <Match when={item.status === "needs_client_registration"}>Needs client ID</Match>
                    </Switch>
                  </span>
                </text>
              </box>
            )}
          </For>
        </Show>
      </box>
    </Show>
  )
}

const tui: TuiPlugin = async (api) => {
  api.slots.register({ order: 200, slots: { sidebar_content: () => <View api={api} /> } })
}

const plugin: TuiPluginModule & { id: string } = { id: "local.sidebar-mcp-green", tui }
export default plugin
