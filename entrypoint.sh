#!/bin/bash
nginx
cd /app/backend/src/sample && gunicorn --bind 0.0.0.0:8001 app:app