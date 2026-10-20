# experimental blank local provider

this folder reuses the small transformer, config, and byte-tokenizer code from [blank-code-training-repo](https://github.com/Chayce22315/blank-code-training-repo). it is your from-scratch model family, copied here so vibe to app: refreshed can experiment with it without making the ios app depend on python.

## honest status

the blank model is a tiny research model trained from random initialization. it may generate word-like text, but it is not a capable coding assistant yet. this server is a wiring test for the local-provider path, not a claim that the model can build apps.

## setup

use python 3.10+ and a compatible pytorch install. on your training pc, from the repository root:

```powershell
python -m pip install -r local_blank_server/requirements.txt
python -m blank_model.train --config blank --data data/train --steps 200 --output checkpoints/blank
```

the training command above runs from the training repository, not this app repository. then copy your trained `latest.pt` checkpoint into this folder at `checkpoints/blank/latest.pt`, or pass its path to `--checkpoint`. do not commit checkpoints or datasets.

from this folder, start the server:

```powershell
python server.py --checkpoint checkpoints/blank/latest.pt
```

health check: `http://127.0.0.1:8080/health`

## iphone connection

`127.0.0.1` on an iphone means the iphone itself, not your pc. to connect from an iphone, use your pc's local wi-fi address in the app's local endpoint setting and start the server with `--host 0.0.0.0`. before binding to a network interface, set a long random bearer token in `VIBE_LOCAL_TOKEN`; the server refuses network listening without it. only use a trusted private network, keep the token private, and never port-forward this endpoint to the public internet. the ios app needs the same token configured to authenticate; secure keychain entry is a follow-up integration step.

## license and provenance

source: [blank-code-training-repo](https://github.com/Chayce22315/blank-code-training-repo), MIT license, copyright 2026 Chayce22315. the model code here is adapted from that repository. the ios app calls this server over a configurable openai-compatible endpoint; no model weights are bundled in the app.
