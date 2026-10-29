#!/bin/bash
OUTPUT_FILE="$HOME/.local/state/dms/github_stats.json"
mkdir -p "$(dirname "$OUTPUT_FILE")"

# 1. Try gh cli GraphQL (authenticated, full contributions heatmap)
if command -v gh >/dev/null 2>&1; then
    DATA=$(gh api graphql -f query='query { user(login: "EDGAR-BRI") { name avatarUrl repositories(ownerAffiliations: OWNER) { totalCount } followers { totalCount } contributionsCollection { contributionCalendar { totalContributions weeks { contributionDays { contributionCount color } } } } } }' 2>/dev/null)
    if [ -n "$DATA" ]; then
        PARSED=$(echo "$DATA" | jq '.data.user' 2>/dev/null)
        if [ "$PARSED" != "null" ] && [ -n "$PARSED" ]; then
            echo "$DATA" | jq '{
              name: (.data.user.name // "EDGAR-BRI"),
              login: "EDGAR-BRI",
              avatarUrl: .data.user.avatarUrl,
              repos: .data.user.repositories.totalCount,
              followers: .data.user.followers.totalCount,
              contributions: .data.user.contributionsCollection.contributionCalendar.totalContributions,
              weeks: [.data.user.contributionsCollection.contributionCalendar.weeks[-26:][] | [.contributionDays[] | {count: .contributionCount, color: .color}]]
            }' > "$OUTPUT_FILE"
            cp "$OUTPUT_FILE" /usr/share/sddm/themes/Corners/data/github_stats.json 2>/dev/null || true
            exit 0
        fi
    fi
fi

# 2. Fallback to public REST API if gh failed
curl -s "https://api.github.com/users/EDGAR-BRI" | jq '{
  name: (.name // "EDGAR-BRI"),
  login: .login,
  avatarUrl: .avatar_url,
  repos: .public_repos,
  followers: .followers,
  contributions: 0,
  weeks: []
}' > "$OUTPUT_FILE"
cp "$OUTPUT_FILE" /usr/share/sddm/themes/Corners/data/github_stats.json 2>/dev/null || true
