import { spawnSync } from "node:child_process";
import { promises as fs } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

function run(command, args, cwd, inherit = false) {
  const result = spawnSync(command, args, {
    cwd,
    encoding: "utf8",
    stdio: inherit ? "inherit" : "pipe",
  });

  if (result.status !== 0) {
    const details = (result.stderr || result.stdout || "command failed").trim();
    throw new Error(`${command} ${args.join(" ")} failed: ${details}`);
  }

  return (result.stdout || "").trim();
}

async function readVersion(repoRoot) {
  const packageJson = JSON.parse(await fs.readFile(join(repoRoot, "package.json"), "utf8"));
  if (!packageJson.version) {
    throw new Error("package.json is missing version");
  }
  return packageJson.version;
}

async function main() {
  const args = new Set(process.argv.slice(2));
  const allowDirty = args.has("--allow-dirty");
  if (args.size > (allowDirty ? 1 : 0)) {
    throw new Error("Unknown arguments. Supported: --allow-dirty");
  }

  const scriptDir = dirname(fileURLToPath(import.meta.url));
  const repoRoot = resolve(scriptDir, "..");

  run("npm", ["run", "build"], repoRoot, true);

  const status = run("git", ["status", "--porcelain"], repoRoot);
  if (status !== "") {
    if (!allowDirty) {
      throw new Error(
        "Working tree is not clean. Commit/stash changes before release:local, or use --allow-dirty."
      );
    }
    console.warn("Warning: working tree is dirty; continuing due to --allow-dirty.");
  }

  const version = await readVersion(repoRoot);
  const tag = `claude-subagent-v${version}`;
  const existingTag = run("git", ["tag", "--list", tag], repoRoot);

  if (existingTag === "") {
    run("git", ["tag", "-a", tag, "-m", `Release ${tag}`], repoRoot);
    console.log(`Created local annotated tag: ${tag}`);
  } else {
    console.log(`Tag already exists locally: ${tag}`);
  }

  console.log("\nNext manual steps:");
  console.log("1. git push origin <branch>");
  console.log(`2. git push origin ${tag}`);
  console.log(`3. Create GitHub release for ${tag}`);
  console.log("4. Upload dist/*.zip and dist/*.skill");
}

await main();
