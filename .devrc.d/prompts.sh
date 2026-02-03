#!/bin/bash

# ========================================
# PROMPT MODULE - AI Agent Helper Functions
# ========================================
# All functions in this module start with 'prompt_' prefix
# 
# ALIAS MAPPINGS (underscore removal pattern):
# Function Name       →    Alias Name
# ---------------           ------------
# prompt_init        →    promptinit
# prompt_project     →    promptproject
# prompt_agent       →    promptagent
# prompt_context     →    promptcontext
#
# Pattern: Remove underscores, convert to lowercase
# Every function must have corresponding alias in ALIAS file
# ========================================

prompt_init() {
    cat <<'EOF'
Read global rules, agents, and skills first. These have highest priority.
Read markdown files in the project root to learn the project context only.
Read rules, agents, and skills in the current folder.

If any current-folder item conflicts with a global item, stop and report.
Otherwise, follow global items and use current-folder items only to add details.
Say "Done." once finished.
EOF
}

prompt_project() {
    cat <<'EOF'
Project Context Analysis:
1. Identify project type (web, mobile, desktop, CLI, library)
2. Check for package.json, requirements.txt, Cargo.toml, etc.
3. Look for framework-specific patterns
4. Identify build tools and dependency managers
5. Determine testing frameworks in use
EOF
}

prompt_agent() {
    cat <<'EOF'
Agent Configuration:
1. Review available agents in current project
2. Check agent YAML frontmatter requirements
3. Verify tool permissions for each agent
4. Validate agent descriptions and triggers
5. Test agent integration with current workflow
EOF
}

prompt_context() {
    cat <<'EOF'
Current Working Context:
- Working Directory: $(pwd)
- Git Branch: $(git branch --show-current 2>/dev/null || echo "Not in git repo")
- Remote: $(git remote get-url origin 2>/dev/null || echo "No remote")
- Available Agents: $(find . -name "*.md" -type f | grep -i agent | wc -l) agent files found
EOF
}