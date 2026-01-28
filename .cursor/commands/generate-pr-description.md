# Generate PR Description Command

## Overview

Analyze the git diff in pr-diff.txt and create a comprehensive PR description (max 300 words) highlighting:

- High-level architectural changes
- Key features, added/modified
- Performance improvements
- Breaking changes (if any)
- Business impact

Focus on the 'why' and 'what' rather than detailed code changes.

**IMPORTANT**: Output ONLY the PR description markdown content wrapped in a markdown code block (```markdown ... ```) for easy copying. Do not include any AI commentary, tool execution details, or explanatory text outside the code block. Start directly with the PR title and content inside the code block.

After generating the PR description, clean up by deleting pr-diff.txt file.

## Manual Workflow

1. **Generate diff**: `git diff main HEAD > pr-diff.txt` (use `main HEAD` to see what's new in your branch)
2. **Verify direction**: Check that `git diff --stat main HEAD` shows positive insertions for new features
3. **Analyze with AI**: Use this prompt with the generated file
4. **Cleanup**: `rm pr-diff.txt` (or `del pr-diff.txt` on Windows)

**Important**: Always use `git diff main HEAD` (or `git diff base-branch feature-branch`) to see what's NEW in your branch. The direction matters!

## AI Prompt Template

```
Based on the git diff in pr-diff.txt (comparing base-branch..feature-branch), create a comprehensive PR description (max 300 words).
```

**CRITICAL**:
- Output ONLY the markdown PR description content wrapped in a markdown code block (```markdown ... ```) for easy copying
- No AI commentary, no tool execution details, no explanatory text outside the code block
- Start immediately with the PR title and description inside the code block that can be copied directly to GitHub/Azure DevOps

Include these sections:

## Overview
Brief summary of what this PR accomplishes

## 🏗️ High-Level Architectural Changes
Focus on system design changes, new patterns, architectural decisions

## 🎯 Key Features
Major features added, modified, or removed

## 🚀 Performance & Operational Improvements
Resource optimization, monitoring enhancements, deployment improvements

## 🔄 Service Changes
How each service/component behavior changed

## 🎯 Business Impact
Reliability, operational excellence, developer experience improvements

## Technical Details
- Files changed: X files (Y added, Z modified, W deleted)
- Breaking changes: None/List them
- Related issue:
   - Fixes #XXXXX
   - Fixes #YYYYY
   - etc...

```
Focus on architectural significance rather than implementation details.
 to get related issues from the commit messages or the branch name. and it always use the format GCM-XXXX. so if the branch name is "feature/gcm-1234-add-new-feature", then the related issue is GCM-1234, or if the commit message is "Fixes GCM-1234", then the related issue is GCM-1234.
```

## PowerShell Script Alternative

Create `generate-pr-description.ps1`:

```powershell
#!/usr/bin/env pwsh
param(
    [string]$BaseBranch = "main",
    [string]$OutputFile = "pr-diff.txt"
)

Write-Host "🔍 Generating diff: $BaseBranch..HEAD (what's new in your branch)..." -ForegroundColor Cyan
git diff $BaseBranch HEAD > $OutputFile

$fileCount = (git diff --name-only $BaseBranch HEAD | Measure-Object).Count
$stats = git diff --stat $BaseBranch HEAD

Write-Host "📊 Changes Summary:" -ForegroundColor Green
Write-Host "Files changed: $fileCount" -ForegroundColor Yellow
Write-Host $stats -ForegroundColor Gray

Write-Host "`n✅ Generated $OutputFile" -ForegroundColor Green
Write-Host "💡 Next: Ask AI to analyze the diff and generate PR description" -ForegroundColor Blue
Write-Host "🧹 Remember to delete $OutputFile after generating the description" -ForegroundColor Yellow
```

Usage: `./generate-pr-description.ps1 -BaseBranch origin/main`