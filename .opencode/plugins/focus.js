// Focus plugin for OpenCode
// Injects Focus skill content into system prompt and registers skills directory

const fs = require("fs");
const path = require("path");

async function FocusPlugin({ config }) {
  const pluginRoot = path.resolve(__dirname, "../..");
  const skillsDir = path.join(pluginRoot, "skills");
  const skillFile = path.join(skillsDir, "focus", "SKILL.md");

  // Register skills directory
  const currentConfig = config.get();
  const skillsPaths = currentConfig.skills?.paths || [];
  if (!skillsPaths.includes(skillsDir)) {
    config.set({
      ...currentConfig,
      skills: {
        ...currentConfig.skills,
        paths: [...skillsPaths, skillsDir],
      },
    });
  }

  return {
    name: "focus",
    version: "1.0.0",

    hooks: {
      "system-prompt": async ({ prompt }) => {
        // Read SKILL.md and extract body (skip YAML frontmatter)
        if (!fs.existsSync(skillFile)) return { prompt };

        const content = fs.readFileSync(skillFile, "utf-8");
        const parts = content.split("---");
        const body = parts.length >= 3 ? parts.slice(2).join("---").trim() : content;

        // Check for active plan and memory
        let context = "";
        const memoryFile = path.join(process.cwd(), ".focus", "memory.md");
        const planFile = path.join(process.cwd(), ".focus", "plan.md");

        if (fs.existsSync(memoryFile)) {
          const memory = fs.readFileSync(memoryFile, "utf-8");
          const lastSession = memory.match(/## Last Session[\s\S]*?(?=## |$)/);
          if (lastSession) {
            context += "\n\n=== Session Memory ===\n" + lastSession[0].trim();
          }
        }
        if (fs.existsSync(planFile)) {
          const plan = fs.readFileSync(planFile, "utf-8");
          const header = plan.split("\n").slice(0, 15).join("\n");
          context += "\n\n=== Active Plan ===\n" + header;
        }

        return {
          prompt: prompt + "\n\n" + body + context,
        };
      },
    },
  };
}

module.exports = FocusPlugin;
