#!/bin/bash
set -e

CAT_SCRIPT="cat-all.sh"

echo '#!/bin/bash
set -e
' > "$CAT_SCRIPT"

find . -type f \
    ! -path "./.git/*" \
    ! -path "./node_modules/*" \
    ! -path "./migrations/*.pyc" \
    ! -path "./migrations/__pycache__/*" \
    ! -path "./__pycache__/*" \
    ! -name "cat-all.sh" \
    | sort | while read -r file; do
    relpath="${file#./}"
    echo "echo -e '\n========== $relpath =========='" >> $CAT_SCRIPT
    echo "cat \"$relpath\" 2>/dev/null || echo '(нет файла)'" >> $CAT_SCRIPT
done

chmod +x "$CAT_SCRIPT"
echo "[regen.sh] Готово! Сгенерирован $CAT_SCRIPT."
