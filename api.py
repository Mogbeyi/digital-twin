from dotenv import load_dotenv
from openai import OpenAI
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
import json
import os
from pypdf import PdfReader

load_dotenv(override=True)

app = FastAPI(title="Emmy Digital Twin API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


class ChatMessage(BaseModel):
    role: str
    content: str


class ChatRequest(BaseModel):
    message: str
    history: list[ChatMessage] = []


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

    def system_prompt(self):
        return (
            f"You are acting as {self.name} (goes by {self.nickname}). "
            "You answer questions on his website about his career, background, skills, and experience. "
            "Stay true to his voice and preferences.\n\n"
            "IMPORTANT GUARDRAILS:\n"
            "- ONLY answer questions related to Emmy's career, professional background, skills, "
            "experience, education, projects, work history, and technical expertise.\n"
            "- If someone asks you to write stories, poems, code, do homework, answer trivia, "
            "or anything unrelated to Emmy's professional life, politely decline.\n"
            "- For off-topic requests, say something like: \"Hey, I appreciate the creativity, "
            "but I'm really just here to chat about my career and background. "
            "Got any questions about my work or experience?\"\n"
            "- Stay friendly but firm about staying on topic.\n\n"
            "Style guide:\n" + self.style + "\n\n"
            "Core facts (treat as source of truth):\n" + json.dumps(self.facts, indent=2) + "\n\n"
            "Additional context from his LinkedIn PDF:\n" + self.linkedin + "\n\n"
            "Stay in character as Emmy throughout."
        )

    def stream_chat(self, message: str, history: list[dict]):
        messages = [
            {"role": "system", "content": self.system_prompt()},
            *[{"role": m["role"], "content": m["content"]} for m in history],
            {"role": "user", "content": message},
        ]

        stream = self.openai.chat.completions.create(
            model="openai/gpt-oss-120b",
            messages=messages,
            stream=True,
        )

        for chunk in stream:
            if chunk.choices[0].delta.content:
                yield f"data: {json.dumps({'content': chunk.choices[0].delta.content})}\n\n"

        yield "data: [DONE]\n\n"


# Lazy initialization - only create when needed, not at module load
_me_instance = None

def get_me():
    global _me_instance
    if _me_instance is None:
        _me_instance = Me()
    return _me_instance


@app.post("/api/chat")
async def chat(request: ChatRequest):
    me = get_me()
    return StreamingResponse(
        me.stream_chat(request.message, [m.model_dump() for m in request.history]),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
        },
    )


@app.get("/api/health")
async def health():
    return {"status": "ok"}

