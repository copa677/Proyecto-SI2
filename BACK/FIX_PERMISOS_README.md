# Fix para Error de Duplicación de Permisos

## Problema
```
ERRO: duplicar valor da chave viola a restrição de unicidade "permisos_pkey"
DETAIL: Chave (id_permiso)=(6) já existe.
```

## Causa
El stored procedure `insertar_permisos` solo hace INSERT, causando error cuando se intenta asignar permisos por segunda vez al mismo usuario/ventana.

## Solución
Actualizar el procedimiento para que haga UPDATE si el permiso ya existe, o INSERT si no existe.

## Cómo Aplicar el Fix

### Opción 1: Usando Python (Recomendado)

Desde el directorio `BACK`, ejecuta:

```bash
python apply_fix_insertar_permisos.py
```

Este script automáticamente:
1. Elimina versiones anteriores del procedimiento
2. Crea el nuevo PROCEDURE con lógica INSERT/UPDATE
3. Verifica que se creó correctamente

### Opción 2: Usando SQL Directo

Ejecuta el archivo `fix_insertar_permisos.sql` en tu cliente PostgreSQL:

```bash
psql -U tu_usuario -d textiltech -f fix_insertar_permisos.sql
```

O desde pgAdmin/DBeaver, abre y ejecuta el contenido del archivo.

## Verificación

Después de aplicar el fix, prueba asignar permisos:

### Desde Postman
```
POST http://localhost:8000/api/usuario/permisos
Headers: 
  Content-Type: application/json
  Authorization: Bearer {tu_token}

Body:
{
  "name_user": "jerson",
  "ventana": "Personal",
  "insertar": true,
  "editar": true,
  "eliminar": true,
  "ver": true
}
```

**Primera vez:** Creará el permiso
**Segunda vez:** Actualizará el permiso (sin error)

## Qué Cambió

### ANTES (causaba error):
```sql
-- Solo INSERT
INSERT INTO permisos(id_user, insertar, editar, eliminar, ver, vista)
VALUES (...);
```

### DESPUÉS (sin error):
```sql
-- Verifica si existe
IF EXISTS (...) THEN
    UPDATE permisos SET ... WHERE ...;  -- Actualiza
ELSE
    INSERT INTO permisos VALUES (...);   -- Crea nuevo
END IF;
```

## Comportamiento del PROCEDURE Actualizado

El procedimiento `insertar_permisos` ahora:

1. **Busca el usuario** por `name_user`
2. **Verifica si ya existe** un permiso para ese usuario y ventana
3. **Si existe:** Actualiza los valores de insertar/editar/eliminar/ver
4. **Si no existe:** Crea un nuevo registro de permiso

## Notas Técnicas

- **Tipo:** PROCEDURE (no FUNCTION)
- **Uso:** `CALL insertar_permisos(...)`
- **Lenguaje:** PL/pgSQL
- **Compatible con:** PostgreSQL 11+

## Troubleshooting

### Error: "insertar_permisos não é uma função"
**Causa:** El procedimiento no existe en la base de datos
**Solución:** Ejecuta el script de fix

### Error: "Usuario X no encontrado"
**Causa:** El username no existe en la tabla usuarios
**Solución:** Verifica el nombre de usuario correcto

### Error al conectar a la base de datos
**Causa:** Variables de entorno no configuradas
**Solución:** Asegúrate de tener un archivo `.env` con:
```
DB_NAME=textiltech
DB_USER=tu_usuario
DB_PASSWORD=tu_password
DB_HOST=localhost
DB_PORT=5432
```

## Archivos Relacionados

- `fix_insertar_permisos.sql` - Script SQL del fix
- `apply_fix_insertar_permisos.py` - Script Python para aplicar el fix
- `check_insertar_permisos.py` - Script para verificar si el procedimiento existe
- `usuarios/views.py` - View que llama al procedimiento (línea 105)

## Testing

Para verificar que el fix funciona:

1. Asigna permisos a un usuario por primera vez ✓
2. Modifica los permisos del mismo usuario/ventana ✓
3. Verifica en la base de datos que se actualizó ✓

```sql
-- Ver permisos de un usuario
SELECT * FROM permisos WHERE id_user = (
    SELECT id_user FROM usuarios WHERE name_user = 'jerson'
);
```

---

**Aplicado:** Pendiente
**Requiere reinicio del backend:** No (solo actualiza BD)
**Compatible con versión anterior:** Sí
