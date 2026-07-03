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

## Usage

```sh
# Lint the schema
buf lint

# Compile the module (no plugins, fast sanity check)
buf build

# Generate language stubs into gen/{go,ts,python}
buf generate
```

