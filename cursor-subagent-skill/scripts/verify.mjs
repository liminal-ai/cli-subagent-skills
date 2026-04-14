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

async function mustExist(path) {
  try {
    await fs.access(path);
  } catch {
    throw new Error(`Missing required path: ${path}`);
  }
}

async function readVersion(repoRoot) {
  const packageJson = JSON.parse(await fs.readFile(join(repoRoot, "package.json"), "utf8"));
  if (!packageJson.version) {
    throw new Error("package.json is missing version");
  }
  return packageJson.version;
}

async function main() {
  const scriptDir = dirname(fileURLToPath(import.meta.url));
  const repoRoot = resolve(scriptDir, "..");

  const requiredPaths = [
    join(repoRoot, "skills", "cursor-subagent", "SKILL.md"),
    join(repoRoot, "skills", "cursor-subagent", "scripts", "cursor-result"),
    join(repoRoot, "scripts", "build-artifacts.mjs"),
    join(repoRoot, "scripts", "deploy-local.mjs"),
    join(repoRoot, "scripts", "release-local.mjs"),
    join(repoRoot, "scripts", "verify.mjs"),
  ];

  for (const path of requiredPaths) {
    await mustExist(path);
  }

  const helperPath = join(repoRoot, "skills", "cursor-subagent", "scripts", "cursor-result");
  const helpText = run(helperPath, ["--help"], repoRoot);
  if (!helpText.includes("cursor-result")) {
    throw new Error("cursor-result --help output does not include expected usage text");
  }

  run("npm", ["run", "build"], repoRoot, true);

  const version = await readVersion(repoRoot);
  const base = `cursor-subagent-v${version}`;
  const zipPath = join(repoRoot, "dist", `${base}.zip`);
  const skillPath = join(repoRoot, "dist", `${base}.skill`);

  await mustExist(zipPath);
  await mustExist(skillPath);

  const [zipStat, skillStat] = await Promise.all([fs.stat(zipPath), fs.stat(skillPath)]);
  if (zipStat.size !== skillStat.size) {
    throw new Error(`Artifact size mismatch: zip=${zipStat.size}, skill=${skillStat.size}`);
  }

  const zipList = run("unzip", ["-l", zipPath], repoRoot);
  const requiredEntries = [
    "cursor-subagent/SKILL.md",
    "cursor-subagent/scripts/cursor-result",
  ];

  for (const entry of requiredEntries) {
    if (!zipList.includes(entry)) {
      throw new Error(`Missing archive entry: ${entry}`);
    }
  }

  if (zipList.includes("__MACOSX") || zipList.includes(".DS_Store")) {
    throw new Error("Archive contains excluded junk entries (__MACOSX or .DS_Store)");
  }

  console.log("Verify checks passed.");
}

await main();
