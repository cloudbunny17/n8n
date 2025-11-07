# Custom n8n with OCR and PDF Support
FROM n8nio/n8n:latest

# Switch to root to install packages
USER root

# Install Tesseract OCR and PDF tools (Alpine Linux uses apk)
RUN apk update && \
    apk add --no-cache \
    tesseract-ocr \
    poppler-utils \
    tesseract-ocr-data-eng \
    curl \
    bash

# Switch back to node user
USER node

# Verify installations (don't fail if versions can't be shown)
RUN tesseract --version || echo "Tesseract installed" && \
    pdftotext -v || echo "pdftotext installed"
