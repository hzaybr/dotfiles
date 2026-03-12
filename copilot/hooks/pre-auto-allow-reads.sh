#!/bin/bash
# PreToolUse hook: Auto-approve read-only operations
# These tools can't modify files, so no need to prompt every time.
jq -n '{
  permissionDecision: "allow",
  permissionDecisionReason: "Read-only operation auto-approved by hook"
}'
