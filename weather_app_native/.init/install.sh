#!/usr/bin/env bash
set -euo pipefail

# environment step: create workspace, validate Node/npm versions, prepare minimal profile template (non-privileged)
WORKSPACE="/home/kavia/workspace/code-generation/weather-insights-42724-42733/weather_app_native"
# ensure workspace exists (create as root if needed, then ensure user-owned path exists)
sudo mkdir -p "$WORKSPACE" && mkdir -p "$WORKSPACE"

# detect runtimes (non-privileged)
NODE_V="$(command -v node >/dev/null 2>&1 && node --version || echo '')"
NPM_V="$(command -v npm >/dev/null 2>&1 && npm --version || echo '')"
# publish detection to stderr for automation logs
printf 'DETECTED_NODE=%s\nDETECTED_NPM=%s\n' "$NODE_V" "$NPM_V" >/dev/stderr

# required majors
REQUIRED_NODE_MAJOR=18
REQUIRED_NPM_MAJOR=9
NODE_MAJOR=$(echo "$NODE_V" | sed -E 's/^v?([0-9]+).*/\1/' || echo 0)
NPM_MAJOR=$(echo "$NPM_V" | sed -E 's/^([0-9]+).*/\1/' || echo 0)

# validate
if [ "$NODE_MAJOR" -lt "$REQUIRED_NODE_MAJOR" ] || [ "$NPM_MAJOR" -lt "$REQUIRED_NPM_MAJOR" ]; then
  cat >&2 <<'MSG'
ERROR: Node/npm requirement not satisfied (need Node>=18 and npm>=9).
Detected Node and npm versions are printed above.
Remediation: run in a container/image with compatible Node/npm, or install a compatible runtime (for example use nvm to install Node 18+ and ensure npm>=9), then re-run this script.
If you control the image, install a newer Node (official Node 18+ package or NodeSource) or use the preinstalled nodejs/npm from package manager with correct versions.
MSG
  exit 4
fi

# Prepare minimal profile content template in workspace for later privileged remediation.
# Do not write /etc/profile.d directly here to avoid requiring sudo in this step.
PROFILE_TEMPLATE_PATH="$WORKSPACE/.weather_app_native_profile_template.sh"
cat > "$PROFILE_TEMPLATE_PATH" <<'TEMPLATE'
# weather_app_native global environment
# This file is a template. Remediation step will atomically install it to /etc/profile.d/weather_app_native.sh using sudo.
export LANG="en_US.UTF-8"
export NODE_ENV="development"
# ensure /usr/local/bin is on PATH for local tools
export PATH="/usr/local/bin:${PATH}"
TEMPLATE

# ensure template is readable
chmod 0644 "$PROFILE_TEMPLATE_PATH"

# final validation: ensure PATH contains /usr/local/bin in current shell; if not, print warning but do not modify system files here
case ":$PATH:" in
  *":/usr/local/bin:"*) : ;;
  *) printf 'WARNING: /usr/local/bin not in PATH for current shell; remediation step will ensure it is present for future sessions.\n' >/dev/stderr ;;
esac

# success
exit 0
