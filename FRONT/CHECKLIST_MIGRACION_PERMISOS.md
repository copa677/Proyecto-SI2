# Lista de Verificación - Migración Sistema de Permisos

## Estado Actual: ✅ COMPLETADO

### Cambios Realizados

#### 1. ✅ PermissionService Actualizado
**Archivo:** `src/app/services_back/permission.service.ts`

**Nuevas funcionalidades agregadas:**
- ✅ Cache de permisos del backend (`permisosBackend$`)
- ✅ Método `hasPermission()` para compatibilidad con menu
- ✅ Método `tienePermiso()` para compatibilidad con directivas
- ✅ Método `cargarPermisosBackend()` para cargar permisos por ID usuario
- ✅ Soporte para múltiples roles: `admin`, `Administrador`, `Supervisor`, `Operario`, `empleado`
- ✅ Permisos predefinidos: `gestionar_personal`, `asignar_roles`, etc.

#### 2. ✅ PermisoAccionDirective Actualizada
**Archivo:** `src/app/directives/permiso-accion.directive.ts`

**Cambios:**
- ✅ Import cambiado de `AuthPermisosService` a `PermissionService`
- ✅ Inyección de dependencia actualizada
- ✅ Funcionalidad preservada, ahora usa servicio consolidado

#### 3. ✅ AuthPermisosService Marcado como Deprecated
**Archivo:** `src/app/services_back/auth-permisos.service.ts`

**Estado:**
- ✅ Agregado comentario `@deprecated`
- ✅ No hay referencias en otros archivos
- ⏳ Pendiente eliminación física (después de testing completo)

#### 4. ✅ MenuComponent
**Archivo:** `src/app/pages/menu/menu.component.ts`

**Estado:**
- ✅ Ya tiene `PermissionService` inyectado y público
- ✅ Inicializa el rol en `ngOnInit()`
- ✅ Template HTML usa `permissionService.hasPermission()`

#### 5. ✅ PermisosService (Sin Cambios)
**Archivo:** `src/app/services_back/permisos.service.ts`

**Estado:**
- ✅ Mantiene su función como servicio HTTP para operaciones CRUD
- ✅ Documentación agregada a métodos
- ✅ Complementa a PermissionService correctamente

#### 6. ✅ AsignarPermisosComponent (Sin Cambios)
**Archivo:** `src/app/pages/asignar-permisos/asignar-permisos.component.ts`

**Estado:**
- ✅ Ya usa `PermisosService` correctamente
- ✅ No requiere cambios

### Archivos Actualizados

| Archivo | Estado | Acción |
|---------|--------|--------|
| `permission.service.ts` | ✅ Actualizado | Agregados métodos hasPermission, tienePermiso, cargarPermisosBackend |
| `permiso-accion.directive.ts` | ✅ Actualizado | Cambiado a usar PermissionService |
| `auth-permisos.service.ts` | ⚠️ Deprecated | Marcado para eliminación futura |
| `permisos.service.ts` | ✅ Mantenido | Limpieza y documentación |
| `menu.component.ts` | ✅ OK | No requirió cambios |
| `asignar-permisos.component.ts` | ✅ OK | No requirió cambios |

### Validación de Código

- ✅ No hay errores de compilación en TypeScript
- ✅ No hay imports rotos
- ✅ Todos los servicios usan inyección de dependencias correctamente
- ✅ Métodos públicos documentados con comentarios JSDoc

### Testing Pendiente

#### Frontend
- [ ] Verificar login y extracción de rol desde JWT
- [ ] Confirmar que menús se ocultan/muestran según rol
- [ ] Probar directiva `*appPermisoAccion` en diferentes escenarios
- [ ] Verificar asignación de permisos desde componente AsignarPermisos
- [ ] Confirmar cache de permisos funciona correctamente
- [ ] Probar limpiarCache() al cerrar sesión

#### Backend
- [ ] Probar endpoint `/api/usuario/permisos/{idUsuario}/`
- [ ] Probar endpoint `/api/usuario/getpermisosUser_Ventana/{username}/{ventana}`
- [ ] Probar endpoint POST `/api/usuario/permisos` con diferentes ventanas
- [ ] Verificar stored procedure `insertar_permisos` con UPDATE en lugar de solo INSERT

#### Integración
- [ ] Login con usuario `admin` → Verificar acceso total
- [ ] Login con usuario `Supervisor` → Verificar permisos limitados
- [ ] Login con usuario `Operario` → Verificar acceso básico
- [ ] Asignar permisos personalizados a usuario → Verificar precedencia sobre rol
- [ ] Cerrar sesión → Verificar que cache se limpia

