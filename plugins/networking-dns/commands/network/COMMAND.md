# /network

A quick-access command for networking-dns workflows in Claude Code.

## Trigger

`/network [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing networking-dns implementation
- `generate` - Generate new networking-dns artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for networking-dns artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of networking-dns artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against network-patterns patterns
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
## Networking Dns - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Networking Dns - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/network analyze

# Generate new artifacts
/network generate --context ./src

# Validate against best practices
/network validate --verbose

# Generate documentation
/network document --format markdown
```
