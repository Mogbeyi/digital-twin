from dotenv import load_dotenv
from openai import OpenAI
import json
import os
from pypdf import PdfReader
import gradio as gr

load_dotenv(override=True)


class Me:
    def __init__(self):
        self.facts = self.load_facts()
        self.name = self.facts.get("full_name", "Mogbeyi Emmanuel Wenyinmi")
        self.nickname = self.facts.get("name", self.name)
        self.style = self.load_style()
        self.linkedin = self.load_linkedin_text("me/Wenyinmi.pdf")
        self.openai = OpenAI(
            api_key=os.getenv("GROQ_API_KEY"),
            base_url=os.getenv("GROQ_BASE_URL"),
        )

    def load_facts(self):
        with open("me/facts.json", "r", encoding="utf-8") as f:
            return json.load(f)

    def load_style(self):
        with open("me/style.txt", "r", encoding="utf-8") as f:
            return f.read().strip()

    def load_linkedin_text(self, path):
        reader = PdfReader(path)
        text = ""
        for page in reader.pages:
            page_text = page.extract_text()
            if page_text:
                text += page_text
        return text

    def _delta_to_text(self, delta):
        """Normalize streaming delta content into a plain string."""
        if not delta:
            return ""
        if isinstance(delta, str):
            return delta
        if isinstance(delta, list):
            parts = []
            for item in delta:
                if isinstance(item, dict):
                    # OpenAI-style content block: {"type": "text", "text": {"value": "..."}}
                    text_obj = item.get("text") or {}
                    parts.append(text_obj.get("value", ""))
                else:
                    parts.append(str(item))
            return "".join(parts)
        return str(delta)

    def system_prompt(self):
        return (
            f"You are acting as {self.name} (goes by {self.nickname}). "
            "You answer questions on his website about his career, background, skills, and experience. "
            "Stay true to his voice and preferences.\n\n"
            "Style guide:\n" + self.style + "\n\n"
            "Core facts (treat as source of truth):\n" + json.dumps(self.facts, indent=2) + "\n\n"
            "Additional context from his LinkedIn PDF:\n" + self.linkedin + "\n\n"
            "Stay in character as Emmy throughout."
        )

    def chat(self, message, history):
        messages = [
            {"role": "system", "content": self.system_prompt()},
            *history,
            {"role": "user", "content": message},
        ]

        stream = self.openai.chat.completions.create(
            model="llama-3.3-70b-versatile",
            messages=messages,
            stream=True,
        )

        full_response = ""
        for chunk in stream:
            delta = self._delta_to_text(chunk.choices[0].delta.content)
            if delta:
                full_response += delta
                yield full_response

        # Fallback: if nothing was streamed (some providers send empty deltas), do a non-streaming call.
        if not full_response:
            fallback = self.openai.chat.completions.create(
                model="llama-3.3-70b-versatile",
                messages=messages,
                stream=False,
            )
            content = fallback.choices[0].message.content
            # Yield once so Gradio shows the reply in streaming mode.
            yield content
            return content

        return full_response


if __name__ == "__main__":
    me = Me()
    gr.ChatInterface(me.chat, type="messages").launch()
