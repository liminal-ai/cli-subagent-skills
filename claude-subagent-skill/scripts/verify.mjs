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
    join(repoRoot, "skills", "claude-subagent", "SKILL.md"),
    join(repoRoot, "skills", "claude-subagent", "scripts", "claude-result"),
    join(repoRoot, "scripts", "build-artifacts.mjs"),
    join(repoRoot, "scripts", "deploy-local.mjs"),
    join(repoRoot, "scripts", "release-local.mjs"),
    join(repoRoot, "scripts", "verify.mjs"),
  ];

  for (const path of requiredPaths) {
    await mustExist(path);
  }

  const helperPath = join(repoRoot, "skills", "claude-subagent", "scripts", "claude-result");
  const helpText = run(helperPath, ["--help"], repoRoot);
  if (!helpText.includes("claude-result")) {
    throw new Error("claude-result --help output does not include expected usage text");
  }

  run("npm", ["run", "build"], repoRoot, true);

  const version = await readVersion(repoRoot);
  const base = `claude-subagent-v${version}`;
  const zipPath = join(repoRoot, "dist", `${base}.zip`);
  const distSkillDir = join(repoRoot, "dist", "claude-subagent");
  const legacySkillPath = join(repoRoot, "dist", `${base}.skill`);

  await mustExist(zipPath);
  await mustExist(distSkillDir);
  await mustExist(join(distSkillDir, "SKILL.md"));
  await mustExist(join(distSkillDir, "scripts", "claude-result"));

  try {
    await fs.access(legacySkillPath);
    throw new Error(`Legacy .skill artifact should not exist: ${legacySkillPath}`);
  } catch (error) {
    if (error instanceof Error && error.message.includes("should not exist")) {
      throw error;
    }
  }

  const zipList = run("unzip", ["-l", zipPath], repoRoot);
  const requiredEntries = [
    "claude-subagent/SKILL.md",
    "claude-subagent/scripts/claude-result",
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
