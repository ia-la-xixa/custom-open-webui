# 🔄 Sistema de Actualizaciones Automáticas - La Xixa Custom Open WebUI

Este documento explica cómo funciona el sistema de actualizaciones automáticas del repositorio y qué hacer en caso de conflictos.

## 🎯 ¿Qué es esto?

Este fork personalizado de Open WebUI incluye el branding corporativo de La Xixa. Para mantenerlo actualizado con las mejoras del proyecto original, hemos configurado un sistema automático de sincronización.

## 🤖 Sincronización Automática

### Cómo funciona

**Cada lunes a las 9 AM**, una acción automática de GitHub:

1. ✅ Revisa si hay actualizaciones en Open WebUI oficial
2. ✅ Intenta fusionar los cambios automáticamente
3. ✅ Si **no hay conflictos** → Se actualiza automáticamente
4. ⚠️ Si **hay conflictos** → Crea un Pull Request para revisión manual

### Ver el estado

Puedes revisar el estado de las actualizaciones en:

```
GitHub → Actions → "Sync Upstream (Open WebUI)"
```

## ✅ Escenario 1: Actualización Exitosa (Sin Conflictos)

Cuando todo va bien, verás:

- ✅ Un nuevo commit en la rama `main` con el mensaje "chore: Sync with upstream"
- 🔔 (Opcional) Una notificación si tienes configuradas las notificaciones de GitHub
- 🚀 Tu Coolify automáticamente hará deploy de la nueva versión

**No necesitas hacer nada.** El sistema se encarga de todo.

## ⚠️ Escenario 2: Conflictos Detectados

Cuando hay conflictos (por ejemplo, Open WebUI modificó algo que también modificamos para La Xixa):

### Qué verás

1. 📧 Un Pull Request nuevo con el título: **"⚠️ Sync Upstream - Conflictos Detectados"**
2. 📋 Lista de archivos que tienen conflictos
3. 📖 Instrucciones detalladas de cómo resolver

### ⚠️ IMPORTANTE: Si no resuelves el PR

**El sistema es inteligente:** Si hay un PR de conflictos abierto, las siguientes ejecuciones automáticas del lunes **NO crearán nuevos PRs**. El workflow detectará el PR pendiente y saltará la ejecución.

Verás en los logs de GitHub Actions:
```
⚠️ Ya existe un PR de sync abierto: #123
Saltando ejecución hasta que se resuelva el PR existente
```

**Esto significa:**
- ✅ No se acumularán PRs de conflictos
- ✅ Solo tendrás UN PR pendiente a la vez
- ⚠️ Pero NO se sincronizarán nuevas actualizaciones hasta que resuelvas el PR existente

### Qué hacer

**Opción A: Si eres técnico** _(Recomendado)_

```bash
# 1. Descarga el branch con conflictos
git fetch origin
git checkout sync-upstream-conflicts-YYYYMMDD

# 2. Intenta el merge
git merge upstream/main

# 3. Revisa los archivos con conflictos
git status

# 4. Abre los archivos marcados y resuelve los conflictos
# (Busca las marcas <<<<<<, ======, >>>>>>)

# 5. Una vez resueltos
git add .
git commit -m "Resolve upstream sync conflicts"
git push origin sync-upstream-conflicts-YYYYMMDD

# 6. Mergea el Pull Request en GitHub
```

**Opción B: Contratar soporte técnico**

Si no te sientes cómodo resolviendo conflictos, contacta con tu proveedor técnico. El PR contiene toda la información necesaria para que puedan ayudarte.

**Opción C: Forzar nuevo intento (Avanzado)**

Si quieres que el workflow intente de nuevo ignorando el PR existente:

1. Cierra el PR antiguo (sin mergear)
2. Ve a Actions → "Sync Upstream" → "Run workflow"
3. El workflow creará un nuevo PR con el estado actualizado

## 🔙 Sistema de Backup

### Backups automáticos

Cada vez que se intenta una actualización, **se crea un backup automático** de tu código:

```
backup-before-sync-YYYYMMDD-HHMMSS
```

Puedes verlos en GitHub → Branches

### Restaurar desde backup

