#!/bin/bash
# PreToolUse hook: Auto-approve read-only operations (Read, Glob, Grep)
# These tools can't modify files, so no need to prompt every time.
jq -n '{
  hookSpecificOutput: {
    hookEventName: "PreToolUse",
    permissionDecision: "allow",
    permissionDecisionReason: "Read-only operation auto-approved by hook"
  }
}'
