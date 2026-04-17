import threading
import requests
import json
import tkinter as tk
from tkinter.scrolledtext import ScrolledText


# ===============================
# AnythingLLM 設定
# ===============================
API_URL = "http://localhost:3001"
API_KEY = "DW1620Q-VVRM3DN-NAA287H-KWTRD6H"
WORKSPACE_SLUG = "d4758af5-6b6c-46de-8746-57b9782432cc"
USE_STREAM = True


HEADERS_STREAM = {
    "Authorization": f"Bearer {API_KEY}",
    "Accept": "text/event-stream",
    "Content-Type": "application/json",
}

HEADERS_JSON = {
    "Authorization": f"Bearer {API_KEY}",
    "Accept": "application/json",
    "Content-Type": "application/json",
}


def build_url(stream=False):
    return f"{API_URL.rstrip('/')}/api/v1/workspace/{WORKSPACE_SLUG}/" + ("stream-chat" if stream else "chat")


# ===============================
# 修正：正確 UTF-8 stream 解析
# ===============================
def call_anythingllm_stream(message, on_chunk, on_error):
    url = build_url(stream=True)
    payload = {
        "message": message,
        "mode": "chat",
        "stream": True,
    }

    try:
        with requests.post(url, json=payload, headers=HEADERS_STREAM, stream=True, timeout=120) as resp:

            if resp.status_code != 200:
                on_error(f"HTTP {resp.status_code}: {resp.text}")
                return

            # 關鍵：不要 decode_unicode，改成手動 UTF-8
            for raw_line in resp.iter_lines(decode_unicode=False):
                if not raw_line:
                    continue

                line = raw_line.decode("utf-8", errors="ignore").strip()

                if not line.startswith("data:"):
                    continue

                data = line[5:].strip()
                if data == "[DONE]":
                    break

                try:
                    obj = json.loads(data)
                except:
                    continue

                if obj.get("type") == "textResponseChunk":
                    chunk = obj.get("textResponse", "")
                    if chunk:
                        on_chunk(chunk)

                if obj.get("type") == "finalizeResponseStream":
                    final = obj.get("textResponse", "")
                    if final:
                        on_chunk(final)

    except Exception as e:
        on_error(str(e))


# ===============================
# 一次性請求版本
# ===============================
def call_anythingllm_once(message, on_result, on_error):
    url = build_url(stream=False)
    payload = {"message": message, "mode": "chat", "stream": False}

    try:
        resp = requests.post(url, json=payload, headers=HEADERS_JSON, timeout=60)

        if resp.status_code != 200:
            on_error(f"HTTP {resp.status_code}: {resp.text}")
            return

        data = resp.json()
        text = data.get("textResponse") or data.get("text")
        if not text:
            text = json.dumps(data, ensure_ascii=False)

        on_result(text)

    except Exception as e:
        on_error(str(e))


# ===============================
# GUI：淺色主題 + ChatGPT 風格
# ===============================
class ChatApp:
    def __init__(self, root):
        self.root = root
        root.title("AnythingLLM Chat — Gemma3:4b")
        root.geometry("1200x800")
        root.configure(bg="#f5f5f5")

        # 文字框
        self.display = ScrolledText(
            root,
            wrap=tk.WORD,
            bg="#ffffff",
            fg="#000000",
            font=("Segoe UI", 12),
            insertbackground="#000000",
            bd=0
        )
        self.display.pack(fill=tk.BOTH, expand=True, padx=10, pady=10)
        self.display.configure(state=tk.DISABLED)

        # 輸入區
        bottom = tk.Frame(root, bg="#f5f5f5")
        bottom.pack(fill=tk.X, padx=10, pady=5)

        self.text_var = tk.StringVar()
        self.entry = tk.Entry(bottom, textvariable=self.text_var, font=("Segoe UI", 12))
        self.entry.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=8, padx=(0, 8))
        self.entry.bind("<Return>", self.on_send)

        self.send_btn = tk.Button(bottom, text="送出", font=("Segoe UI", 11), command=self.on_send)
        self.send_btn.pack(side=tk.LEFT, padx=(0, 5))

        self.clear_btn = tk.Button(bottom, text="清除", font=("Segoe UI", 11), command=self.on_clear)
        self.clear_btn.pack(side=tk.LEFT)

        # 狀態列
        self.status = tk.StringVar(value="Ready")
        tk.Label(root, textvariable=self.status, bg="#f5f5f5", fg="#555").pack(anchor="w", padx=12, pady=5)

    def append(self, role, text):
        self.display.configure(state=tk.NORMAL)
        if role == "user":
            bubble = f"\n🧑 你：\n{text}\n"
        else:
            bubble = f"\n🤖 助理：\n{text}\n"

        self.display.insert(tk.END, bubble)
        self.display.see(tk.END)
        self.display.configure(state=tk.DISABLED)

    def append_stream(self, chunk):
        self.display.configure(state=tk.NORMAL)
        self.display.insert(tk.END, chunk)
        self.display.see(tk.END)
        self.display.configure(state=tk.DISABLED)

    def on_clear(self):
        self.display.configure(state=tk.NORMAL)
        self.display.delete("1.0", tk.END)
        self.display.configure(state=tk.DISABLED)

    def on_send(self, event=None):
        msg = self.text_var.get().strip()
        if not msg:
            return

        self.text_var.set("")
        self.append("user", msg)

        threading.Thread(target=self.worker, args=(msg,), daemon=True).start()

    def worker(self, message):
        self.status.set("Thinking...")

        if USE_STREAM:
            self.append("assistant", "")

            def on_chunk(c):
                self.root.after(0, lambda: self.append_stream(c))

            def on_error(err):
                self.root.after(0, lambda: self.append("assistant", f"[錯誤] {err}"))

            call_anythingllm_stream(message, on_chunk, on_error)
        else:
            def on_result(txt):
                self.root.after(0, lambda: self.append("assistant", txt))

            def on_error(err):
                self.root.after(0, lambda: self.append("assistant", f"[錯誤] {err}"))

            call_anythingllm_once(message, on_result, on_error)

        self.status.set("Ready")


def main():
    root = tk.Tk()
    ChatApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()
