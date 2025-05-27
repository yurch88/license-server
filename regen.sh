#!/bin/bash
set -e

CAT_SCRIPT="cat-all.sh"

echo '#!/bin/bash
set -e
' > "$CAT_SCRIPT"

find . \
    -type f \
    \( \
        -name "*.py" -o -name "*.js" -o -name "*.jsx" -o -name "*.ts" -o -name "*.tsx" \
        -o -name "*.css" -o -name "*.json" -o -name "*.html" -o -name "*.conf" \
        -o -name "*.md" -o -name "*.sql" -o -name "Dockerfile" \
        -o -name ".env" -o -name "docker-compose.yml" \
        -o -name "install.sh" -o -name "delete.sh" \
        -o -name "cat-all.sh" -o -name "regen.sh" \
    \) \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./migrations/*.pyc" \
    ! -path "./migrations/__pycache__/*" \
    ! -path "./__pycache__/*" \
    | sort | while read -r file; do
    relpath="${file#./}"
    echo "echo -e '\n========== $relpath =========='" >> $CAT_SCRIPT
    echo "cat \"$relpath\" 2>/dev/null || echo '(нет файла)'" >> $CAT_SCRIPT
done

chmod +x "$CAT_SCRIPT"
echo "[regen.sh] Готово! Сгенерирован $CAT_SCRIPT."
