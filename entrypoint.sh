#!/bin/bash
set -e

# Configure git identity inside container if not set
git config --global user.name "${GIT_USER_NAME:-tkogut}"
git config --global user.email "${GIT_USER_EMAIL:-tkogut9@gmail.com}"
git config --global init.defaultBranch "${GIT_DEFAULT_BRANCH:-master}"
git config --global --add safe.directory "*"

# Ensure Claude Code session & credential persistence
mkdir -p /root/.claude
if [ -f "/root/.claude.json" ] && [ ! -L "/root/.claude.json" ]; then
    mv /root/.claude.json /root/.claude/.claude.json
fi
if [ -f "/root/.claude/.claude.json" ] || [ ! -e "/root/.claude.json" ]; then
    ln -sf /root/.claude/.claude.json /root/.claude.json
fi

# Patch Cezar provider-auth for pi model parsing (pi writes list-models to stderr)
AUTH_JS="/usr/local/lib/node_modules/@open-mercato/cezar/dist/core/provider-auth.js"
if [ -f "$AUTH_JS" ]; then
    python3 -c "
with open('$AUTH_JS', 'r') as f:
    c = f.read()
target = 'const lines = normalizedLines(result.stdout);'
replacement = 'const lines = normalizedLines(result.stdout, result.stderr);'
if target in c:
    with open('$AUTH_JS', 'w') as f:
        f.write(c.replace(target, replacement))
"
fi

# Patch Cezar pi-runner to verify session exists before passing --session
RUNNER_JS="/usr/local/lib/node_modules/@open-mercato/cezar/dist/core/pi-runner.js"
if [ -f "$RUNNER_JS" ]; then
    python3 -c "
with open('$RUNNER_JS', 'r') as f:
    c = f.read()

helper = '''
import { existsSync as fsExists, readdirSync as fsReaddir } from 'node:fs';
import { homedir as osHomedir } from 'node:os';
import { join as pathJoin } from 'node:path';

function piSessionExists(sessionId) {
    if (!sessionId) return false;
    try {
        const base = pathJoin(osHomedir(), '.pi', 'agent', 'sessions');
        if (!fsExists(base)) return false;
        const stack = [base];
        while (stack.length > 0) {
            const cur = stack.pop();
            const entries = fsReaddir(cur, { withFileTypes: true });
            for (const entry of entries) {
                if (entry.isDirectory()) {
                    stack.push(pathJoin(cur, entry.name));
                } else if (entry.isFile() && entry.name.includes(sessionId)) {
                    return true;
                }
            }
        }
    } catch {
        return false;
    }
    return false;
}
'''
if 'function piSessionExists' not in c:
    c = helper + c

old1 = \"if (spec.sessionId)\\n        args.push(spec.resume ? '--session' : '--session-id', spec.sessionId);\"
old2 = \"if (spec.resume && spec.sessionId)\\n        args.push('--session', spec.sessionId);\"
replacement = \"if (spec.resume && spec.sessionId && piSessionExists(spec.sessionId))\\n        args.push('--session', spec.sessionId);\"

if old1 in c:
    c = c.replace(old1, replacement)
elif old2 in c:
    c = c.replace(old2, replacement)

with open('$RUNNER_JS', 'w') as f:
    f.write(c)
"
fi

# Patch Cezar pi-runner & pi-ui-mapper for agent_end RPC event
for P in /usr/local/lib/node_modules/@open-mercato/cezar/dist/core/pi-runner.js /usr/local/lib/node_modules/@open-mercato/cezar/dist/core/pi-ui-mapper.js; do
    if [ -f "$P" ]; then
        python3 -c "
import sys
p = sys.argv[1]
with open(p, 'r') as f:
    fc = f.read()
