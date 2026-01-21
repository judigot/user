# Agent Shell Compatibility Documentation

## Function Wrappers (Recommended)
```bash
# Works in all shells without special handling
promptinit() { prompt_init; }
promptproject() { prompt_project; }
promptagent() { prompt_agent; }
promptcontext() { prompt_context; }
```

## Simple Alias Loading (Universal)
```bash
# Direct alias calls work in any shell environment
alias hi=helloWorld  # Simple and reliable
alias ai_status="git status -sb"
```

## Usage Examples
```bash
# Works universally
promptinit              # Calls prompt_init() function

# Requires eval only in non-interactive shells
eval "ai_status"          # Works everywhere
```

## Key Principles

### Function Wrappers for Critical Functions
For frequently used functions (especially those agents will call), prefer function wrappers over traditional aliases:

- **Universal compatibility**: Works in interactive, non-interactive, and CI/CD shells
- **No shell detection needed**: Functions work regardless of shell features
- **Zero dependencies**: No reliance on `shopt -s expand_aliases` or interactive mode

### Simple Aliases
Traditional aliases work directly in interactive shells but require `eval` in non-interactive shells.

## Implementation Guidelines

1. **Function Wrappers First**: Start with function wrappers for critical agent functions
2. **Direct Access Preferred**: Function names should be directly callable (no `eval` needed)
3. **Clear Documentation**: Document loading requirements in function comments
4. **Backward Compatible**: Maintain existing workflows while improving compatibility

**Key Principle**: The simplest solution that works universally is always the best solution for agent shell compatibility.