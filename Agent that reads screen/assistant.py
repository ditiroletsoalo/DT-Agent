#!/usr/bin/env python3
"""
macOS Universal AI Assistant
Trigger anywhere with ⌘ + Shift + Space
Primary:  Groq API (free, fast, vision via Llama 4 Scout)
Fallback: Ollama (local, 100% free, no internet needed)
"""

import subprocess
import threading
import time
import base64
import os
import sys
import tkinter as tk

try:
    import customtkinter as ctk
    from pynput import keyboard
    import pyperclip
    import requests
except ImportError as e:
    print(f"\n❌ Missing package: {e}")
    print("   Run:  bash setup.sh\n")
    sys.exit(1)

# ── Config ───────────────────────────────────────────────────────────────────
GROQ_API_KEY   = os.environ.get("GROQ_API_KEY", "")
GROQ_MODEL     = "meta-llama/llama-4-scout-17b-16e-instruct"  # Free + vision
GROQ_URL       = "https://api.groq.com/openai/v1/chat/completions"

OLLAMA_MODEL   = "llava"          # Vision model for Ollama (ollama pull llava)
OLLAMA_URL     = "http://localhost:11434/api/chat"

SYSTEM_PROMPT = (
    "You are a helpful desktop AI assistant. The user may share a screenshot "
    "of their screen — if so, refer to what you see directly. "
    "Be concise and practical. When answering about R, Python, or data "
    "analysis, be specific and technical."
)
# ─────────────────────────────────────────────────────────────────────────────


