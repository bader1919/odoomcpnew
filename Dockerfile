# Dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Clone and install the MCP server
RUN git clone https://github.com/ivnvxd/mcp-server-odoo.git .
RUN pip install -e .

# Expose the port Railway will use
EXPOSE $PORT

# Health check endpoint
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:$PORT/mcp/ || exit 1

# Run the server with HTTP transport
CMD python -m mcp_server_odoo --transport streamable-http --host 0.0.0.0 --port $PORT

---

# railway.json
{
  "build": {
    "builder": "DOCKERFILE"
  },
  "deploy": {
    "healthcheckPath": "/mcp/",
    "healthcheckTimeout": 30,
    "restartPolicyType": "ON_FAILURE"
  }
}

---

# .env.example (DO NOT commit actual credentials)
ODOO_URL=https://www.by-mb.com
ODOO_API_KEY=your-api-key-here
ODOO_USER=your-email@by-mb.com
ODOO_PASSWORD=your-password
ODOO_DB=bymb
ODOO_MCP_TRANSPORT=streamable-http
ODOO_MCP_HOST=0.0.0.0
ODOO_MCP_LOG_LEVEL=INFO

---

# start.sh (production startup script)
#!/bin/bash
set -e

echo "Starting Odoo MCP Server..."
echo "Odoo URL: $ODOO_URL"
echo "Database: $ODOO_DB"
echo "Transport: $ODOO_MCP_TRANSPORT"

# Health check for Odoo connection before starting
if [ -n "$ODOO_URL" ]; then
    echo "Testing Odoo connection..."
    curl -f "$ODOO_URL/web/database/selector" || echo "Warning: Could not reach Odoo instance"
fi

# Start the MCP server
exec python -m mcp_server_odoo --transport streamable-http --host 0.0.0.0 --port ${PORT:-8000}