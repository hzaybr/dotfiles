#!/bin/bash
# Dotfiles installation script
# Creates symbolic links from home directory to dotfiles

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
WORKSPACE_DIR="$HOME/git"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

backup_and_link() {
	local src="$1"
	local dest="$2"

	if [ -L "$dest" ]; then
		# Already a symlink (from previous install), just remove it
		rm "$dest"
	elif [ -e "$dest" ]; then
		# Real file, back it up
		mkdir -p "$BACKUP_DIR"
		log_warn "Backing up existing $dest to $BACKUP_DIR/"
		mv "$dest" "$BACKUP_DIR/"
	fi

	mkdir -p "$(dirname "$dest")"
	ln -sf "$src" "$dest"
	log_info "Linked $dest -> $src"
}

backup_and_copy() {
	local src="$1"
	local dest="$2"

	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mkdir -p "$BACKUP_DIR"
		log_warn "Backing up existing $dest to $BACKUP_DIR/"
		mv "$dest" "$BACKUP_DIR/"
	fi

	mkdir -p "$(dirname "$dest")"
	cp "$src" "$dest"
	log_info "Copied $src -> $dest"
}

# Merge CLAUDE.md + rules/*.md into a single instructions file.
# Usage: merge_instructions <dest>
merge_instructions() {
	local dest="$1"
	local tmp
	tmp=$(mktemp)

	if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
		cat "$DOTFILES_DIR/claude/CLAUDE.md" >>"$tmp"
	fi

	if [ -d "$DOTFILES_DIR/claude/rules" ]; then
		for file in "$DOTFILES_DIR/claude/rules"/*.md; do
			[ -f "$file" ] || continue
			echo "" >>"$tmp"
			echo "---" >>"$tmp"
			echo "" >>"$tmp"
			cat "$file" >>"$tmp"
		done
	fi

	if [ -e "$dest" ] || [ -L "$dest" ]; then
		mkdir -p "$BACKUP_DIR"
		mv "$dest" "$BACKUP_DIR/"
	fi
	mkdir -p "$(dirname "$dest")"
	mv "$tmp" "$dest"
	log_info "Generated $dest from CLAUDE.md + rules/*.md"
}

# Warn for unresolved MCP env placeholders like ${VAR} or $VAR.
warn_missing_mcp_env_vars() {
	local source="$1"
	local missing_vars
	missing_vars=$(
		jq -r '
			(.mcpServers // . // {})
			| to_entries[]
			| (.value.env // {})
			| to_entries[]
			| select(.value | type == "string" and test("^\\$\\{?[A-Za-z_][A-Za-z0-9_]*\\}?$"))
			| (.value | capture("^\\$\\{?(?<name>[A-Za-z_][A-Za-z0-9_]*)\\}?$").name) as $name
			| select((env[$name] // "") == "")
			| $name
		' "$source" | sort -u
	)

	if [ -n "$missing_vars" ]; then
		while IFS= read -r var_name; do
			[ -n "$var_name" ] || continue
			log_warn "MCP env var $var_name is not set; omitting it during sync"
		done <<<"$missing_vars"
	fi
}

# Resolve MCP source JSON into concrete values by replacing ${VAR}/$VAR from shell env.
# Supports target-specific overrides via <target>Args (e.g. codexArgs, geminiArgs),
# which fully replace the base args when syncing for that target.
resolve_mcp_source() {
	local source="$1"
	local resolved="$2"
	local target="${3:-claude}"

	jq --arg target "$target" '
		def resolve_value:
			if type == "string" and test("^\\$\\{?[A-Za-z_][A-Za-z0-9_]*\\}?$") then
				capture("^\\$\\{?(?<name>[A-Za-z_][A-Za-z0-9_]*)\\}?$").name as $name
				| (env[$name] // null)
			else
				.
			end;

		def resolve_env:
			((. // {})
				| to_entries
				| map(
					(.value | resolve_value) as $resolved
					| select($resolved != null)
					| { key: .key, value: $resolved }
				)
				| from_entries);

		($target + "Args") as $override_key |

		{
			mcpServers: (
				(.mcpServers // . // {})
				| with_entries(
					.value = (
						if (.value.url // null) != null then
							{
								type: (.value.type // "http"),
								url: .value.url
							}
						else
							{
								command: .value.command,
								args: (
									if (.value[$override_key] // null) != null
									then .value[$override_key]
									else (.value.args // [])
									end
								),
								env: (.value.env | resolve_env)
							}
						end
					)
				)
			)
		}
	' "$source" >"$resolved"
}

# Sync MCP servers into ~/.claude.json.
sync_claude_mcp() {
	local source="$1"
	local dest="$2"

	if ! command -v jq >/dev/null 2>&1; then
		log_warn "jq not found; skipping Claude MCP sync"
		return
	fi
	if [ ! -f "$source" ]; then
		log_warn "MCP source not found at $source; skipping Claude MCP sync"
		return
	fi

	local resolved
	local tmp
	resolved=$(mktemp)
	tmp=$(mktemp)

	resolve_mcp_source "$source" "$resolved" claude

	if [ -f "$dest" ]; then
		jq --slurpfile mcp "$resolved" '.mcpServers = ($mcp[0].mcpServers // {})' "$dest" >"$tmp"
	else
		jq -n --slurpfile mcp "$resolved" '{ mcpServers: ($mcp[0].mcpServers // {}) }' >"$tmp"
	fi

	mv "$tmp" "$dest"
	rm -f "$resolved"
	log_info "Synced Claude MCP servers to $dest"
}

# Sync MCP servers into a managed block inside ~/.codex/config.toml.
sync_codex_mcp() {
	local source="$1"
	local dest="$2"
	local begin_marker="# BEGIN MCP SERVERS (managed by dotfiles)"
	local end_marker="# END MCP SERVERS (managed by dotfiles)"

	if ! command -v jq >/dev/null 2>&1; then
		log_warn "jq not found; skipping Codex MCP sync"
		return
	fi
	if [ ! -f "$source" ]; then
		log_warn "MCP source not found at $source; skipping Codex MCP sync"
		return
	fi

	local resolved
	local base_tmp
	local block_tmp
	local output_tmp
	resolved=$(mktemp)
	base_tmp=$(mktemp)
	block_tmp=$(mktemp)
	output_tmp=$(mktemp)

	resolve_mcp_source "$source" "$resolved" codex

	if [ -f "$dest" ]; then
		# Self-healing: strip the managed marker lines wherever they are (Codex
		# rewrites config.toml at runtime and may drop one of them), and strip
		# every [mcp_servers.*] table since all MCP servers are managed by
		# mcp-servers.json. This is a no-op on a freshly copied base config.
		awk -v begin="$begin_marker" -v end="$end_marker" '
			$0 == begin { next }
			$0 == end { next }
			/^\[mcp_servers/ { inmcp=1; next }
			/^\[/ { inmcp=0 }
			inmcp { next }
			{ print }
		' "$dest" >"$base_tmp"
	else
		: >"$base_tmp"
	fi

	jq -r '
		(.mcpServers // {})
		| to_entries[]
		| select((.value.command // "") != "" or (.value.url // "") != "")
		| "[mcp_servers.\(.key | @json)]",
			(if (.value.url // "") != "" then
				"url = \(.value.url | @json)"
			else
				"command = \(.value.command | @json)",
				(if ((.value.args // []) | length) > 0 then "args = \((.value.args // []) | @json)" else empty end),
				(if ((.value.env // {}) | length) > 0 then
					"env = { " + ((.value.env // {}) | to_entries | map((.key | @json) + " = " + (.value | @json)) | join(", ")) + " }"
				else empty end)
			end),
			""
	' "$resolved" >"$block_tmp"

	cat "$base_tmp" >"$output_tmp"
	if [ -s "$block_tmp" ]; then
		if [ -s "$output_tmp" ]; then
			echo "" >>"$output_tmp"
		fi
		echo "$begin_marker" >>"$output_tmp"
		cat "$block_tmp" >>"$output_tmp"
		echo "$end_marker" >>"$output_tmp"
	fi

	mkdir -p "$(dirname "$dest")"
	mv "$output_tmp" "$dest"
	rm -f "$resolved" "$base_tmp" "$block_tmp"
	log_info "Synced Codex MCP servers to $dest"
}

# Remove broken symlinks (and resulting empty subdirs) from managed directories.
# Prevents drift when a source file under claude/ is deleted or renamed.
cleanup_broken_symlinks() {
	for dir in "$@"; do
		[ -d "$dir" ] || continue
		while IFS= read -r link; do
			[ -n "$link" ] || continue
			/bin/rm -f "$link"
			log_info "Removed orphan symlink $link"
		done < <(find "$dir" -type l ! -exec test -e {} \; -print 2>/dev/null)
		find "$dir" -mindepth 1 -type d -empty -delete 2>/dev/null
	done
}

echo "=========================================="
echo "        Dotfiles Installation Script"
echo "=========================================="
echo ""

# Zsh
if [ -f "$DOTFILES_DIR/zsh/.zshrc" ]; then
	backup_and_link "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
fi
if [ -f "$DOTFILES_DIR/zsh/.zimrc" ]; then
	backup_and_link "$DOTFILES_DIR/zsh/.zimrc" "$HOME/.zimrc"
fi
if [ -f "$DOTFILES_DIR/zsh/.p10k.zsh" ]; then
	backup_and_link "$DOTFILES_DIR/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
fi

# Vim
if [ -f "$DOTFILES_DIR/vim/.vimrc" ]; then
	backup_and_link "$DOTFILES_DIR/vim/.vimrc" "$HOME/.vimrc"
fi
if [ -f "$DOTFILES_DIR/vim/coc-settings.json" ]; then
	backup_and_link "$DOTFILES_DIR/vim/coc-settings.json" "$HOME/.vim/coc-settings.json"
fi

# Tmux
if [ -f "$DOTFILES_DIR/tmux/.tmux.conf" ]; then
	backup_and_link "$DOTFILES_DIR/tmux/.tmux.conf" "$HOME/.tmux.conf"
fi

# Git
if [ -f "$DOTFILES_DIR/git/.gitconfig" ]; then
	backup_and_link "$DOTFILES_DIR/git/.gitconfig" "$HOME/.gitconfig"
fi
if [ -f "$DOTFILES_DIR/git/ignore" ]; then
	backup_and_link "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
fi

# GitHub CLI
if [ -f "$DOTFILES_DIR/gh/config.yml" ]; then
	backup_and_link "$DOTFILES_DIR/gh/config.yml" "$HOME/.config/gh/config.yml"
fi

# Hammerspoon (macOS only)
if [ "$(uname)" = "Darwin" ] && [ -f "$DOTFILES_DIR/hammerspoon/init.lua" ]; then
	backup_and_link "$DOTFILES_DIR/hammerspoon/init.lua" "$HOME/.hammerspoon/init.lua"
fi

# Ghostty
if [ -f "$DOTFILES_DIR/ghostty/config" ]; then
	if [ "$(uname)" = "Darwin" ]; then
		GHOSTTY_DIR="$HOME/Library/Application Support/com.mitchellh.ghostty"
	else
		GHOSTTY_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/ghostty"
	fi
	backup_and_link "$DOTFILES_DIR/ghostty/config" "$GHOSTTY_DIR/config"
fi

# Neovim
if [ -d "$DOTFILES_DIR/nvim" ]; then
	backup_and_link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"
fi

# Claude Code
CLAUDE_DIR="$HOME/.claude"
if [ -d "$DOTFILES_DIR/claude" ]; then
	# CLAUDE.md
	if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
		backup_and_link "$DOTFILES_DIR/claude/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md"
	fi

	# settings.json
	if [ -f "$DOTFILES_DIR/claude/settings.json" ]; then
		backup_and_link "$DOTFILES_DIR/claude/settings.json" "$CLAUDE_DIR/settings.json"
	fi

	# statusline.sh
	if [ -f "$DOTFILES_DIR/claude/statusline.sh" ]; then
		backup_and_link "$DOTFILES_DIR/claude/statusline.sh" "$CLAUDE_DIR/statusline.sh"
	fi

	# rules
	if [ -d "$DOTFILES_DIR/claude/rules" ]; then
		mkdir -p "$CLAUDE_DIR/rules"
		for file in "$DOTFILES_DIR/claude/rules"/*.md; do
			[ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/rules/$(basename "$file")"
		done
	fi

	# commands
	if [ -d "$DOTFILES_DIR/claude/commands" ]; then
		mkdir -p "$CLAUDE_DIR/commands"
		for file in "$DOTFILES_DIR/claude/commands"/*.md; do
			[ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/commands/$(basename "$file")"
		done
	fi

	# skills
	if [ -d "$DOTFILES_DIR/claude/skills" ]; then
		for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
			skill_name=$(basename "$skill_dir")
			mkdir -p "$CLAUDE_DIR/skills/$skill_name"
			if [ -f "${skill_dir}SKILL.md" ]; then
				backup_and_link "${skill_dir}SKILL.md" "$CLAUDE_DIR/skills/$skill_name/SKILL.md"
			fi
		done
	fi

	# agents
	if [ -d "$DOTFILES_DIR/claude/agents" ]; then
		mkdir -p "$CLAUDE_DIR/agents"
		for file in "$DOTFILES_DIR/claude/agents"/*.md; do
			[ -f "$file" ] && backup_and_link "$file" "$CLAUDE_DIR/agents/$(basename "$file")"
		done
	fi
fi

# Copilot CLI (symlinks to Claude source of truth)
COPILOT_DIR="$HOME/.copilot"
if [ -d "$DOTFILES_DIR/claude" ]; then
	mkdir -p "$COPILOT_DIR/rules" "$COPILOT_DIR/skills"

	# Core instructions
	if [ -f "$DOTFILES_DIR/claude/CLAUDE.md" ]; then
		backup_and_link "$DOTFILES_DIR/claude/CLAUDE.md" "$COPILOT_DIR/copilot-instructions.md"
	fi

	# Rules (.md -> .instructions.md)
	if [ -d "$DOTFILES_DIR/claude/rules" ]; then
		for file in "$DOTFILES_DIR/claude/rules"/*.md; do
			[ -f "$file" ] || continue
			name="$(basename "$file" .md)"
			backup_and_link "$file" "$COPILOT_DIR/rules/$name.instructions.md"
		done
	fi

	# Skills (SKILL.md -> skill-name.instructions.md)
	if [ -d "$DOTFILES_DIR/claude/skills" ]; then
		for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
			skill_name=$(basename "$skill_dir")
			if [ -f "${skill_dir}SKILL.md" ]; then
				backup_and_link "${skill_dir}SKILL.md" "$COPILOT_DIR/skills/$skill_name.instructions.md"
			fi
		done
	fi

	# Agents (merge multiple files into single AGENTS.md)
	if [ -d "$DOTFILES_DIR/claude/agents" ]; then
		agents_tmp=$(mktemp)
		first=true
		for file in "$DOTFILES_DIR/claude/agents"/*.md; do
			[ -f "$file" ] || continue
			if [ "$first" = true ]; then
				first=false
			else
				echo "" >>"$agents_tmp"
				echo "---" >>"$agents_tmp"
				echo "" >>"$agents_tmp"
			fi
			cat "$file" >>"$agents_tmp"
		done
		if [ -e "$COPILOT_DIR/AGENTS.md" ] || [ -L "$COPILOT_DIR/AGENTS.md" ]; then
			mkdir -p "$BACKUP_DIR"
			mv "$COPILOT_DIR/AGENTS.md" "$BACKUP_DIR/"
		fi
		mv "$agents_tmp" "$COPILOT_DIR/AGENTS.md"
		log_info "Generated $COPILOT_DIR/AGENTS.md from agents/*.md"
	fi
fi

# Codex CLI
CODEX_DIR="$HOME/.codex"
CODEX_SOURCE_DIR="$DOTFILES_DIR/codex"
CODEX_SKILLS_DIR="$HOME/.codex/skills"
MCP_SOURCE="$DOTFILES_DIR/claude/mcp-servers.json"
if [ -d "$DOTFILES_DIR/claude" ] || [ -d "$CODEX_SOURCE_DIR" ]; then
	mkdir -p "$CODEX_DIR" "$CODEX_SKILLS_DIR"

	# AGENTS.md
	if [ -f "$CODEX_SOURCE_DIR/AGENTS.md" ]; then
		backup_and_link "$CODEX_SOURCE_DIR/AGENTS.md" "$CODEX_DIR/AGENTS.md"
	elif [ -d "$DOTFILES_DIR/claude" ]; then
		# Backward-compatible fallback for older checkouts without codex/AGENTS.md.
		merge_instructions "$CODEX_DIR/AGENTS.md"
	fi

	# Base config is copied instead of symlinked so MCP env resolution never mutates the repo.
	if [ -f "$CODEX_SOURCE_DIR/config.toml" ]; then
		backup_and_copy "$CODEX_SOURCE_DIR/config.toml" "$CODEX_DIR/config.toml"
	fi

	# Skills (~/.codex/skills/<name>/ -> claude/skills/<name>/)
	if [ -d "$DOTFILES_DIR/claude/skills" ]; then
		for skill_dir in "$DOTFILES_DIR/claude/skills"/*/; do
			skill_name=$(basename "$skill_dir")
			backup_and_link "${skill_dir%/}" "$CODEX_SKILLS_DIR/$skill_name"
		done
	fi

	# MCP servers (repo source -> Claude + Codex)
	if [ -f "$MCP_SOURCE" ]; then
		if command -v jq >/dev/null 2>&1; then
			warn_missing_mcp_env_vars "$MCP_SOURCE"
		fi
		sync_claude_mcp "$MCP_SOURCE" "$HOME/.claude.json"
		sync_codex_mcp "$MCP_SOURCE" "$CODEX_DIR/config.toml"
	fi
fi

# Workspace config (~/git/)
if [ -d "$DOTFILES_DIR/claude-workspace" ] && [ -d "$WORKSPACE_DIR" ]; then
	# Claude workspace CLAUDE.md
	if [ -f "$DOTFILES_DIR/claude-workspace/CLAUDE.md" ]; then
		backup_and_link "$DOTFILES_DIR/claude-workspace/CLAUDE.md" "$WORKSPACE_DIR/CLAUDE.md"
	fi

	# Copilot workspace instructions (symlink to same CLAUDE.md)
	mkdir -p "$WORKSPACE_DIR/.copilot"
	backup_and_link "$DOTFILES_DIR/claude-workspace/CLAUDE.md" "$WORKSPACE_DIR/.copilot/copilot-instructions.md"
fi

cleanup_broken_symlinks \
	"$HOME/.claude/commands" \
	"$HOME/.claude/agents" \
	"$HOME/.claude/rules" \
	"$HOME/.claude/skills" \
	"$HOME/.codex/skills" \
	"$HOME/.agents/skills" \
	"$HOME/.copilot/skills" \
	"$HOME/.copilot/rules"

echo ""
echo "=========================================="
log_info "Installation complete!"
if [ -d "$BACKUP_DIR" ]; then
	log_warn "Backups saved to: $BACKUP_DIR"
fi
echo "=========================================="