class AssistantApp:
    def __init__(self, root: ctk.CTk):
        self.root = root
        self.root.withdraw()
        self.window = None
        self.conversation: list = []
        self.screenshot_b64: str | None = None
        self.active_backend: str = "?"
        self._setup_hotkey()
        print("✅ Assistant running.  Press ⌘ + Shift + Space anywhere to activate.")
        print(f"   Groq API key: {'✅ set' if GROQ_API_KEY else '❌ not set — will use Ollama'}")

    def _setup_hotkey(self):
        def on_activate():
            self.root.after(0, self._on_hotkey)
        h = keyboard.GlobalHotKeys({"<cmd>+<shift>+<space>": on_activate})
        h.daemon = True
        h.start()

    def _on_hotkey(self):
        threading.Thread(target=self._grab_context_then_show, daemon=True).start()

    def _grab_context_then_show(self):
        highlighted = self._get_highlighted_text()
        screenshot  = self._take_screenshot()
        self.root.after(0, lambda: self._show_or_focus(highlighted, screenshot))

    def _get_highlighted_text(self) -> str:
        try:
            original = pyperclip.paste()
        except Exception:
            original = ""
        script = 'tell application "System Events" to keystroke "c" using command down'
        subprocess.run(["osascript", "-e", script], capture_output=True)
        time.sleep(0.18)
        try:
            selected = pyperclip.paste()
        except Exception:
            return ""
        return selected if selected != original else ""

    def _take_screenshot(self) -> str | None:
        path = "/tmp/ai_assistant_sc.png"
        subprocess.run(["screencapture", "-x", path], capture_output=True)
        time.sleep(0.1)
        try:
            with open(path, "rb") as f:
                return base64.b64encode(f.read()).decode()
        except Exception:
            return None

    def _show_or_focus(self, highlighted: str, screenshot: str | None):
        self.screenshot_b64 = screenshot
        if self.window and self.window.winfo_exists():
            self.window.lift()
            self.window.focus_force()
            if highlighted:
                self.input_box.delete("1.0", tk.END)
                self.input_box.insert("1.0", highlighted)
            self._set_status("🔄 Screen refreshed", "#4CAF50")
        else:
            self._build_window(highlighted)

    def _build_window(self, highlighted: str = ""):
        win = ctk.CTkToplevel(self.root)
        win.title("AI Assistant")
        win.geometry("560x700")
        win.attributes("-topmost", True)
        win.resizable(True, True)
        self.window = win

        ctk.CTkLabel(
            win, text="✦  AI Assistant",
            font=ctk.CTkFont(size=20, weight="bold")
        ).pack(pady=(20, 2))

        self.backend_label = ctk.CTkLabel(
            win,
            text="Groq + Ollama fallback  •  Works in any app  •  ⌘ ⇧ Space",
            font=ctk.CTkFont(size=11), text_color="gray",
        )
        self.backend_label.pack(pady=(0, 14))

        self.chat_box = ctk.CTkTextbox(
            win, font=ctk.CTkFont(size=13),
            wrap="word", state="disabled", corner_radius=10,
        )
        self.chat_box.pack(fill="both", expand=True, padx=16, pady=(0, 8))

        input_frame = ctk.CTkFrame(win, fg_color="transparent")
        input_frame.pack(fill="x", padx=16, pady=(0, 4))

        self.input_box = ctk.CTkTextbox(
            input_frame, height=88, font=ctk.CTkFont(size=13),
            wrap="word", corner_radius=10,
        )
        self.input_box.pack(fill="x", pady=(0, 8))
        self.input_box.bind("<Return>", self._on_enter)

        if highlighted:
            self.input_box.insert("1.0", highlighted)

        btn_row = ctk.CTkFrame(input_frame, fg_color="transparent")
        btn_row.pack(fill="x")

        ctk.CTkButton(
            btn_row, text="Send  ↵", command=self._send,
            width=90, font=ctk.CTkFont(size=13), corner_radius=8,
        ).pack(side="right")

        ctk.CTkButton(
            btn_row, text="New Chat", command=self._clear,
            width=90, fg_color="transparent", border_width=1,
            font=ctk.CTkFont(size=13), corner_radius=8,
        ).pack(side="right", padx=(0, 8))

        self.status_var   = tk.StringVar(value="✅ Ready — ask anything")
        self.status_label = ctk.CTkLabel(
            win, textvariable=self.status_var,
            font=ctk.CTkFont(size=11), text_color="#4CAF50",
        )
        self.status_label.pack(pady=(4, 14))

        win.protocol("WM_DELETE_WINDOW", self._close_window)
        self.input_box.focus_set()

    def _on_enter(self, event):
        if not (event.state & 0x1):
            self._send()
            return "break"

    def _send(self):
        text = self.input_box.get("1.0", tk.END).strip()
        if not text:
            return
        self.input_box.delete("1.0", tk.END)
        self._append_chat("You", text)
        self._set_status("⏳ Thinking...", "gray")
        threading.Thread(target=self._call_with_fallback, args=(text,), daemon=True).start()

    # ── Backend: Groq ─────────────────────────────────────────────────────────

    def _call_groq(self, user_text: str, history: list) -> str:
        content = []
        if self.screenshot_b64:
            content.append({
                "type": "image_url",
                "image_url": {"url": f"data:image/png;base64,{self.screenshot_b64}"},
            })
        content.append({"type": "text", "text": user_text})

        messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history + \
                   [{"role": "user", "content": content}]

        resp = requests.post(
            GROQ_URL,
            headers={
                "Authorization": f"Bearer {GROQ_API_KEY}",
                "Content-Type": "application/json",
            },
            json={"model": GROQ_MODEL, "max_tokens": 1024, "messages": messages},
            timeout=30,
        )
        data = resp.json()
        if "error" in data:
            raise RuntimeError(data["error"]["message"])
        return data["choices"][0]["message"]["content"]

    # ── Backend: Ollama ───────────────────────────────────────────────────────

    def _call_ollama(self, user_text: str, history: list) -> str:
        images = [self.screenshot_b64] if self.screenshot_b64 else []
        messages = [{"role": "system", "content": SYSTEM_PROMPT}] + history + \
                   [{"role": "user", "content": user_text, "images": images}]

        resp = requests.post(
            OLLAMA_URL,
            json={"model": OLLAMA_MODEL, "messages": messages, "stream": False},
            timeout=120,
        )
        data = resp.json()
        if "error" in data:
            raise RuntimeError(data["error"])
        return data["message"]["content"]

    # ── Orchestration ─────────────────────────────────────────────────────────

    def _call_with_fallback(self, user_text: str):
        # Flatten history (text only)
        history = []
        for msg in self.conversation[-10:]:
            role = msg["role"]
            content = msg["content"]
            if isinstance(content, list):
                content = " ".join(p["text"] for p in content if p.get("type") == "text")
            history.append({"role": role, "content": content})

        reply = None
        backend_used = None
        error_log = []

        # 1️⃣ Try Groq
        if GROQ_API_KEY:
            try:
                self.root.after(0, lambda: self._set_status("⏳ Trying Groq...", "gray"))
                reply = self._call_groq(user_text, history)
                backend_used = "Groq (Llama 4 Scout)"
            except Exception as e:
                error_log.append(f"Groq failed: {e}")
                print(f"⚠️  {error_log[-1]}")

        # 2️⃣ Fallback: Ollama
        if reply is None:
            try:
                self.root.after(0, lambda: self._set_status("⏳ Trying Ollama (local)...", "gray"))
                reply = self._call_ollama(user_text, history)
                backend_used = "Ollama (local LLaVA)"
            except Exception as e:
                error_log.append(f"Ollama failed: {e}")
                print(f"⚠️  {error_log[-1]}")

        if reply is None:
            err = "\n".join(error_log) or "Both backends failed."
            ollama_hint = (
                "\n\n💡 To set up Ollama:\n"
                "1. brew install ollama\n"
                "2. ollama serve\n"
                "3. ollama pull llava"
            )
            self.root.after(0, lambda: self._append_chat("Error", err + ollama_hint))
            self.root.after(0, lambda: self._set_status("❌ Both backends failed", "red"))
            return

        # Save to history
        self.conversation.append({
            "role": "user",
            "content": [{"type": "text", "text": user_text}],
        })
        self.conversation.append({"role": "assistant", "content": reply})

        status = f"✅ {backend_used}"
        self.root.after(0, lambda: self._append_chat("Assistant", reply))
        self.root.after(0, lambda: self._set_status(status, "#4CAF50"))

    # ── UI helpers ────────────────────────────────────────────────────────────

    def _append_chat(self, sender: str, text: str):
        self.chat_box.configure(state="normal")
        self.chat_box.insert(tk.END, f"\n{sender}:\n{text}\n")
        self.chat_box.configure(state="disabled")
        self.chat_box.see(tk.END)

    def _set_status(self, msg: str, color: str):
        self.status_var.set(msg)
        self.status_label.configure(text_color=color)

    def _clear(self):
        self.conversation = []
        self.chat_box.configure(state="normal")
        self.chat_box.delete("1.0", tk.END)
        self.chat_box.configure(state="disabled")
        threading.Thread(target=self._refresh_screenshot, daemon=True).start()

    def _refresh_screenshot(self):
        sc = self._take_screenshot()
        self.root.after(0, lambda: setattr(self, "screenshot_b64", sc))
        self.root.after(0, lambda: self._set_status("✅ Screen refreshed", "#4CAF50"))

    def _close_window(self):
        if self.window:
            self.window.destroy()
            self.window = None


def main():
    if not GROQ_API_KEY:
        print("\n⚠️   GROQ_API_KEY not set — will go straight to Ollama fallback.")
        print("    Get a free key at: https://console.groq.com/keys\n")

    ctk.set_appearance_mode("dark")
    ctk.set_default_color_theme("blue")

    root = ctk.CTk()
    root.withdraw()
    AssistantApp(root)
    root.mainloop()


if __name__ == "__main__":
    main()



#https://console.groq.com/keyswhat

## In the terminal( the following two lines)
#echo "export GROQ_API_KEY='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'" >> ~/.zshrc
#source ~/.zshrc