### Problemas Conocidos a Resolver

#### 1. Stored Procedure - Duplicación de Claves
**Archivo:** `BACK/fix_bitacora_sequence.sql` (o similar)
**Problema:** Error al asignar permisos dos veces al mismo usuario/ventana
**Solución:**
```sql
-- Actualizar insertar_permisos para manejar UPDATE
CREATE OR REPLACE FUNCTION insertar_permisos(...)
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM permisos WHERE ...) THEN
    UPDATE permisos SET ... WHERE ...;
  ELSE
    INSERT INTO permisos (...) VALUES (...);
  END IF;
END;
$$ LANGUAGE plpgsql;
```

#### 2. Sincronización de Roles
**Ubicación:** Backend vs Frontend
**Problema:** Backend usa `'Administrador'`, frontend usa `'admin'`
**Estado:** ✅ RESUELTO - ROLE_PERMISSIONS acepta ambos
**Validar:** Confirmar que JWT devuelve el rol correcto

### Pasos Siguientes

#### Inmediato (Esta sesión)
1. ✅ Consolidar PermissionService
2. ✅ Actualizar directiva PermisoAccionDirective
3. ✅ Marcar AuthPermisosService como deprecated
4. ✅ Documentar sistema completo
5. 🔄 **AHORA:** Probar en navegador

#### Corto Plazo (Próxima sesión)
1. [ ] Actualizar stored procedure `insertar_permisos`
2. [ ] Testing completo del sistema
3. [ ] Eliminar `auth-permisos.service.ts` físicamente
4. [ ] Agregar guards de ruta basados en permisos

#### Mediano Plazo
1. [ ] Implementar tests unitarios para PermissionService
2. [ ] Agregar logging de acciones denegadas
3. [ ] Crear panel de auditoría de permisos
4. [ ] Documentación para usuarios finales

### Comandos de Testing

#### Iniciar Frontend
```bash
cd FRONT/my-proyecto-app
npm start
```

#### Verificar Compilación
```bash
cd FRONT/my-proyecto-app
ng build --configuration development
```

#### Usuarios de Prueba
- **Admin:** usuario=jerson, id=4, rol=admin
- **Supervisor:** (crear si no existe)
- **Operario:** (crear si no existe)

### Postman - Tests de API

#### 1. Login
```
POST {{base_url}}/api/usuario/login
Body: {"name_user": "jerson", "password_user": "..."}
Response: {token: "..."}
```

#### 2. Asignar Permisos
```
POST {{base_url}}/api/usuario/permisos
Headers: Authorization: Bearer {{token}}
Body: {
  "name_user": "jerson",
  "ventana": "Personal",
  "insertar": true,
  "editar": true,
  "eliminar": true,
  "ver": true
}
```

#### 3. Obtener Permisos de Ventana
```
GET {{base_url}}/api/usuario/getpermisosUser_Ventana/jerson/Personal
Headers: Authorization: Bearer {{token}}
Response: {insertar: true, editar: true, eliminar: true, ver: true}
```

### Checklist de Validación Final

Antes de considerar el sistema completo, verificar:

- [ ] ✅ No hay errores en consola del navegador
- [ ] ✅ No hay errores en consola del backend
- [ ] Usuarios con rol 'admin' ven todo el menú
- [ ] Usuarios con rol 'Supervisor' ven solo secciones permitidas
- [ ] Usuarios con rol 'Operario' tienen acceso limitado
- [ ] Directiva `*appPermisoAccion` oculta elementos correctamente
- [ ] Permisos de base de datos sobrescriben permisos de rol (cuando aplicable)
- [ ] Cache de permisos se limpia al cerrar sesión
- [ ] Token JWT contiene el rol correcto del usuario
- [ ] Stored procedure no genera errores de duplicación

### Notas Importantes

⚠️ **IMPORTANTE:** El sistema ahora es híbrido:
- **Rol Administrador:** Acceso total automático (bypass)
- **Otros Roles:** Permisos predefinidos + permisos de BD
- **Prioridad:** Admin > Permisos de BD > Permisos de Rol

🔒 **SEGURIDAD:**
- Verificar permisos tanto en frontend como backend
- No confiar solo en visibilidad de UI
- Backend debe validar permisos en cada endpoint

📝 **DOCUMENTACIÓN:**
- Sistema completamente documentado en `SISTEMA_PERMISOS_CONSOLIDADO.md`
- Comentarios JSDoc en todos los métodos públicos
- Ejemplos de uso en documentación

---

**Fecha de consolidación:** $(date)
**Responsable:** GitHub Copilot + Usuario
**Estado:** ✅ Consolidación completa - Pendiente testing
