# /config

A quick-access command for configuration-management workflows in Claude Code.

## Trigger

`/config [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing configuration-management implementation
- `generate` - Generate new configuration-management artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for configuration-management artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of configuration-management artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against config-patterns patterns
- Identify gaps, issues, and opportunities
- Prioritize findings by impact and effort

### Step 3: Execution
- Apply the requested action
- Generate or modify artifacts as needed
- Validate changes against requirements

### Step 4: Output
- Present results in the requested format
- Include actionable next steps
- Flag any items requiring human decision

## Output

### Success
```
## Configuration Management - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Configuration Management - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/config analyze

# Generate new artifacts
/config generate --context ./src

# Validate against best practices
/config validate --verbose

# Generate documentation
/config document --format markdown
```
