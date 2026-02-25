# /terraform

A quick-access command for terraform-patterns workflows in Claude Code.

## Trigger

`/terraform [action] [options]`

## Input

### Actions
- `analyze` - Analyze existing terraform-patterns implementation
- `generate` - Generate new terraform-patterns artifacts
- `improve` - Suggest improvements to current implementation
- `validate` - Check implementation against best practices
- `document` - Generate documentation for terraform-patterns artifacts

### Options
- `--context <path>` - Specify the file or directory to operate on
- `--format <type>` - Output format (markdown, json, yaml)
- `--verbose` - Include detailed explanations
- `--dry-run` - Preview changes without applying them

## Process

### Step 1: Context Gathering
- Read relevant files and configuration
- Identify the current state of terraform-patterns artifacts
- Determine applicable standards and conventions

### Step 2: Analysis
- Evaluate against terraform-patterns patterns
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
## Terraform Patterns - [Action] Complete

### Changes Made
- [List of changes]

### Validation
- [Checks passed]

### Next Steps
- [Recommended follow-up actions]
```

### Error
```
## Terraform Patterns - [Action] Failed

### Issue
[Description of the problem]

### Suggested Fix
[How to resolve the issue]
```

## Examples

```bash
# Analyze current implementation
/terraform analyze

# Generate new artifacts
/terraform generate --context ./src

# Validate against best practices
/terraform validate --verbose

# Generate documentation
/terraform document --format markdown
```
