#!/usr/bin/env bash
# Post-processes buf's raw Python output (packages/python/src/openai/...) into an
# installable package. Run after `buf generate` and before `python -m build` /
# any import smoke test. Idempotent: safe to re-run after a fresh `buf generate`.
#
# Two things buf's protocolbuffers/python + grpc/python plugins don't handle:
#   1. They emit a top-level `openai` package, which collides with the real
#      `openai` PyPI package (OpenAI's own SDK) if both are installed. Renamed
#      to `openai_proto` here, with all internal imports rewritten to match.
#   2. They don't emit `__init__.py` files, so nothing under `src/` is importable
#      as a package yet.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")"

SRC_ROOT="src/openai"
DEST_ROOT="src/openai_proto"

if [ ! -d "$SRC_ROOT" ]; then
  echo "packages/python/postprocess.sh: $SRC_ROOT not found — did you run 'buf generate' first?" >&2
  exit 1
fi

rm -rf "$DEST_ROOT"
mv "$SRC_ROOT" "$DEST_ROOT"

# Rewrite absolute imports (`from openai.chat.v1 import ...` / `import openai.chat.v1...`)
# to the renamed namespace. Word-boundary anchored so it only matches the
# top-level `openai` package, not incidental substrings.
grep -rlE '^(from|import) openai\.' "$DEST_ROOT" --include='*.py' --include='*.pyi' | \
  xargs -I{} sed -i '' -E 's/^(from|import) openai\./\1 openai_proto./' {}

find "$DEST_ROOT" -type d -exec touch {}/__init__.py \;

echo "packages/python/postprocess.sh: done — $(find "$DEST_ROOT" -name '*.py' | wc -l | tr -d ' ') .py files under $DEST_ROOT"
