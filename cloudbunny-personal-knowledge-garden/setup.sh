#!/bin/bash

# Knowledge Garden Setup Script
# This script initializes all services and downloads required models

set -e

echo "🌱 Cloudbunny's Knowledge Garden - Setup Script"
echo "=================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if .env exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  No .env file found. Creating from .env.example...${NC}"
    cp .env.example .env
    echo -e "${RED}⚠️  IMPORTANT: Edit .env and update all passwords and keys!${NC}"
    echo ""
    read -p "Press Enter to continue after updating .env..."
fi

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p n8n/workflows
mkdir -p n8n/backups
mkdir -p scripts
mkdir -p worker
mkdir -p nginx

# Start services
echo ""
echo "🚀 Starting services..."
docker-compose up -d postgres qdrant

echo "⏳ Waiting for databases to be ready..."
sleep 10

# Build and start n8n with OCR/PDF tools
echo ""
echo "🔧 Building n8n with OCR and PDF support..."
echo "   (This may take a few minutes on first run)"
docker-compose build n8n
docker-compose up -d n8n

echo "⏳ Waiting for n8n to start..."
sleep 10

# Start Ollama
echo ""
echo "🤖 Starting Ollama..."
docker-compose up -d ollama

echo "⏳ Waiting for Ollama to start..."
sleep 15

# Pull Ollama models
echo ""
echo "📥 Pulling Ollama models (this may take several minutes)..."
echo "   - llama3.2 (for answering questions)"
echo "   - nomic-embed-text (for embeddings)"

docker-compose exec -T ollama ollama pull llama3.2
docker-compose exec -T ollama ollama pull nomic-embed-text

echo -e "${GREEN}✅ Ollama models downloaded${NC}"

# Create Qdrant collection
echo ""
echo "📊 Creating Qdrant collection..."
sleep 5

curl -X PUT http://localhost:6333/collections/garden \
  -H 'Content-Type: application/json' \
  -d '{
    "vectors": {
      "size": 768,
      "distance": "Cosine"
    }
  }' || echo "Collection may already exist"

echo -e "${GREEN}✅ Qdrant collection created${NC}"

# Start remaining services
echo ""
echo "🔧 Starting remaining services..."
docker-compose up -d

echo ""
echo "⏳ Waiting for all services to be ready..."
sleep 20

# Show status
echo ""
echo "📊 Service Status:"
docker-compose ps

echo ""
echo -e "${GREEN}✅ Setup complete!${NC}"
echo ""
echo "📝 Next steps:"
echo "   1. Access n8n at: https://$(grep N8N_HOST .env | cut -d '=' -f2):5678"
echo "   2. Import the workflow: enhanced_knowledge_garden.json"
echo "   3. Set up your Telegram bot token in n8n credentials"
echo "   4. Activate the workflow"
echo ""
echo "🤖 Create a Telegram bot:"
echo "   1. Message @BotFather on Telegram"
echo "   2. Use /newbot command"
echo "   3. Copy the bot token"
echo "   4. Add it to n8n credentials"
echo ""
echo "📖 Documentation: Check README.md for more details"
echo ""
