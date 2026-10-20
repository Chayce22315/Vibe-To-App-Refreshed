"""Local OpenAI-compatible endpoint for the experimental blank checkpoint.

Run from this directory after training a checkpoint. The model is a research
prototype; it may produce incoherent text and is not expected to write working apps.
"""
import argparse
import json
import os
import secrets
import time
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

import torch

from blank_model.model import BlankLanguageModel
from blank_model.tokenizer import ByteTokenizer

MODEL = None
TOKENIZER = ByteTokenizer()
DEVICE = None
TOKEN = None


class Handler(BaseHTTPRequestHandler):
    server_version = "VibeBlankLocal/0.1"

    def _json(self, status, payload):
        body = json.dumps(payload).encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            self._json(200, {
                "ok": MODEL is not None,
                "model": getattr(getattr(MODEL, "config", None), "name", "unloaded"),
                "device": str(DEVICE),
                "note": "experimental from-scratch model; quality is not guaranteed",
            })
        else:
            self._json(404, {"error": {"message": "not found", "type": "not_found"}})

    def do_POST(self):
        if self.path != "/v1/chat/completions":
            self._json(404, {"error": {"message": "not found", "type": "not_found"}})
            return

        if TOKEN and not secrets.compare_digest(
            self.headers.get("Authorization", ""), "Bearer " + TOKEN
        ):
            self._json(401, {"error": {"message": "invalid bearer token", "type": "auth_error"}})
            return

        try:
            length = int(self.headers.get("Content-Length", "0"))
            if length <= 0 or length > 128_000:
                raise ValueError("request body must be between 1 byte and 128 KB")
            payload = json.loads(self.rfile.read(length))
            messages = payload.get("messages", [])
            prompt = "\n".join(
                f"{str(m.get('role', 'user'))}: {str(m.get('content', ''))}"
                for m in messages if isinstance(m, dict)
            )
            prompt += "\nassistant:"
            max_tokens = max(1, min(int(payload.get("max_tokens", 96)), 128))
            temperature = max(0.1, min(float(payload.get("temperature", 0.8)), 1.5))
            top_k = max(1, min(int(payload.get("top_k", 40)), 100))
            ids = TOKENIZER.encode(prompt)
            if not ids:
                ids = [32]
            input_ids = torch.tensor([ids], dtype=torch.long, device=DEVICE)
            with torch.inference_mode():
                output = MODEL.generate(
                    input_ids,
                    max_new_tokens=max_tokens,
                    temperature=temperature,
                    top_k=top_k,
                )
            generated = output[0, len(ids):].detach().cpu().tolist()
            answer = TOKENIZER.decode(generated).strip()
            self._json(200, {
                "id": "chatcmpl-blank-local",
                "object": "chat.completion",
                "created": int(time.time()),
                "model": getattr(MODEL.config, "name", "blank"),
                "choices": [{
                    "index": 0,
                    "message": {"role": "assistant", "content": answer},
                    "finish_reason": "length",
                }],
                "usage": {
                    "prompt_tokens": len(ids),
                    "completion_tokens": len(generated),
                    "total_tokens": len(ids) + len(generated),
                },
            })
        except (ValueError, TypeError, KeyError, json.JSONDecodeError) as exc:
            self._json(400, {"error": {"message": str(exc), "type": "invalid_request"}})
        except Exception as exc:
            self._json(500, {"error": {"message": str(exc), "type": "inference_error"}})

    def log_message(self, fmt, *args):
        print("[http] " + fmt % args)


def main():
    global MODEL, DEVICE, TOKEN
    parser = argparse.ArgumentParser(description="serve your experimental blank model locally")
    parser.add_argument("--checkpoint", default="checkpoints/blank/latest.pt")
    parser.add_argument("--host", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=8080)
    args = parser.parse_args()

    checkpoint_path = Path(args.checkpoint)
    if not checkpoint_path.is_file():
        raise SystemExit(
            f"checkpoint not found: {checkpoint_path}\n"
            "train blank first, or pass --checkpoint with the path to latest.pt"
        )

    TOKEN = os.environ.get("VIBE_LOCAL_TOKEN", "").strip() or None
    if args.host not in {"127.0.0.1", "localhost", "::1"} and not TOKEN:
        raise SystemExit(
            "refusing to listen on a network interface without VIBE_LOCAL_TOKEN. "
            "set a long random token, keep the server on a trusted network, and never port-forward it."
        )

    DEVICE = torch.device("cuda" if torch.cuda.is_available() else "cpu")
    checkpoint = torch.load(checkpoint_path, map_location=DEVICE, weights_only=False)
    from blank_model.configs import ModelConfig
    config = ModelConfig(**checkpoint["model_config"])
    MODEL = BlankLanguageModel(config).to(DEVICE)
    MODEL.load_state_dict(checkpoint["model"])
    MODEL.eval()

    server = ThreadingHTTPServer((args.host, args.port), Handler)
    print(f"blank model loaded on {DEVICE}; listening at http://{args.host}:{args.port}")
    print("endpoints: GET /health, POST /v1/chat/completions")
    print("prototype only. press ctrl+c to stop.")
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nstopping local inference server...")
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
