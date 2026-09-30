# People mine: LibreDevOps-Claude-Code

What people who use the product said in its own public places: issues, issue comments, discussions, pull requests, and forks that changed something. Optional third pantry source; a product with no outside voices yet leaves the Hits table empty and says so.

## How this fills

1. List the product's own repos (the kitchen law names them).
2. Read what people outside the maintainers wrote since the last run: issues (the `feedback` label first), issue comments, discussions and their comments, pull requests, and forks with commits ahead of the default branch.
3. One row per voice. Quote a short snippet and link the exact issue, comment, discussion, PR or commit. Say whether they gave credit consent when the source has a consent box.
4. Tag each row with the capability it is about, in the same words as the competitor map's matrix, so the queue can cite it next to competitor and X rows.
5. Never count stars as feedback, never infer sentiment the person did not state, never paraphrase a number. Maintainers' own issues are not voices.
6. Save as `YYYY-MM-DD-people-mine.md` beside the other dated files (keep this TEMPLATE).

## Hits

No outside voices yet. Every issue, comment and pull request on the repo so far is by the maintainer, there are no discussions, and there are no forks.

| Repo | Kind (bug/feature/question/praise/contribution) | Snippet | Link | Theme (matrix capability) | Credit consent |
|------|--------------------------------------------------|---------|------|---------------------------|----------------|
|  |  |  |  |  |  |

## Read log (what we read)

Read on 2026-09-30 with `gh` and the GitHub API, repo HermeticOrmus/LibreDevOps-Claude-Code:

- Issues and pull requests, all states (`gh api "repos/HermeticOrmus/LibreDevOps-Claude-Code/issues?state=all"`): #1 (issue, closed), #2 (PR, closed), #3 (issue, closed), #4 (PR, closed), #5 (issue, open). All opened by HermeticOrmus. No issue carries the `feedback` label.
- Issue comments (`/issues/comments`): 2, both by HermeticOrmus (release notes on #1 and #3).
- Pull request review comments (`/pulls/comments`): 0. Reviews on PR #2 and PR #4 (`/pulls/<n>/reviews`): 0.
- Discussions (GraphQL `repository.discussions`): Discussions are enabled, 0 discussions.
- Commit comments (`/comments`): 0.
- Forks (`/forks`): 0, so no forks with commits ahead of `main`.
- Stars and watchers were looked at only to confirm there is no one else to read (0 stargazers, 0 subscribers); they are not feedback.
