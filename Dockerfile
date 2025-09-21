# Dockerfile for Odoo MCP Server on Railway
FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Clone and install the MCP server
RUN git clone https://github.com/ivnvxd/mcp-server-odoo.git . && \
    pip install --no-cache-dir -e .

# Create startup script to handle connection testing
RUN echo '#!/bin/bash\n\
echo "Testing Odoo connection..."\n\
curl -f "$ODOO_URL/web/database/selector" || echo "Warning: Odoo not accessible"\n\
echo "Starting MCP server..."\n\
exec python -m mcp_server_odoo --transport streamable-http --host 0.0.0.0 --port ${PORT:-8000}' > start.sh && \
    chmod +x start.sh

# Create non-root user for security
RUN useradd -m -u 1000 mcpuser && \
    chown -R mcpuser:mcpuser /app
USER mcpuser

# Expose port (Railway will set $PORT)
EXPOSE $PORT

# Health check for the MCP server endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:${PORT:-8000}/mcp/ || exit 1

# Start with custom script
CMD ["./start.sh"]