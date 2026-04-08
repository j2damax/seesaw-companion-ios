#!/bin/bash
# export_test_results.sh — Generates a Markdown code-coverage report from an
# existing .xcresult bundle. Run after:
#   xcodebuild test -scheme SeeSaw \
#     -destination 'platform=iOS Simulator,name=iPhone 17' \
#     -enableCodeCoverage YES \
#     -resultBundlePath <project>/test-results/SeeSaw_<timestamp>.xcresult
#
# Uses the 'latest.xcresult' symlink written by the previous test run if no
# explicit path is supplied via XCRESULT_PATH environment variable.

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESULT="${XCRESULT_PATH:-${PROJECT_DIR}/test-results/latest.xcresult}"
OUTPUT="${PROJECT_DIR}/test-results/TestCoverage.md"

# Get JSON report
JSON=$(xcrun xccov view --report --json "$RESULT")

# Extract overall target coverage
echo "# SeeSaw Companion — Test Coverage Report" > "$OUTPUT"
echo "" >> "$OUTPUT"
echo "**Generated:** $(date '+%Y-%m-%d %H:%M:%S')" >> "$OUTPUT"
echo "" >> "$OUTPUT"

# Parse target-level summary
echo "## Target Summary" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "| Target | Line Coverage |" >> "$OUTPUT"
echo "|--------|-------------|" >> "$OUTPUT"
echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data.get('targets', []):
    name = target.get('name', 'Unknown')
    pct = target.get('lineCoverage', 0) * 100
    print(f'| {name} | {pct:.1f}% |')
" >> "$OUTPUT"

echo "" >> "$OUTPUT"

# Parse per-file coverage
echo "## Per-File Coverage" >> "$OUTPUT"
echo "" >> "$OUTPUT"
echo "| File | Lines Covered | Total Lines | Coverage |" >> "$OUTPUT"
echo "|------|--------------|-------------|----------|" >> "$OUTPUT"
echo "$JSON" | python3 -c "
import json, sys
data = json.load(sys.stdin)
for target in data.get('targets', []):
    tname = target.get('name', '')
    if 'Tests' in tname:
        continue  # skip test targets
    for f in sorted(target.get('files', []), key=lambda x: x.get('lineCoverage', 0)):
        name = f.get('name', 'Unknown')
        pct = f.get('lineCoverage', 0) * 100
        covered = f.get('coveredLines', 0)
        total = f.get('executableLines', 0)
        if total == 0:
            continue
        print(f'| {name} | {covered} | {total} | {pct:.1f}% |')
" >> "$OUTPUT"

echo "" >> "$OUTPUT"
echo "---" >> "$OUTPUT"
echo "*Report generated from \`$RESULT\`*" >> "$OUTPUT"

echo "✅ Coverage report saved to $OUTPUT"