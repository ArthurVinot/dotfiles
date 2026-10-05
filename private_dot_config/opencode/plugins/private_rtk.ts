import type { Plugin as V1Plugin } from "@opencode-ai/plugin"
import type { Plugin } from "@opencode/plugin"
import { execFile } from "node:child_process"

// RTK OpenCode plugin — rewrites commands to use rtk for token savings.
// Requires: rtk >= 0.23.0 in PATH.
//
// This is a thin delegating plugin: all rewrite logic lives in `rtk rewrite`,
// which is the single source of truth (src/discover/registry.rs).
// To add or change rewrite rules, edit the Rust registry — not this file.
//
// Local V2 port until upstream ships one (rtk-ai/rtk#3898, #4187).
// Exposes both entrypoints: V2 calls setup(), V1 (>= 1.18.29) calls server().

// Resolves stdout regardless of exit code (`rtk rewrite` exits non-zero even
// on success); undefined only when rtk could not be spawned.
function run(args: string[]): Promise<string | undefined> {
  return new Promise((resolve) => {
    execFile("rtk", args, { timeout: 5000 }, (error, stdout) => {
      if (error && typeof error.code !== "number") return resolve(undefined)
      resolve(String(stdout).trim())
    })
  })
}

async function available(): Promise<boolean> {
  if ((await run(["--version"])) !== undefined) return true
  console.warn("[rtk] rtk binary not found in PATH — plugin disabled")
  return false
}

// Rewrites args.command in place when rtk has a rewrite for it.
async function rewrite(tool: unknown, args: unknown) {
  const name = String(tool ?? "").toLowerCase()
  if (name !== "bash" && name !== "shell") return
  if (!args || typeof args !== "object") return

  const command = (args as Record<string, unknown>).command
  if (typeof command !== "string" || !command) return

  const rewritten = await run(["rewrite", command])
  if (rewritten && rewritten !== command) {
    ;(args as Record<string, unknown>).command = rewritten
  }
}

const v2: Plugin = {
  id: "rtk",
  async setup(ctx) {
    if (!(await available())) return
    await ctx.tool.hook("execute.before", (event) => rewrite(event.tool, event.input))
  },
}

const server: V1Plugin = async () => {
  if (!(await available())) return {}
  return {
    "tool.execute.before": async (input, output) => rewrite(input?.tool, output?.args),
  }
}

export default { ...v2, server }
