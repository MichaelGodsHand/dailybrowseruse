# Use Python 3.11 slim image as base
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    wget \
    gnupg \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Google Chrome
RUN wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb && \
    apt-get update && \
    apt-get install -y ./google-chrome-stable_current_amd64.deb && \
    rm -f google-chrome-stable_current_amd64.deb && \
    rm -rf /var/lib/apt/lists/*

# Verify Chrome installation
RUN google-chrome --version

# Copy requirements first for better caching
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Install Playwright browsers (chromium)
RUN playwright install chromium && \
    playwright install-deps chromium

# Copy setup script and make it executable
COPY setup_chrome.sh .
RUN chmod +x setup_chrome.sh

# Run setup script (installs additional dependencies)
RUN ./setup_chrome.sh || true  # Continue even if script fails (Chrome already installed)

# Copy application code
COPY . .

# Set environment variables
ENV PYTHONUNBUFFERED=1
ENV HEADLESS_MODE=true
ENV PORT=8080

# Expose port
EXPOSE 8080

# Run the FastAPI application
# For Cloud Run, use uvicorn directly (ngrok in fastapi_agent.py __main__ won't work in Cloud Run)
# Alternative: CMD ["python", "fastapi_agent.py"] (but ngrok will fail in Cloud Run)
CMD ["python", "-m", "uvicorn", "fastapi_agent:app", "--host", "0.0.0.0", "--port", "8080"]