Si algo sale mal y quieres volver atrás:

```bash
# 1. Lista los backups disponibles
git branch -a | grep backup

# 2. Restaura el backup que necesites
git checkout backup-before-sync-20241124-091500

# 3. Crea una nueva rama desde ese backup
git checkout -b main-restored
git push origin main-restored --force
```

## 🛠️ Herramientas Adicionales

### Script de Patches

Hemos incluido un script que guarda tus cambios de La Xixa como "patches":

```bash
./scripts/save-laxixa-patches.sh
```

Esto crea archivos `.patch` con todos tus cambios personalizados. Úsalo:

- Antes de hacer cambios grandes
- Para documentar qué se modificó exactamente
- Como plan B si necesitas reconstruir desde cero

## 🎛️ Configuración

### Cambiar la frecuencia de sync

Edita `.github/workflows/sync-upstream.yml`:

```yaml
schedule:
  - cron: '0 9 * * 1'  # Lunes 9 AM
```

Ejemplos:
- `'0 9 * * *'` → Diario a las 9 AM
- `'0 9 1 * *'` → Primer día del mes a las 9 AM
- `'0 9 * * 0'` → Domingos a las 9 AM

### Ejecutar manualmente

No tienes que esperar a la sincronización automática:

1. Ve a **GitHub → Actions → "Sync Upstream (Open WebUI)"**
2. Click en **"Run workflow"**
3. Confirma

## 📞 Soporte

### Logs y diagnóstico

Para ver qué pasó en la última sincronización:

1. GitHub → Actions → Última ejecución de "Sync Upstream"
2. Click en el job "sync"
3. Revisa los logs de cada paso

### Problemas comunes

**"No se creó el PR de conflictos"**
- Revisa que tienes el secret `MY_TOKEN` configurado en GitHub
- Ve a Settings → Secrets and variables → Actions

**"El workflow no se ejecuta"**
- GitHub a veces desactiva workflows después de 60 días sin commits
- Ve a Actions y habilítalo manualmente

**"Coolify no hace deploy después del sync"**
- Revisa que tu webhook de Coolify esté activo
- El workflow hace push a `main`, lo que debe disparar el deploy

## ❓ Preguntas Frecuentes

### ¿Qué pasa si hay un PR de conflictos y no lo resuelvo?

El workflow **no creará más PRs** mientras haya uno abierto con la etiqueta `sync-upstream`. Verás en los logs que se salta la ejecución. No se sincronizarán nuevas actualizaciones hasta que cierres o mergees el PR existente.

### ¿Puedo cambiar la frecuencia de sincronización?

Sí, edita `.github/workflows/sync-upstream.yml` línea 6:
- `'0 9 * * 1'` → Lunes 9 AM (actual)
- `'0 9 1 * *'` → Primer día del mes
- `'0 9 * * *'` → Diario

### ¿Qué pasa si cierro un PR de conflictos sin resolver?

El siguiente lunes el workflow intentará de nuevo y creará un nuevo PR. Si los mismos archivos siguen en conflicto, tendrás el mismo problema.

### ¿Puedo desactivar la sincronización automática?

Sí, ve a `.github/workflows/sync-upstream.yml` y comenta o elimina la sección `schedule`. Solo quedará la opción de ejecución manual.

### ¿Los backups se borran automáticamente?

No, las ramas de backup se quedan en el repositorio. Puedes borrarlas manualmente cuando ya no las necesites.

## 📊 Estado Actual

- **Última sincronización manual**: 2024-11-24
- **Versión upstream**: v0.6.38
- **Commits personalizados**: ~10 (branding La Xixa)
- **Backup disponible**: backup-before-merge-20251124

## 🎯 Resumen para No Técnicos

1. ✅ **Cada lunes** el sistema revisa actualizaciones automáticamente
2. ✅ **Si no hay problemas** se actualiza solo
3. ⚠️ **Si hay conflictos** te notifica con un Pull Request
4. 🔙 **Siempre se crea un backup** antes de actualizar
5. 📞 **Si tienes dudas** contacta a tu proveedor técnico con el link del PR

---

🤖 Sistema configurado el 2024-11-24