fc = fc.replace(\"value.type === 'agent_settled'\", \"(value.type === 'agent_settled' || value.type === 'agent_end')\")
fc = fc.replace(\"case 'agent_settled':\", \"case 'agent_settled':\\n        case 'agent_end':\")
with open(p, 'w') as f:
    f.write(fc)
" "$P"
    fi
done

# If workspace is not a git repository, initialize it
if [ ! -d "/workspace/.git" ]; then
    echo "📁 Inicjalizacja repozytorium git w /workspace..."
    cd /workspace
    git init
    echo "# Cezar Swarm Workspace" > README.md
    git add README.md
    git commit -m "chore: initialize cezar workspace"
fi

# Set deepseek-v4.1-flash as default model across all projects in pi
mkdir -p /root/.pi/agent
python3 -c "
import json, os

settings_path = '/root/.pi/agent/settings.json'
data = {}
if os.path.exists(settings_path):
    try:
        with open(settings_path, 'r') as f:
            data = json.load(f)
    except Exception:
        data = {}

data['defaultProvider'] = 'openrouter'
data['defaultModel'] = 'deepseek/deepseek-v4.1-flash'

with open(settings_path, 'w') as f:
    json.dump(data, f, indent=2)
"

# Patch Cezar web frontend for pi DeepSeek models (default: deepseek-v4.1-flash)
for F in /usr/local/lib/node_modules/@open-mercato/cezar/web/dist/assets/new-task-form-*.js; do
    if [ -f "$F" ]; then
        python3 -c "
import sys
p = sys.argv[1]
with open(p, 'r') as f:
    fc = f.read()
target = 'pi:[{id:\`\`,label:\`auto\`,desc:\`Use your pi default model\`},'
old_rep = 'pi:[{id:\`\`,label:\`auto\`,desc:\`Use your pi default model\`},{id:\`openrouter/deepseek/deepseek-v4-flash-0731:free\`,label:\`DeepSeek: DeepSeek V4 Flash 0731 (free)\`,desc:\`via OpenRouter (free)\`},{id:\`openrouter/deepseek/deepseek-v4-flash-0731\`,label:\`DeepSeek: DeepSeek V4 Flash 0731\`,desc:\`via OpenRouter\`},{id:\`openrouter/deepseek/deepseek-v4.1-flash\`,label:\`DeepSeek: DeepSeek V4.1 Flash\`,desc:\`via OpenRouter\`},'
replacement = 'pi:[{id:\`openrouter/deepseek/deepseek-v4.1-flash\`,label:\`DeepSeek: DeepSeek V4.1 Flash (default)\`,desc:\`via OpenRouter (multimodal vision)\`},{id:\`\`,label:\`auto (DeepSeek V4.1 Flash)\`,desc:\`Use pi default (DeepSeek V4.1 Flash)\`},{id:\`openrouter/deepseek/deepseek-v4-flash-0731:free\`,label:\`DeepSeek: DeepSeek V4 Flash 0731 (free)\`,desc:\`via OpenRouter (free)\`},{id:\`openrouter/deepseek/deepseek-v4-flash-0731\`,label:\`DeepSeek: DeepSeek V4 Flash 0731\`,desc:\`via OpenRouter\`},'
if old_rep in fc:
    fc = fc.replace(old_rep, replacement, 1)
elif target in fc:
    fc = fc.replace(target, replacement, 1)
with open(p, 'w') as f:
    f.write(fc)
" "$F"
    fi
done

# Cache-busting and static-ui header fix for Cezar frontend
python3 - << 'PYEOF'
import glob, os

web_dir = "/usr/local/lib/node_modules/@open-mercato/cezar/web/dist"
assets_dir = os.path.join(web_dir, "assets")

# Disable immutable caching in static-ui.js
static_ui = "/usr/local/lib/node_modules/@open-mercato/cezar/dist/server/static-ui.js"
if os.path.exists(static_ui):
    with open(static_ui, "r") as f:
        sc = f.read()
    sc = sc.replace("public, max-age=31536000, immutable", "no-cache, must-revalidate")
    with open(static_ui, "w") as f:
        f.write(sc)

# Find current new-task-form chunk and index chunk
old_task = "new-task-form-D5rySSrd.js"
new_task = "new-task-form-v41flash.js"
old_idx = "index-BjtXXvNw.js"
new_idx = "index-v41flash.js"

if os.path.exists(os.path.join(assets_dir, old_task)):
    with open(os.path.join(assets_dir, old_task), "r") as f:
        content = f.read()
    with open(os.path.join(assets_dir, new_task), "w") as f:
        f.write(content)

if os.path.exists(os.path.join(assets_dir, old_idx)):
    with open(os.path.join(assets_dir, old_idx), "r") as f:
        content = f.read()
    with open(os.path.join(assets_dir, new_idx), "w") as f:
        f.write(content)

for fpath in glob.glob(os.path.join(assets_dir, "*.js")):
    with open(fpath, "r") as f:
        fc = f.read()
    mod = False
    for ot in [old_task, "new-task-form-v4flash.js"]:
        if ot in fc and fpath != os.path.join(assets_dir, new_task):
            fc = fc.replace(ot, new_task)
            mod = True
    for oi in [old_idx, "index-v4flash.js"]:
        if oi in fc and fpath != os.path.join(assets_dir, new_idx):
            fc = fc.replace(oi, new_idx)
            mod = True
    if mod:
        with open(fpath, "w") as f:
            f.write(fc)

index_html = os.path.join(web_dir, "index.html")
if os.path.exists(index_html):
    with open(index_html, "r") as f:
        hc = f.read()
    for ot in [old_task, "new-task-form-v4flash.js"]:
        hc = hc.replace(ot, new_task)
    for oi in [old_idx, "index-v4flash.js"]:
        hc = hc.replace(oi, new_idx)
    with open(index_html, "w") as f:
        f.write(hc)
PYEOF

cd /workspace

echo "🚀 Uruchamianie Cezar Cockpit na porcie 4321..."
exec cezar --bind-host 0.0.0.0 --port 4321 --no-open
