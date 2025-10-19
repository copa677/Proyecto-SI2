# Sistema de Bitácora - Documentación

## 📋 Descripción
Sistema automático de auditoría que registra todas las acciones importantes realizadas en el sistema.

## ✅ Problemas Solucionados

### 1. Error de Autenticación (`is_active`)
**Problema:** El modelo `usurios` no tenía el atributo `is_active` requerido por Django REST Framework.

**Solución:** Se agregaron las propiedades `is_active` y `is_authenticated` al modelo `usurios`:
```python
@property
def is_active(self):
    return self.estado == 'activo' if hasattr(self, 'estado') else True

@property
def is_authenticated(self):
    return True
```

### 2. Error de Clave Duplicada
**Problema:** La secuencia de PostgreSQL para `id_bitacora` estaba desincronizada.

**Solución:** 
- Se creó el comando `fix_bitacora_sequence` para corregir automáticamente la secuencia
- Se modificó el sistema para usar INSERT SQL directo en lugar de ORM de Django
- Esto evita conflictos con la secuencia autoincremental

### 3. Manejo de Usuarios en Middleware
**Problema:** El middleware intentaba acceder a `request.user.is_authenticated` de forma incorrecta.

**Solución:** Se mejoró el método `_obtener_usuario()` para manejar correctamente el modelo personalizado `usurios`.

## 🚀 Comandos Disponibles

### Corregir Secuencia de Bitácora
```bash
python manage.py fix_bitacora_sequence
```
Este comando:
- Resetea la secuencia al valor máximo actual + 1
- Muestra el estado actual de la secuencia
- Se ejecuta automáticamente si hay errores de clave duplicada

### Limpiar Bitácoras Antiguas
```bash
# Limpiar registros mayores a 90 días (por defecto)
python manage.py clean_bitacora

# Limpiar registros mayores a X días
python manage.py clean_bitacora --days 30
```

## 📝 Funcionamiento

### Registro Automático (Middleware)
El middleware `BitacoraMiddleware` registra automáticamente:
- ✅ POST (creación de datos)
- ✅ PUT (actualización completa)
- ✅ PATCH (actualización parcial)
- ✅ DELETE (eliminación)

**Rutas excluidas:**
- `/admin/` - Panel de administración
- `/static/` - Archivos estáticos
- `/media/` - Archivos multimedia
- `/api/bitacora/` - Evita registro recursivo

### Acciones Específicas Registradas

#### Autenticación
- `INICIO_SESION` - Usuario inicia sesión
- `CIERRE_SESION` - Usuario cierra sesión
- `REGISTRO_USUARIO` - Nuevo usuario registrado
- `CAMBIO_PASSWORD` - Usuario cambió contraseña

#### Usuarios
- `CREACION_USUARIO` - Usuario creado
- `ACTUALIZACION_USUARIO` - Usuario actualizado
- `ELIMINACION_USUARIO` - Usuario eliminado
- `ASIGNACION_PERMISOS` - Permisos asignados

#### Empleados
- `REGISTRO_EMPLEADO` - Empleado registrado
- `ACTUALIZACION_EMPLEADO` - Empleado actualizado
- `ELIMINACION_EMPLEADO` - Empleado eliminado

#### Turnos
- `CREACION_TURNO` - Turno creado
- `ACTUALIZACION_TURNO` - Turno actualizado
- `ELIMINACION_TURNO` - Turno eliminado
- `DESACTIVACION_TURNO` - Turno desactivado

#### Asistencias
- `REGISTRO_ASISTENCIA` - Asistencia registrada
- `ACTUALIZACION_ASISTENCIA` - Asistencia actualizada
- `ELIMINACION_ASISTENCIA` - Asistencia eliminada

## 🔧 Endpoints API

### Listar Bitácoras
```http
GET /api/bitacora/listar
```
Respuesta:
```json
[
  {
    "id_bitacora": "1",
    "username": "admin",
    "ip": "192.168.1.10",
    "fecha_hora": "2025-10-18T10:30:00Z",
    "accion": "INICIO_SESION",
    "descripcion": "Usuario inició sesión en el sistema"
  }
]
```

### Registrar Bitácora Manual
```http
POST /api/bitacora/registrar
Content-Type: application/json

{
  "username": "admin",
  "ip": "192.168.1.10",
  "fecha_hora": "2025-10-18T10:30:00Z",
  "accion": "ACCION_PERSONALIZADA",
  "descripcion": "Descripción de la acción"
}
```

## 💡 Mejores Prácticas

### 1. Monitoreo Regular
```bash
# Verificar registros recientes
python manage.py shell
>>> from Bitacora.models import Bitacora
>>> Bitacora.objects.order_by('-fecha_hora')[:10]
```

### 2. Limpieza Periódica
Ejecutar mensualmente o según el volumen:
```bash
python manage.py clean_bitacora --days 90
```

### 3. Verificar Secuencia Después de Migraciones
```bash
python manage.py fix_bitacora_sequence
```

## 🐛 Troubleshooting

### Error: "duplicar valor da chave viola a restrição de unicidade"
**Solución:**
```bash
python manage.py fix_bitacora_sequence
```

### Bitácora no registra acciones
**Verificar:**
1. Middleware está habilitado en `settings.py`
2. La ruta no está en las rutas excluidas
3. El método HTTP es POST/PUT/PATCH/DELETE
4. La respuesta HTTP es < 400 (exitosa)

### Usuario aparece como "Sistema" o "Anónimo"
**Verificar:**
1. El token JWT está siendo enviado correctamente
2. El decorador `@jwt_required` está aplicado en la vista
3. El campo `name_user` está presente en el request

## 📊 Estructura de la Tabla

```sql
CREATE TABLE bitacora (
    id_bitacora SERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    ip VARCHAR(45) NOT NULL,
    fecha_hora TIMESTAMP NOT NULL,
    accion TEXT NOT NULL,
    descripcion TEXT NOT NULL
);
```

## 🔐 Seguridad

- Las contraseñas son filtradas automáticamente (nunca se registran)
- Los tokens de acceso no se almacenan
- Solo se registran operaciones exitosas (< 400)
- La IP del cliente se captura correctamente incluso detrás de proxies

## 📦 Archivos Importantes

- `Bitacora/middleware.py` - Middleware principal
- `Bitacora/models.py` - Modelo de datos
- `Bitacora/views.py` - Endpoints API
- `Bitacora/management/commands/fix_bitacora_sequence.py` - Comando para corregir secuencia
- `Bitacora/management/commands/clean_bitacora.py` - Comando para limpiar registros antiguos

## ✨ Mantenimiento

El sistema está diseñado para funcionar de forma automática. Los únicos mantenimientos necesarios son:

1. **Limpieza periódica** de registros antiguos (mensual/trimestral)
2. **Verificación de secuencia** después de migraciones o cambios en la BD
3. **Monitoreo ocasional** para detectar patrones de uso sospechosos

---

**Fecha de última actualización:** 18 de Octubre, 2025
**Versión:** 2.0 (Corregida y Mejorada)
