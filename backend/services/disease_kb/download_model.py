"""Standalone retry loop to pre-download BAAI/bge-m3 into the local HF cache.

Run this once before starting the disease_kb service. Separated from the
service's own startup so a flaky connection doesn't repeatedly crash uvicorn --
this script just keeps retrying snapshot_download (which resumes partial
files) until the whole snapshot is present locally.
"""
from __future__ import annotations

import os
import socket
import time

os.environ.setdefault("HF_HUB_DISABLE_XET", "1")
os.environ.setdefault("HF_HUB_DOWNLOAD_TIMEOUT", "60")

# httpx/httpcore's per-request timeout doesn't always cover the OS-level
# getaddrinfo() call on Windows, which can block indefinitely on a flaky
# connection. A global socket default timeout guards against that hang.
socket.setdefaulttimeout(60)

from huggingface_hub import snapshot_download

MODEL_ID = "BAAI/bge-m3"
MAX_ATTEMPTS = 100

# The repo also ships onnx/openvino/tf variants (several extra GB) that
# sentence-transformers never touches when loading via plain PyTorch --
# skip them so a flaky connection isn't wasted re-downloading data we
# don't need.
IGNORE_PATTERNS = ["onnx/*", "openvino/*", "*.onnx", "*.onnx_data", "*.msgpack", "*.h5", "*.ot", "*.tflite"]

for attempt in range(1, MAX_ATTEMPTS + 1):
    try:
        print(f"[attempt {attempt}] downloading {MODEL_ID} ...", flush=True)
        path = snapshot_download(repo_id=MODEL_ID, ignore_patterns=IGNORE_PATTERNS)
        print(f"DONE: model cached at {path}", flush=True)
        break
    except Exception as exc:  # noqa: BLE001 - genuinely want to retry on anything transient
        print(f"[attempt {attempt}] failed: {exc}", flush=True)
        time.sleep(5)
else:
    print("GAVE UP after max attempts", flush=True)
