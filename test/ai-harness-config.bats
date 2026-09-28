#!/usr/bin/env bats
# shellcheck disable=SC2154

setup() {
  PROJECT_ROOT="$(cd "$(dirname "${BATS_TEST_FILENAME}")/.." >/dev/null 2>&1 && pwd)"
  CODEX_CONFIG="${PROJECT_ROOT}/codex/.codex/config.toml"
  OPENCODE_CONFIG="${PROJECT_ROOT}/opencode/.config/opencode/opencode.json"
  BREWFILE="${PROJECT_ROOT}/homebrew/.config/homebrew/Brewfile"
}

function codex_and_opencode_share_global_agent_guidance { #@test
  cmp "${PROJECT_ROOT}/codex/.codex/AGENTS.md" "${PROJECT_ROOT}/opencode/.config/opencode/AGENTS.md"
}

function ai_harness_configs_define_the_same_required_mcp_servers { #@test
  run python3 - "${CODEX_CONFIG}" "${OPENCODE_CONFIG}" <<'PY'
import json
import pathlib
import re
import sys

codex_text = pathlib.Path(sys.argv[1]).read_text()
opencode = json.loads(pathlib.Path(sys.argv[2]).read_text())
required = {"chrome-devtools", "playwright", "context7", "figma", "deepwiki"}

def codex_section(name):
    match = re.search(rf"^\[mcp_servers\.{re.escape(name)}\]\n(.*?)(?=^\[|\Z)", codex_text, re.MULTILINE | re.DOTALL)
    assert match, f"missing Codex MCP server: {name}"
    return match.group(1)

assert required <= opencode["mcp"].keys()
for name in required:
    codex_section(name)

assert 'args = ["-y", "chrome-devtools-mcp@1.9.0"]' in codex_section("chrome-devtools")
assert opencode["mcp"]["chrome-devtools"]["command"] == ["npx", "-y", "chrome-devtools-mcp@1.9.0"]
assert 'args = ["-y", "@playwright/mcp@0.0.82"]' in codex_section("playwright")
assert opencode["mcp"]["playwright"]["command"] == ["npx", "-y", "@playwright/mcp@0.0.82"]

remote_urls = {
    "context7": "https://mcp.context7.com/mcp",
    "figma": "https://mcp.figma.com/mcp",
    "deepwiki": "https://mcp.deepwiki.com/mcp",
}
for name, url in remote_urls.items():
    assert f'url = "{url}"' in codex_section(name)
    assert opencode["mcp"][name]["url"] == url

assert 'bearer_token_env_var = "CONTEXT7_API_KEY"' in codex_section("context7")
assert opencode["mcp"]["context7"]["headers"]["Authorization"] == "Bearer {env:CONTEXT7_API_KEY}"
assert opencode["model"] == "openai/gpt-6-astra"
assert opencode["permission"] == "allow"
assert opencode["share"] == "disabled"
PY

  [ "${status}" -eq 0 ]
}

function context7_secret_is_referenced_but_not_embedded { #@test
  grep -Fq 'CONTEXT7_API_KEY' "${CODEX_CONFIG}"
  grep -Fq 'CONTEXT7_API_KEY' "${OPENCODE_CONFIG}"
  ! grep -ER 'ctx7sk[-_]' "${PROJECT_ROOT}/codex" "${PROJECT_ROOT}/opencode" "${PROJECT_ROOT}/zsh"
  grep -Fq "\$HOME/.config/m-config/context7.env" "${PROJECT_ROOT}/zsh/.zshrc"
}

function codex_shared_config_excludes_machine_local_state { #@test
  ! grep -E '/Users/|ChatGPT\.app|computer-use|^\[projects\.|^\[desktop|^\[plugins\.' "${CODEX_CONFIG}"
}

function brewfile_installs_concord_discord_client { #@test
  grep -Fq 'brew "concord"' "${BREWFILE}"
}

function brewfile_installs_opencode_v2_not_core_v1 { #@test
  grep -Fq 'tap "anomalyco/tap"' "${BREWFILE}"
  grep -Fq 'brew "opencode-v2"' "${BREWFILE}"
  ! grep -Eq '^[[:space:]]*brew[[:space:]]+"opencode"[[:space:]]*(#|$)' "${BREWFILE}"
}

function retired_apps_are_absent_from_managed_packages { #@test
  local retired
  for retired in claude claude-code discord whatsapp steam; do
    ! grep -Eq "^[[:space:]]*(brew|cask)[[:space:]]+\"${retired}\"" "${BREWFILE}"
  done

  run git -C "${PROJECT_ROOT}" ls-files claude
  [ "${status}" -eq 0 ]
  [ -z "${output}" ]
}
