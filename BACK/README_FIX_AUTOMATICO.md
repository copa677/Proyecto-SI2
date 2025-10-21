# 🔧 Fix Automático del Sistema de Permisos

## ✅ Solución para TODO el Equipo

Este fix se aplica **automáticamente** cuando cualquier miembro del equipo actualiza el código y ejecuta las migraciones de Django. No requiere pasos manuales adicionales.

## 📋 Para Nuevos Desarrolladores o Después de Pull

Cuando hagas `git pull` y obtengas estos cambios, simplemente ejecuta:

```bash
cd BACK
python manage.py migrate
```

Eso es todo! ✅

## 🎯 Qué Hace Este Fix

### Problema Anterior
```
ERROR: duplicar valor da chave viola a restrição de unicidade "permisos_pkey"
```

Cuando intentabas asignar permisos dos veces al mismo usuario/ventana, el sistema fallaba.

### Solución Implementada
El stored procedure `insertar_permisos` ahora:
- ✅ **INSERTA** si el permiso no existe
- ✅ **ACTUALIZA** si el permiso ya existe
- ✅ Se aplica automáticamente con Django migrations

## 📁 Archivos del Fix

### Migration de Django (Automática)
- `usuarios/migrations/0002_update_insertar_permisos_procedure.py`
  - Se ejecuta automáticamente con `python manage.py migrate`
  - Todos los desarrolladores la obtienen al hacer `git pull`

### Scripts de Respaldo (Opcionales)
- `fix_insertar_permisos.sql` - Versión SQL pura (si prefieres ejecutarlo manualmente)
- `apply_fix_insertar_permisos.py` - Script Python independiente (alternativa)
- `verificar_estructura_tablas.py` - Para verificar estructura de tablas

## 🚀 Flujo de Trabajo del Equipo

### Desarrollador que crea el fix (ya hecho)
```bash
git add .
git commit -m "Fix: Actualizar stored procedure insertar_permisos para INSERT/UPDATE automático"
git push
```

### Otros desarrolladores
```bash
git pull
cd BACK
python manage.py migrate   # ← Aplica el fix automáticamente
```

## ✨ Cambios Técnicos

### ANTES (causaba error)
```sql
INSERT INTO permisos(...)
VALUES (...);  -- Error si ya existe
```

### DESPUÉS (sin error)
```sql
-- Verifica si existe
SELECT id_permiso INTO v_permiso_existente
FROM permisos
WHERE id_usuario = v_id_usuario AND vista = p_ventana;

IF v_permiso_existente IS NOT NULL THEN
    UPDATE permisos SET ...;  -- Actualiza
ELSE
    INSERT INTO permisos ...;  -- Crea nuevo
END IF;
```

## 🧪 Probar que Funciona

Desde Postman o frontend:

### Primera vez (INSERT)
```
POST http://localhost:8000/api/usuario/permisos
Body: {
  "name_user": "jerson",
  "ventana": "Personal",
  "insertar": true,
  "editar": true,
  "eliminar": false,
  "ver": true
}
```
✅ Respuesta: `{"mensaje": "Permiso agregado con éxito"}`

### Segunda vez (UPDATE - antes fallaba, ahora funciona)
```
POST http://localhost:8000/api/usuario/permisos
Body: {
  "name_user": "jerson",
  "ventana": "Personal",
  "insertar": true,
  "editar": false,  ← Cambiado
  "eliminar": true,  ← Cambiado
  "ver": true
}
```
✅ Respuesta: `{"mensaje": "Permiso agregado con éxito"}` (pero hizo UPDATE internamente)

## 📊 Verificar en la Base de Datos

```sql
-- Ver que el procedimiento existe
SELECT proname, prokind 
FROM pg_proc 
WHERE proname = 'insertar_permisos';

-- Resultado esperado:
-- proname            | prokind
-- insertar_permisos  | p (PROCEDURE)

-- Ver permisos de un usuario
SELECT * FROM permisos 
WHERE id_usuario = (SELECT id FROM usuarios WHERE name_user = 'jerson');
```

## ⚠️ Troubleshooting

### Error: "No migrations to apply"
✅ **Normal** - El fix ya está aplicado en tu base de datos

### Error: "relation 'permisos' does not exist"
❌ **Problema** - Tu base de datos no tiene la tabla permisos
**Solución:** Ejecuta el script SQL completo de la base de datos (rpv2.0.sql o rp.sql)

### Error: "column 'id_usuario' does not exist"
❌ **Problema** - La tabla permisos usa un nombre diferente para la columna
**Solución:** Ejecuta el script de verificación:
```bash
python verificar_estructura_tablas.py
```
Luego ajusta los nombres de columnas en la migration según la salida

## 📝 Notas para el Equipo

1. **No ejecutar scripts SQL manualmente** - Las migrations de Django lo hacen automáticamente
2. **Siempre hacer `migrate` después de `pull`** - Para aplicar cambios de BD
3. **El procedimiento es idempotente** - Se puede ejecutar múltiples veces sin problemas
4. **Compatible con versiones anteriores** - No rompe funcionalidad existente

## 🎯 Integración con Sistema de Permisos

Este fix es parte del sistema de permisos consolidado:

- ✅ Frontend usa `PermissionService` unificado
- ✅ Backend usa `insertar_permisos` procedure mejorado
- ✅ Soporta roles: Administrador, Supervisor, Operario
- ✅ Permisos por ventana: Personal, Inventario, Lotes, etc.
- ✅ Acciones: insertar, editar, eliminar, ver

Ver documentación completa en:
- `FRONT/SISTEMA_PERMISOS_CONSOLIDADO.md`
- `FRONT/CHECKLIST_MIGRACION_PERMISOS.md`

---

**Autor:** Sistema de Permisos Consolidado  
**Versión:** 2.0  
**Última actualización:** 2025-10-20  
**Requiere intervención manual:** ❌ NO - Totalmente automático con Django migrations
