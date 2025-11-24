#!/bin/bash

###############################################################################
# Script: Guardar Cambios de La Xixa como Patches
#
# Este script extrae todos los cambios personalizados de La Xixa como patches
# que pueden ser reaplicados más tarde si es necesario
###############################################################################

set -e

PATCHES_DIR="patches-laxixa"
BACKUP_DIR="${PATCHES_DIR}/backup-$(date +%Y%m%d-%H%M%S)"

echo "🔍 Buscando commits personalizados de La Xixa..."

# Crear directorio de patches
mkdir -p "$BACKUP_DIR"

# Encontrar el commit base común con upstream
BASE_COMMIT=$(git merge-base HEAD upstream/main 2>/dev/null || git merge-base HEAD origin/main)

echo "📍 Base commit: $BASE_COMMIT"

# Obtener lista de commits personalizados
CUSTOM_COMMITS=$(git log --oneline ${BASE_COMMIT}..HEAD --no-merges | grep -i "la.xixa\|branding\|corporate" || true)

if [ -z "$CUSTOM_COMMITS" ]; then
    echo "⚠️  No se encontraron commits personalizados de La Xixa"
    echo "💡 Tip: Los commits deben contener 'La Xixa', 'branding' o 'corporate' en el mensaje"
    exit 1
fi

echo ""
echo "📋 Commits personalizados encontrados:"
echo "$CUSTOM_COMMITS"
echo ""

# Crear patches para cada commit personalizado
PATCH_COUNT=0
git log ${BASE_COMMIT}..HEAD --oneline --no-merges | grep -i "la.xixa\|branding\|corporate" | while read -r line; do
    COMMIT_HASH=$(echo "$line" | awk '{print $1}')
    PATCH_COUNT=$((PATCH_COUNT + 1))

    PATCH_FILE="${BACKUP_DIR}/$(printf '%04d' $PATCH_COUNT)-${COMMIT_HASH}.patch"
    git format-patch -1 "$COMMIT_HASH" --stdout > "$PATCH_FILE"

    echo "✅ Creado: $PATCH_FILE"
done

# Crear un archivo README con instrucciones
cat > "${BACKUP_DIR}/README.md" << 'EOF'
# 📦 Patches de La Xixa

Este directorio contiene los cambios personalizados de La Xixa extraídos como patches.

## 🔄 Cómo aplicar estos patches

Si necesitas reaplicar estos cambios sobre una versión limpia del upstream:

```bash
# 1. Ve a una rama con la versión limpia del upstream
git checkout -b nueva-rama upstream/main

# 2. Aplica los patches en orden
for patch in patches-laxixa/backup-*/0*.patch; do
    echo "Aplicando: $patch"
    git am < "$patch" || {
        echo "❌ Conflicto al aplicar $patch"
        echo "Resuelve los conflictos y continúa con: git am --continue"
        break
    }
done
```

## 📝 Notas

- Los patches están numerados en orden de aplicación
- Si un patch falla, resuélvelo manualmente y usa `git am --continue`
- Los archivos `.patch` son archivos de texto que puedes editar si es necesario

## 🗓️ Creado

- Fecha: $(date)
- Base commit: $BASE_COMMIT
EOF

echo ""
echo "✅ Patches guardados en: $BACKUP_DIR"
echo "📖 Lee ${BACKUP_DIR}/README.md para instrucciones"
echo ""
echo "🎯 Siguiente paso: Commitea estos patches al repositorio"
echo "   git add $PATCHES_DIR"
echo "   git commit -m 'chore: Backup patches de La Xixa'"
