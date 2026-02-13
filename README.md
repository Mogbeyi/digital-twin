# Digital Twin

An AI-powered digital twin that answers questions about me using LLMs.

## Live Demo

- **Frontend:** https://dxvan08o78ik2.cloudfront.net
- **API:** https://b95g7jm5br.us-east-1.awsapprunner.com

## Architecture

```
┌─────────────┐      ┌─────────────┐      ┌─────────────┐
│  CloudFront │ ──── │   Next.js   │      │    Grok     │
│    (CDN)    │      │  (S3 SSG)   │      │    (LLM)    │
└─────────────┘      └─────────────┘      └─────────────┘
                            │                    ▲
                            ▼                    │
                     ┌─────────────┐             │
                     │  App Runner │ ────────────┘
                     │  (FastAPI)  │
                     └─────────────┘
```

## Local Development

### Prerequisites

- Python 3.11+
- Node.js 18+
- [uv](https://github.com/astral-sh/uv) (recommended) or pip

### Backend (FastAPI)

```bash
# Install dependencies
pip install -r requirements.txt

# Set environment variables
cp .env.example .env  # Edit with your GROK_API_KEY

# Run API
uvicorn api:app --reload
```

### Backend (Gradio - for testing)

```bash
pip install -r requirements-dev.txt
python app.py
```

### Frontend (Next.js)

```bash
cd frontend
npm install
npm run dev
```

## Deployment

Infrastructure is managed with Terraform. See [`infra/`](./infra) for details.

```bash
cd infra
terraform init
terraform apply
```

CI/CD is handled by GitHub Actions - push to `main` to deploy.

## Project Structure

```
├── api.py              # FastAPI production API
├── app.py              # Gradio dev interface
├── me/                 # Personal data (facts, style, resume)
├── frontend/           # Next.js chat UI
├── infra/              # Terraform IaC
└── .github/workflows/  # CI/CD pipelines
```

## Environment Variables

| Variable        | Description                                 |
| --------------- | ------------------------------------------- |
| `GROK_API_KEY`  | API key for Grok/xAI                        |
| `GROK_BASE_URL` | API base URL (default: https://api.x.ai/v1) |
