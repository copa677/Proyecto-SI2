# Sistema de Permisos Consolidado

## Resumen

Se ha consolidado el sistema de permisos de la aplicación en un único servicio `PermissionService` que combina:
1. **Permisos basados en roles** (predeterminados del sistema)
2. **Permisos por ventana/acción** (personalizables desde la base de datos)
3. **Permisos por nombre** (del backend, usados en directivas)

## Arquitectura

### Servicios

#### ✅ `PermissionService` (PRINCIPAL)
**Ubicación:** `src/app/services_back/permission.service.ts`

**Responsabilidades:**
- Gestionar roles de usuario desde JWT tokens
- Verificar permisos basados en roles predeterminados
- Gestionar permisos de ventana (insertar, editar, eliminar, ver)
- Cargar y verificar permisos del backend por nombre
- Cache de permisos para optimización

**Métodos principales:**
```typescript
// Gestión de roles
setUserRole(role: string): void
getUserRole(): string | null
loadUserRoleFromToken(): void  // Privado, se ejecuta automáticamente

// Permisos basados en roles
hasPermission(permission: string): boolean
hasRolePermission(permission: string): boolean

// Permisos por ventana (database)
obtenerPermisosVentana(username: string, ventana: string): Observable<any>
puedeRealizarAccion(username: string, ventana: string, accion: 'insertar' | 'editar' | 'eliminar' | 'ver'): Observable<boolean>
asignarPermisos(username: string, ventana: string, permisos: any): Observable<any>

// Permisos por nombre (backend)
cargarPermisosBackend(idUsuario: number): Observable<string[]>
tienePermiso(nombrePermiso: string): Observable<boolean>

// Utilidades
limpiarCache(): void
```

#### ✅ `PermisosService` (COMPLEMENTARIO)
**Ubicación:** `src/app/services_back/permisos.service.ts`

**Responsabilidades:**
- Realizar llamadas HTTP puras para operaciones CRUD de permisos
- Complementa a PermissionService con operaciones de base de datos

**Métodos:**
```typescript
obtenerPermisos(): Observable<any>
obtenerPermisosDeUsuario(username: string): Observable<any>
obtenerPermisosDeUsuarioVentana(username: string, ventana: string): Observable<any>
asignarPermiso(username: string, permiso: any): Observable<any>
```

#### ❌ `AuthPermisosService` (DEPRECATED)
**Ubicación:** `src/app/services_back/auth-permisos.service.ts`

**Estado:** Marcado como deprecado. No usar en código nuevo.
**Razón:** Funcionalidad consolidada en PermissionService
**Acción recomendada:** Será eliminado en versiones futuras

### Directivas

#### `PermisoAccionDirective`
**Ubicación:** `src/app/directives/permiso-accion.directive.ts`

**Uso:**
```html
<div *appPermisoAccion="'nombre_del_permiso'">
  Contenido visible solo si el usuario tiene el permiso
</div>
```

**Actualización:** Ahora usa `PermissionService` en lugar de `AuthPermisosService`

## Roles del Sistema

### Definidos en `ROLE_PERMISSIONS`

| Rol | Código | Descripción | Permisos |
|-----|--------|-------------|----------|
| Administrador | `admin` / `Administrador` | Acceso total | `['all']` |
| Supervisor | `Supervisor` | Gestión de personal y roles | `['gestionar_personal', 'asignar_roles', ...]` |
| Operario | `Operario` | Operaciones básicas | `['ver_inventario', 'ver_lotes', ...]` |
| Empleado | `empleado` | Compatibilidad | Similar a Operario |

### Permisos por Rol

**Administrador:**
- Acceso completo a todas las funcionalidades

**Supervisor:**
- gestionar_personal
- asignar_roles
- ver_inventario, ver_lotes, ver_ordenes
- agregar_ordenes, editar_ordenes
- ver_calidad, agregar_calidad
- ver_trazabilidad, ver_notificaciones

**Operario:**
- ver_inventario, ver_lotes, ver_ordenes
- agregar_ordenes
- ver_calidad, agregar_calidad
- ver_trazabilidad, ver_notificaciones

## Ventanas del Sistema

Las siguientes ventanas tienen permisos granulares (insertar, editar, eliminar, ver):

1. Personal
2. Inventario
3. Reportes
4. Bitacora
5. Usuarios
6. Lotes
7. OrdenProduccion
8. NotaSalida

## Flujo de Verificación de Permisos

### 1. Inicialización (Menu Component)
```typescript
ngOnInit(): void {
  const role = this.login.getRoleFromToken();
  this.permissionService.setUserRole(role);
}
```

### 2. Verificación en Template (Role-based)
```html
<div *ngIf="permissionService.hasPermission('gestionar_personal')">
  <!-- Menú de Gestión de Personal -->
</div>
```

### 3. Verificación por Ventana/Acción (Database)
```typescript
this.permissionService.puedeRealizarAccion(username, 'Inventario', 'insertar')
  .subscribe(puede => {
    if (puede) {
      // Permitir inserción
    }
  });
```

### 4. Verificación con Directiva (Backend)
```html
<button *appPermisoAccion="'editar_producto'">Editar</button>
```

## Prioridad de Permisos

1. **Rol Administrador:** Bypass completo, siempre tiene acceso
2. **Permisos de Rol:** Verificación en `ROLE_PERMISSIONS`
3. **Permisos de Base de Datos:** Consulta al backend para permisos específicos

## Integración con Backend

### Endpoints Utilizados

#### Obtener permisos de ventana
```
GET /api/usuario/getpermisosUser_Ventana/{username}/{ventana}
Respuesta: {insertar: boolean, editar: boolean, eliminar: boolean, ver: boolean}
```

