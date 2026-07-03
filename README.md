# openai-proto
The inference interface you already use, but proto.

## Layout

```text
openai-proto/
├── buf.yaml                   # Buf module configuration
├── buf.gen.yaml                # Code generation matrix
└── proto/
    └── openai/
        ├── common/v1/          # shared Error/ErrorResponse
        ├── chat/v1/            # Chat Completions (tools, vision, structured outputs, logprobs)
        ├── responses/v1/       # Responses API (unary + typed streaming events)
        ├── embeddings/v1/
        ├── moderations/v1/
        ├── models/v1/
        ├── files/v1/
        ├── uploads/v1/         # multipart uploads (imports files/v1)
        ├── batch/v1/
        ├── finetuning/v1/
        ├── vectorstores/v1/
        ├── images/v1/          # generations, edits, variations
        ├── audio/v1/           # speech, transcription, translation
        └── realtime/v1/        # bidirectional streaming (Connect RPC)
```

Package names mirror `openai.<domain>.<version>`; directory layout mirrors package
namespaces 1:1. Every package's RPCs use buf-standard `<Method>Request`/`<Method>Response`
naming and lint clean under buf's `STANDARD` category, except `chat/v1`, which is
grandfathered to keep its original OpenAI-mirrored message names (scoped via
`lint.ignore_only` in `buf.yaml`).

## Installing generated clients

### Go

```sh
go get github.com/Fraser-Isbester/openai-proto/gen/go@vX.Y.Z
```

```go
import chatv1 "github.com/Fraser-Isbester/openai-proto/gen/go/openai/chat/v1"
```

### Python

```sh
pip install openai-proto-grpc
```

```python
from openai_proto.chat.v1 import chat_messages_pb2, chat_service_pb2_grpc
```

Note the package imports as `openai_proto`, not `openai` — the generated `openai.*` proto
namespace is renamed on publish (see `packages/python/postprocess.sh`) specifically so it
doesn't collide with the real `openai` PyPI package (OpenAI's own SDK) if both are installed.

### TypeScript

```sh
npm install @fraser-isbester/openai-proto
```

```ts
import { ChatServiceClient } from "@fraser-isbester/openai-proto/dist/openai/chat/v1/chat_service.client";
```

There's no single barrel/index export — import the specific generated module you need by
its path (mirrors the proto file layout under `dist/openai/...`). You bring your own
`RpcTransport` (e.g. `@protobuf-ts/grpc-transport` or `@protobuf-ts/grpcweb-transport`).

## Local development

```sh
# Lint the schema
buf lint

# Compile the module (no plugins, fast sanity check)
buf build

# Generate language stubs: gen/go, packages/python/src, packages/typescript/src
buf generate

# Python only: buf's plugins don't emit __init__.py and would collide with the
# real `openai` package on PyPI — this renames the namespace and adds them.
bash packages/python/postprocess.sh
```

`.github/workflows/ci.yml` runs `buf lint`/`build`/`breaking` plus a per-language sanity
build (Go compile, Python import smoke test, TypeScript typecheck) on every push and PR.

## Releasing

Releases are cut manually via the **Release** GitHub Actions workflow
(`.github/workflows/release.yml`, `workflow_dispatch` with a `version` input like `0.1.0`).
One run versions and publishes Go, Python, and TypeScript together from the current `main`:

1. Generates all language stubs from the current proto.
2. Commits `gen/go` (normally gitignored) and tags the commit `vX.Y.Z` — this is what makes
   `go get .../gen/go@vX.Y.Z` resolve; the tag is created once and never moved.
3. Builds and publishes the Python package to PyPI via
   [Trusted Publishing](https://docs.pypi.org/trusted-publishers/) (OIDC — no token to manage,
   but the PyPI project must have trusted publishing configured once for this repo/workflow).
4. Builds and publishes the TypeScript package to npm using the `NPM_TOKEN` repository secret.
5. Creates a GitHub Release with auto-generated notes.

**One-time setup required before the first release:**
- Configure [PyPI Trusted Publishing](https://docs.pypi.org/trusted-publishers/adding-a-publisher/)
  for project `openai-proto-grpc`, repo `Fraser-Isbester/openai-proto`, workflow `release.yml`.
- Add an `NPM_TOKEN` repository secret (an npm automation token with publish access).

