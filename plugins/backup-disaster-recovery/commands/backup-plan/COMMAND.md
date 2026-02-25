# /backup-plan

A quick-access command for backup-disaster-recovery workflows in Claude Code.

## Trigger

`/backup-plan [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing backup-disaster-recovery implementation
- `generate` - Generate new backup-disaster-recovery artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for backup-disaster-recovery artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of backup-disaster-recovery artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against dr-patterns patterns
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
## Backup Disaster Recovery - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Backup Disaster Recovery - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/backup-plan analyze

# Generate new artifacts
/backup-plan generate --context ./src

# Validate against best practices
/backup-plan validate --verbose

# Generate documentation
/backup-plan document --format markdown
```
