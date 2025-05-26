#!/bin/bash
set -e

echo -e '
========== .env =========='
cat ".env" 2>/dev/null || echo '(нет файла)'

echo -e '
========== docker-compose.yml =========='
cat "docker-compose.yml" 2>/dev/null || echo '(нет файла)'

echo -e '
========== cat-all.sh =========='
cat "cat-all.sh" 2>/dev/null || echo '(нет файла)'

echo -e '
========== delete.sh =========='
cat "delete.sh" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/requirements.txt =========='
cat "backend/requirements.txt" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/Dockerfile =========='
cat "backend/Dockerfile" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/app/api.py =========='
cat "backend/app/api.py" 2>/dev/null || echo '(нет файла)'

echo -e '
========== backend/app/main.py =========='
cat "backend/app/main.py" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/Dockerfile =========='
cat "frontend/Dockerfile" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/nginx.conf =========='
cat "frontend/nginx.conf" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/package.json =========='
cat "frontend/package.json" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/vite.config.js =========='
cat "frontend/vite.config.js" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/index.html =========='
cat "frontend/index.html" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/App.jsx =========='
cat "frontend/src/App.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/Dashboard.jsx =========='
cat "frontend/src/Dashboard.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/Login.jsx =========='
cat "frontend/src/Login.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/main.jsx =========='
cat "frontend/src/main.jsx" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/App.css =========='
cat "frontend/src/App.css" 2>/dev/null || echo '(нет файла)'

echo -e '
========== frontend/src/index.css =========='
cat "frontend/src/index.css" 2>/dev/null || echo '(нет файла)'
