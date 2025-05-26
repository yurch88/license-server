# License Server

Минималистичная платформа на FastAPI + React + PostgreSQL для централизованной генерации и управления лицензиями (JWT, PDF-экспорт).  
Всё разворачивается и работает через Docker Compose.  
Фронтенд: Vite + React, Бэкенд: FastAPI, БД: PostgreSQL.  
Управление лицензиями, логин (JWT), мгновенный запуск, полный автодеплой.  
См. install.sh для автоустановки.

## Структура

```
license-server/
├── backend/ # FastAPI backend
│ ├── app/
│ │ ├── api.py
│ │ └── main.py
│ ├── Dockerfile
│ └── requirements.txt
├── frontend/ # Vite + React frontend
│ ├── src/
│ │ ├── App.jsx, Dashboard.jsx, Login.jsx, main.jsx, App.css, index.css
│ ├── index.html
│ ├── package.json
│ ├── vite.config.js
│ ├── Dockerfile
│ └── nginx.conf
├── docker-compose.yml
├── install.sh
├── delete.sh
├── cat-all.sh
├── regen.sh
├── .env
└── migrations/
```
## Быстрый старт

```bash
./install.sh
cd frontend && npm install
cd .. && docker-compose build
docker-compose up -d

##Git команды для коммита и пуша
git init
git remote add origin git@github.com:yurch88/license-server.git
git add .
git commit -m "feat: минимальный production-ready License Server (FastAPI + React)"
git branch -M main
git push -u origin main --force
