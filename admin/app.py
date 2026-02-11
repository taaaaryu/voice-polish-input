from __future__ import annotations

import json
import os
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

from flask import Flask, redirect, render_template, request, url_for


DEFAULT_FILLERS = [
    "えー",
    "え〜",
    "えぇ",
    "あの",
    "あのー",
    "あの〜",
    "えっと",
    "えっとー",
    "えっと〜",
    "その",
    "そのー",
    "その〜",
    "なんか",
]


@dataclass
class Store:
    path: Path

    def read(self) -> dict[str, Any]:
        self._ensure_exists()
        raw = self.path.read_text(encoding="utf-8")
        try:
            parsed = json.loads(raw)
        except json.JSONDecodeError:
            parsed = self._default_state()
        return self._normalize(parsed)

    def write(self, data: dict[str, Any]) -> None:
        normalized = self._normalize(data)
        self.path.parent.mkdir(parents=True, exist_ok=True)
        tmp = self.path.with_suffix(".tmp")
        tmp.write_text(json.dumps(normalized, ensure_ascii=False, indent=2), encoding="utf-8")
        tmp.replace(self.path)

    def _ensure_exists(self) -> None:
        if self.path.exists():
            return
        self.path.parent.mkdir(parents=True, exist_ok=True)
        self.write(self._default_state())

    def _default_state(self) -> dict[str, Any]:
        return {
            "fillerWords": DEFAULT_FILLERS,
            "replacementEntries": [],
            "historyEntries": [],
        }

    def _normalize(self, data: dict[str, Any]) -> dict[str, Any]:
        fillers = sorted({str(v).strip() for v in data.get("fillerWords", []) if str(v).strip()})

        replacements: list[dict[str, str]] = []
        seen_from: set[str] = set()
        for entry in data.get("replacementEntries", []):
            src = str(entry.get("from", "")).strip()
            dst = str(entry.get("to", "")).strip()
            if not src or not dst or src in seen_from:
                continue
            seen_from.add(src)
            replacements.append({"from": src, "to": dst})
        replacements.sort(key=lambda item: item["from"])

        history: list[dict[str, Any]] = []
        for row in data.get("historyEntries", []):
            row_id = str(row.get("id", "")).strip()
            created = str(row.get("createdAtISO8601", "")).strip()
            raw_text = str(row.get("rawText", ""))
            polished = str(row.get("polishedText", ""))
            inserted = bool(row.get("inserted", False))
            error_message = row.get("errorMessage")
            if not row_id:
                row_id = f"hist-{len(history)+1}"
            if not created:
                created = datetime.now(timezone.utc).isoformat()
            history.append(
                {
                    "id": row_id,
                    "createdAtISO8601": created,
                    "rawText": raw_text,
                    "polishedText": polished,
                    "inserted": inserted,
                    "errorMessage": error_message if error_message else None,
                }
            )

        history = history[:300]
        return {
            "fillerWords": fillers,
            "replacementEntries": replacements,
            "historyEntries": history,
        }


state_path = Path(
    os.environ.get(
        "VOICE_POLISH_STATE_PATH",
        os.path.expanduser("~/Library/Application Support/VoicePolishInput/state.json"),
    )
)
store = Store(path=state_path)
app = Flask(__name__)


@app.get("/")
def index() -> str:
    state = store.read()
    history = state["historyEntries"]
    history_preview = history[:100]
    return render_template(
        "index.html",
        state_path=str(state_path),
        fillers=state["fillerWords"],
        replacements=state["replacementEntries"],
        history=history_preview,
        history_count=len(history),
    )


@app.post("/fillers/add")
def fillers_add():
    word = request.form.get("word", "").strip()
    state = store.read()
    if word and word not in state["fillerWords"]:
        state["fillerWords"].append(word)
        state["fillerWords"].sort()
        store.write(state)
    return redirect(url_for("index"))


@app.post("/fillers/delete")
def fillers_delete():
    word = request.form.get("word", "").strip()
    state = store.read()
    state["fillerWords"] = [v for v in state["fillerWords"] if v != word]
    store.write(state)
    return redirect(url_for("index"))


@app.post("/replacements/upsert")
def replacements_upsert():
    src = request.form.get("src", "").strip()
    dst = request.form.get("dst", "").strip()
    if not src or not dst:
        return redirect(url_for("index"))

    state = store.read()
    found = False
    for item in state["replacementEntries"]:
        if item["from"] == src:
            item["to"] = dst
            found = True
            break
    if not found:
        state["replacementEntries"].append({"from": src, "to": dst})
    state["replacementEntries"].sort(key=lambda item: item["from"])
    store.write(state)
    return redirect(url_for("index"))


@app.post("/replacements/delete")
def replacements_delete():
    src = request.form.get("src", "").strip()
    state = store.read()
    state["replacementEntries"] = [item for item in state["replacementEntries"] if item["from"] != src]
    store.write(state)
    return redirect(url_for("index"))


@app.post("/history/clear")
def history_clear():
    state = store.read()
    state["historyEntries"] = []
    store.write(state)
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8765, debug=False)