#### Asignar permisos
```
POST /api/usuario/permisos
Body: {name_user, ventana, insertar, editar, eliminar, ver}
```

#### Obtener permisos por ID usuario
```
GET /api/usuario/permisos/{idUsuario}/
Respuesta: {permisos: string[]}
```

### Stored Procedure
**Nombre:** `insertar_permisos`
**Ubicación:** Base de datos PostgreSQL
**Funcionalidad:** Inserta/actualiza permisos en la tabla `permisos`

**Nota:** Actualmente tiene un bug de duplicación de claves. Requiere actualización para manejar UPDATE en lugar de solo INSERT.

## Componentes Actualizados

### ✅ MenuComponent
- Usa `PermissionService` para mostrar/ocultar secciones del menú
- Inicializa el rol del usuario en `ngOnInit`
- Verificación con `hasPermission()` para menús role-based

### ✅ AsignarPermisosComponent
- Usa `PermisosService` para operaciones CRUD
- Permite asignar permisos por ventana a usuarios específicos

### ✅ PermisoAccionDirective
- Actualizada para usar `PermissionService` en lugar de `AuthPermisosService`
- Soporta verificación por nombre de permiso

## Gestión de Caché

El servicio implementa caché en memoria usando `BehaviorSubject`:

```typescript
private userRole$ = new BehaviorSubject<string | null>(null);
private permisosVentana$ = new BehaviorSubject<any>({});
private permisosBackend$ = new BehaviorSubject<string[]>([]);
```

**Limpiar cache:**
```typescript
this.permissionService.limpiarCache();  // Llamar al cerrar sesión
```

## Token JWT

El sistema extrae el rol del usuario del token JWT usando `jwt-decode`:

**Estructura del token:**
```json
{
  "id": 1,
  "username": "usuario",
  "tipo_usuario": "Administrador",  // <-- Rol extraído
  "exp": 1234567890
}
```

## Migración desde Sistema Anterior

### Antes (múltiples servicios)
```typescript
// En componentes
constructor(
  private authPermisosService: AuthPermisosService,
  private permisosService: PermisosService,
  private permissionService: PermissionService
) {}
```

### Ahora (servicio unificado)
```typescript
// En componentes
constructor(
  private permissionService: PermissionService,
  private permisosService: PermisosService  // Solo para operaciones CRUD
) {}
```

### Cambios en imports
```typescript
// ❌ Antes
import { AuthPermisosService } from '../services_back/auth-permisos.service';

// ✅ Ahora
import { PermissionService } from '../services_back/permission.service';
```

## Testing

### Test de Permisos en Postman

**Endpoint:** `POST {{base_url}}/api/usuario/permisos`

**Body:**
```json
{
  "name_user": "jerson",
  "ventana": "Personal",
  "insertar": true,
  "editar": true,
  "eliminar": true,
  "ver": true
}
```

**Usuario de prueba:**
- ID: 4
- Username: jerson
- Rol: admin

### Verificación en Frontend

1. Login como usuario específico
2. Verificar que los menús se muestran según el rol
3. Intentar operaciones CRUD en diferentes ventanas
4. Confirmar que los botones/acciones respetan los permisos de la base de datos

## Problemas Conocidos

### 1. Duplicación de Claves en Stored Procedure
**Síntoma:** Error al asignar permisos por segunda vez al mismo usuario/ventana
**Error:** `duplicar valor da chave viola a restrição de unicidade permisos_pkey`
**Solución pendiente:** Modificar `insertar_permisos` para hacer UPDATE si existe

### 2. Compatibilidad de Roles
**Problema:** El backend usa `'Administrador'` mientras el frontend usa `'admin'`
**Solución implementada:** ROLE_PERMISSIONS acepta ambos

## Roadmap

### Completado ✅
- [x] Consolidar AuthPermisosService en PermissionService
- [x] Actualizar PermisoAccionDirective
- [x] Agregar método hasPermission() para compatibilidad con menú
- [x] Implementar cache con BehaviorSubject
- [x] Integración con JWT token
- [x] Documentación completa

### Pendiente 📋
- [ ] Actualizar stored procedure insertar_permisos para manejar UPDATE
- [ ] Eliminar auth-permisos.service.ts después de testing completo
- [ ] Agregar guards de ruta basados en permisos
- [ ] Implementar tests unitarios para PermissionService
- [ ] Agregar logging de acciones denegadas para auditoría
- [ ] Sincronización automática de permisos al cambiar rol de usuario

## Uso Recomendado

### En Componentes
```typescript
import { PermissionService } from '../../services_back/permission.service';

export class MiComponente implements OnInit {
  constructor(public permissionService: PermissionService) {}

  ngOnInit() {
    // Verificar permiso role-based
    if (this.permissionService.hasPermission('gestionar_personal')) {
      // ...
    }

    // Verificar permiso de ventana
    const username = this.login.getUsernameFromToken();
    this.permissionService.puedeRealizarAccion(username, 'Inventario', 'insertar')
      .subscribe(puede => {
        this.puedeInsertar = puede;
      });
  }
}
```

### En Templates
```html
<!-- Verificación role-based -->
<div *ngIf="permissionService.hasPermission('asignar_roles')">
  <button>Gestionar Usuarios</button>
</div>

<!-- Verificación con directiva -->
<button *appPermisoAccion="'editar_inventario'">Editar</button>

<!-- Verificación programática -->
<button [disabled]="!puedeInsertar">Crear Nuevo</button>
```

## Soporte

Para problemas o preguntas sobre el sistema de permisos:
1. Revisar esta documentación
2. Verificar la implementación en `PermissionService`
3. Consultar los endpoints del backend en `usuarios/views.py`
4. Revisar la definición de roles en `usuarios/roles.py`

---

**Última actualización:** $(date)
**Versión del sistema:** 2.0 (Consolidado)
