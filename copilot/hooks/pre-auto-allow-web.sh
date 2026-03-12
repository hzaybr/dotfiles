#!/bin/bash
# PreToolUse hook: Auto-approve web search/fetch operations
# These are read-only and can't modify local files.
jq -n '{
  permissionDecision: "allow",
  permissionDecisionReason: "Web operation auto-approved by hook"
}'
