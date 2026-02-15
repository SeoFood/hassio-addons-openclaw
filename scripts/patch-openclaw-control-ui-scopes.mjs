import { readdirSync, readFileSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const distDir = "/usr/local/lib/node_modules/openclaw/dist";
const files = readdirSync(distDir).filter(
  (name) => name.startsWith("gateway-cli-") && name.endsWith(".js"),
);

const blockPattern =
  /([ \t]*)if \(!device\) \{\n[ \t]*if \(scopes\.length > 0\) \{\n[ \t]*scopes = \[\];\n[ \t]*connectParams\.scopes = scopes;\n[ \t]*\}\n[ \t]*const canSkipDevice = sharedAuthOk;/;

let patched = 0;
let alreadyPatched = 0;

for (const file of files) {
  const fullPath = join(distDir, file);
  const source = readFileSync(fullPath, "utf8");

  if (source.includes("preserveScopesForInsecureControlUi")) {
    alreadyPatched += 1;
    continue;
  }

  if (!blockPattern.test(source)) {
    continue;
  }

  const next = source.replace(blockPattern, (_match, indent) => {
    return (
      `${indent}if (!device) {\n` +
      `${indent}\tconst preserveScopesForInsecureControlUi = isControlUi && allowControlUiBypass && sharedAuthOk;\n` +
      `${indent}\tif (!preserveScopesForInsecureControlUi && scopes.length > 0) {\n` +
      `${indent}\t\tscopes = [];\n` +
      `${indent}\t\tconnectParams.scopes = scopes;\n` +
      `${indent}\t}\n` +
      `${indent}\tconst canSkipDevice = sharedAuthOk;`
    );
  });

  writeFileSync(fullPath, next, "utf8");
  patched += 1;
}

if (patched === 0 && alreadyPatched === 0) {
  throw new Error(
    "Could not patch OpenClaw gateway scope block. Upstream dist layout changed.",
  );
}

console.log(`patched=${patched} already_patched=${alreadyPatched}`);
