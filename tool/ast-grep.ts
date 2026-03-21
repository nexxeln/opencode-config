import { spawn } from "node:child_process";

import { tool } from "@opencode-ai/plugin";

const languages = [
  "typescript",
  "tsx",
  "javascript",
  "python",
  "rust",
  "go",
  "java",
  "c",
  "cpp",
  "csharp",
  "kotlin",
  "swift",
  "ruby",
  "lua",
  "elixir",
  "html",
  "css",
  "json",
  "yaml",
] as const;

function hasCode(error: unknown): error is Error & { code: string } {
  return error instanceof Error && typeof Reflect.get(error, "code") === "string";
}

function run(
  command: string,
  args: string[],
  options: { cwd: string; signal: AbortSignal },
) {
  return new Promise<{
    stdout: string;
    stderr: string;
    exitCode: number | null;
  }>((resolve, reject) => {
    const child = spawn(command, args, {
      cwd: options.cwd,
      signal: options.signal,
      stdio: ["ignore", "pipe", "pipe"],
    });

    let stdout = "";
    let stderr = "";
    let settled = false;

    const finish = (callback: () => void) => {
      if (settled) return;
      settled = true;
      callback();
    };

    child.stdout?.setEncoding("utf8");
    child.stderr?.setEncoding("utf8");

    child.stdout?.on("data", (chunk: string) => {
      stdout += chunk;
    });

    child.stderr?.on("data", (chunk: string) => {
      stderr += chunk;
    });

    child.on("error", (error) => {
      finish(() => reject(error));
    });

    child.on("close", (exitCode) => {
      finish(() => resolve({ stdout, stderr, exitCode }));
    });
  });
}

async function runAstGrep(
  args: string[],
  options: { cwd: string; signal: AbortSignal },
) {
  try {
    return await run("sg", args, options);
  } catch (error) {
    if (hasCode(error) && error.code === "ENOENT") {
      return {
        stdout: "",
        stderr: "ast-grep binary `sg` not found in PATH",
        exitCode: 127,
      };
    }

    if (error instanceof Error && error.name === "AbortError") {
      return {
        stdout: "",
        stderr: "ast-grep command aborted",
        exitCode: 130,
      };
    }

    throw error;
  }
}

export default tool({
  description: `Search or rewrite code using ast-grep's structural AST pattern matching.

Use for code patterns that are hard to match with regex because formatting does not matter.

Metavariables:
- $VAR: matches a single AST node
- $$$VAR: matches zero or more nodes

Examples:
- Search: pattern="console.log($$$ARGS)"
- Search: pattern="async function $NAME($$$PARAMS) { $$$BODY }"
- Rewrite: pattern="console.log($MSG)" rewrite="logger.info($MSG)"`,

  args: {
    action: tool.schema
      .enum(["search", "rewrite"])
      .optional()
      .describe("Operation to run (defaults to search)"),
    pattern: tool.schema.string().describe("AST pattern to match"),
    rewrite: tool.schema
      .string()
      .optional()
      .describe("Replacement pattern for rewrite mode"),
    path: tool.schema
      .string()
      .optional()
      .describe("Path to search or transform (default: current session directory)"),
    lang: tool.schema
      .enum(languages)
      .optional()
      .describe("Language hint (auto-detected if omitted)"),
    json: tool.schema
      .boolean()
      .optional()
      .describe("Return search output as JSON"),
  },

  async execute(args, context) {
    const action = args.action ?? (args.rewrite ? "rewrite" : "search");

    if (action === "rewrite" && !args.rewrite) {
      return "Error: rewrite mode requires a rewrite pattern";
    }

    if (action === "rewrite" && args.json) {
      return "Error: json output is only supported for search mode";
    }

    context.metadata({
      title: action === "rewrite" ? "ast-grep rewrite" : "ast-grep search",
      metadata: {
        action,
        pattern: args.pattern,
        path: args.path ?? ".",
        lang: args.lang ?? "auto",
      },
    });

    const command = ["--pattern", args.pattern];

    if (action === "rewrite") {
      command.push("--rewrite", args.rewrite!, "--update-all");
    }

    if (args.lang) command.push("--lang", args.lang);
    if (action === "search" && args.json) command.push("--json");

    command.push(args.path ?? ".");

    const result = await runAstGrep(command, {
      cwd: context.directory,
      signal: context.abort,
    });

    if (result.exitCode !== 0) {
      return `Error: ${result.stderr.trim() || `sg exited with code ${result.exitCode}`}`;
    }

    const stdout = result.stdout.trim();

    if (stdout) return stdout;
    if (action === "rewrite") return "Rewrite finished.";
    return "No matches found.";
  },
});
