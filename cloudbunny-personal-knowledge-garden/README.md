# 🌱 Cloudbunny's Knowledge Garden - AI-Powered Personal Knowledge Management

A self-hosted, privacy-first personal knowledge management system powered by AI. Store and recall information from **text, voice, images, PDFs, and URLs** - all through Telegram.

![License](https://img.shields.io/badge/license-MIT-blue.svg)
![Docker](https://img.shields.io/badge/docker-required-blue.svg)
![n8n](https://img.shields.io/badge/n8n-workflow-orange.svg)

## ✨ Features

- 📝 **Text Messages** - Direct storage of notes and ideas
- 🎤 **Voice Messages** - Automatic transcription via Whisper AI
- 📸 **Images with Text** - OCR extraction via Tesseract
- 📄 **PDF Documents** - Full text extraction and indexing
- 🔗 **URLs** - Web scraping and content extraction
- 🔍 **Smart Retrieval** - Semantic search using vector embeddings
- 🤖 **AI Answers** - LLM-synthesized responses from your notes

## 🎯 Why Knowledge Garden?

| Feature                 | Knowledge Garden | Mem.ai   | Notion AI  | Obsidian |
|-------------------------|-----------------|-----------|------------|----------|
| **Cost**                | **$0/month**      | $15-30  | $10-20     | Free-$10 |
| **Privacy**             | ✅ Self-hosted    | ❌ Cloud | ❌ Cloud   | ✅ Local |
| **Voice Transcription** | ✅ Whisper        | ✅ | ❌  | ❌         |
| **Image OCR**           | ✅ Tesseract      | ❌ | ❌  | ❌         |
| **PDF Extraction**      | ✅ Built-in       | ✅ | ✅  | Plugin     |
| **Telegram Interface**  | ✅                | ❌ | ❌  | ❌         |
| **Semantic Search**     | ✅ Vector DB      | ✅ | ✅  | Limited    |

## 🏗️ Architecture

```
┌─────────────┐
│  Telegram   │ ← Your interface
└──────┬──────┘
       │
┌──────▼──────────────────────────────────────┐
│           n8n Workflow Engine               │
│  ┌────────────────────────────────────┐     │
│  │  Content Router (IF nodes)         │     │
│  │  ├─ Text      → Direct             │     │
│  │  ├─ Voice     → Whisper → Text     │     │
│  │  ├─ Image     → OCR → Text         │     │
│  │  ├─ PDF       → Extract → Text     │     │
│  │  └─ URL       → Scrape → Text      │     │
│  └────────────────────────────────────┘     │
│  ┌────────────────────────────────────┐     │
│  │  Processing Pipeline               │     │
│  │  ├─ Chunking (500 chars)           │     │
│  │  ├─ Embedding (Ollama)             │     │
│  │  └─ Storage (Qdrant)               │     │
│  └────────────────────────────────────┘     │
└─────────────────────────────────────────────┘
       │                    │
┌──────▼──────┐      ┌──────▼──────┐
│   Qdrant    │      │   Ollama    │
│  (Vectors)  │      │ (LLM+Embed) │
└─────────────┘      └─────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose (v2.0+)
- 8GB+ RAM (4GB minimum)
- 20GB+ disk space
- Domain name or ngrok (for Telegram webhooks)

### 1. Clone Repository

```bash
git clone https://github.com/cloudbunny17/n8n.git
cd cloudbunny-personal-knowledge-garden
```

### 2. Configure Environment

```bash
cp .env.example .env
nano .env
```

**Update these values:**
```env
N8N_HOST=your-domain.com              # Your domain or ngrok URL
N8N_ENCRYPTION_KEY=<generate-random>  # Run: openssl rand -hex 32
N8N_BASIC_AUTH_PASSWORD=<password>    # Choose strong password
POSTGRES_PASSWORD=<password>          # Choose strong password
```

### 3. Run Setup

```bash
chmod +x setup.sh
./setup.sh
```

This will:
- ✅ Start all services (n8n, Ollama, Qdrant, Whisper, PostgreSQL)
- ✅ Download AI models (~4GB)
- ✅ Initialize vector database
- ✅ Install OCR tools

**Time:** ~10-15 minutes

### 4. Create Telegram Bot

1. Message [@BotFather](https://t.me/BotFather) on Telegram
2. Send `/newbot` command
3. Follow prompts to name your bot
4. **Copy the bot token**

### 5. Import Workflow

1. Go to `https://your-domain:5678`
2. Login with credentials from `.env`
3. Click **Import from File**
4. Upload `Cloudbunny's - Knowledge Garden.json`
5. Add Telegram credentials:
   - Click **Credentials** → **Add Credential**
   - Select **Telegram API**
   - Paste your bot token
   - Save as `Telegram Bot`
6. Click **Active** toggle ✅

### 6. Test Your Bot!

Send messages to your Telegram bot:

```
👤 You: "Remember: The meeting is Friday at 3pm"
🤖 Bot: 🌱 Stored (text): Remember: The meeting is Friday...

👤 You: [Voice message about project deadline]
🤖 Bot: 🌱 Stored (voice): [Voice transcription]: The project...

👤 You: "When is the meeting?"
🤖 Bot: 🌿 The meeting is scheduled for Friday at 3pm.
```

## 📖 Usage

### Storing Content

Simply send any content type to your bot:

- **Text:** "Remember: Buy groceries"
- **Voice:** Record a voice message
- **Image:** Send a photo with text (screenshot, whiteboard, document)
- **PDF:** Upload any PDF document
- **URL:** Send a web link

### Retrieving Information

Ask questions naturally:

- "What did I save about the meeting?"
- "Find my notes about groceries"
- "Tell me about the project deadline"
- "What was in that PDF I uploaded?"
- "Show me everything about AI"

The bot will:
1. Search semantically across ALL your notes
2. Find relevant content (regardless of original format)
3. Synthesize an answer using AI

## 🔧 Configuration

### Change Whisper Model

Edit `.env`:
```env
WHISPER_MODEL=base  # Options: tiny, base, small, medium, large
```

Restart:
```bash
docker-compose restart whisper
```

### Change LLM Model

Edit workflow node "🤖 Answer":
```javascript
{ model: 'llama3.2', ... }
// Or try: mistral, llama2, codellama
```

Pull new model:
```bash
docker-compose exec ollama ollama pull mistral
```

### Add OCR Languages if required

```bash
docker-compose exec -u root n8n apk add tesseract-ocr-data-fra  # French
docker-compose exec -u root n8n apk add tesseract-ocr-data-spa  # Spanish
```

## 📊 Services

| Service | Port | Purpose |
|---------|------|---------|
| n8n | 5678 | Workflow automation UI |
| Ollama | 11434 | LLM & embeddings |
| Qdrant | 6333 | Vector database |
| Whisper | 8000 | Speech-to-text |
| PostgreSQL | 5432 | n8n database |

## 🐛 Troubleshooting

### Voice transcription not working

```bash
# Check Whisper is running
docker-compose ps whisper
docker-compose logs whisper

# Restart if needed
docker-compose restart whisper
```

### OCR/PDF not working

```bash
# Install tools
docker-compose exec -u root n8n apk add tesseract-ocr-data-eng poppler-utils

# Verify
docker-compose exec n8n tesseract --version
docker-compose exec n8n pdftotext -v
```

### Services not starting

```bash
# Check logs
docker-compose logs

# Check disk space
df -h

# Restart everything
docker-compose down
docker-compose up -d
```

### Out of memory

1. Use smaller models:
   - Whisper: `WHISPER_MODEL=tiny`
   - Ollama: `ollama pull llama2:7b`
2. Increase Docker memory limit

## 🔒 Security

- ✅ All data stored locally
- ✅ No external API calls (except Telegram)
- ✅ Encrypted credentials
- ✅ Network isolation via Docker
- ✅ Optional SSL via nginx

**Best practices:**
- Change all default passwords
- Use strong encryption key
- Set up firewall rules
- Enable SSL in production
- Regular backups

## 💾 Backup

```bash
# Backup Qdrant (your notes)
docker run --rm -v kg_qdrant:/data -v $(pwd)/backups:/backup alpine \
  tar czf /backup/qdrant-$(date +%Y%m%d).tar.gz /data

# Backup n8n workflows
docker run --rm -v kg_n8n_data:/data -v $(pwd)/backups:/backup alpine \
  tar czf /backup/n8n-$(date +%Y%m%d).tar.gz /data
```

## 📄 License

MIT License - See [LICENSE](LICENSE) file

## 🙏 Acknowledgments

Built with:
- [n8n](https://n8n.io/) - Workflow automation
- [Ollama](https://ollama.ai/) - Local LLM
- [Qdrant](https://qdrant.tech/) - Vector database
- [Whisper](https://github.com/openai/whisper) - Speech recognition
- [Tesseract](https://github.com/tesseract-ocr/tesseract) - OCR

## 📞 Support

- 📖 [Documentation](README.md)
- 🐛 [Issues](https://github.com/cloudbunny17/n8n/issues)

---

**Star ⭐ this repo if you find it useful!**

<div align="center">

**Made with ❤️ and lots of coffee**

[Request Feature](https://github.com/cloudbunny17/n8n/issues) · 

</div>
