# Sistema de Bitácora - Guía de Uso

## 📋 Descripción
Sistema de bitácora automático que registra eventos y acciones del sistema usando JWT para identificar al usuario automáticamente.

## 🔧 Estructura

### Backend (Django)
- **Modelo:** `Bitacora` - Almacena: usuario, IP, fecha/hora, acción y descripción
- **API:**
  - `GET /api/bitacora/listar` - Lista todas las bitácoras
  - `POST /api/bitacora/registrar` - Registra un nuevo evento
- **Middleware:** Registra automáticamente acciones POST, PUT, PATCH, DELETE

### Frontend (Angular)
- **Servicio:** `BitacoraService` - Gestiona la comunicación con el backend
- **Componente:** `BitacoraComponent` - Interfaz para ver y filtrar registros

## 🚀 Uso

### 1. Registro Automático de Eventos

El servicio obtiene automáticamente el usuario del token JWT y la IP del usuario.

```typescript
import { BitacoraService } from 'src/app/services_back/bitacora.service';

constructor(private bitacoraService: BitacoraService) {}

// Registrar un evento
this.bitacoraService.registrarAccion(
  'Creación',
  'Se creó un nuevo usuario: Juan Pérez'
).subscribe({
  next: () => console.log('Evento registrado'),
  error: (err) => console.error('Error:', err)
});
```

### 2. Ejemplos de Uso

#### Login (Inicio de sesión)
```typescript
this.bitacoraService.registrarAccion(
  'Inicio de sesión',
  `El usuario ${username} ha iniciado sesión en el sistema`
).subscribe();
```

#### Logout (Cierre de sesión)
```typescript
this.bitacoraService.registrarAccion(
  'Cierre de sesión',
  `El usuario ${username} ha cerrado sesión`
).subscribe();
```

#### Crear Registro
```typescript
this.bitacoraService.registrarAccion(
  'Creación',
  'Se creó un nuevo empleado: María González'
).subscribe();
```

#### Modificar Registro
```typescript
this.bitacoraService.registrarAccion(
  'Modificación',
  'Se actualizó el turno del empleado ID: 123'
).subscribe();
```

#### Eliminar Registro
```typescript
this.bitacoraService.registrarAccion(
  'Eliminación',
  'Se eliminó el usuario ID: 456'
).subscribe();
```

### 3. Ver Bitácora

Navega a `/menu/bitacora` para ver todos los registros con filtros por:
- Usuario
- Fecha
- Acción
- Búsqueda de texto

## 📝 Tipos de Acciones Predefinidas

- **Inicio de sesión** - Usuario entra al sistema
- **Cierre de sesión** - Usuario sale del sistema
- **Creación** - Nuevo registro creado
- **Modificación** - Registro actualizado
- **Eliminación** - Registro eliminado

## 🔐 Seguridad

- El usuario se obtiene automáticamente del token JWT
- La IP se detecta automáticamente
- No es necesario pasar manualmente estos datos

## 🎯 Ventajas

✅ **Automático:** Obtiene usuario e IP sin intervención manual  
✅ **Seguro:** Usa JWT para identificar al usuario  
✅ **Simple:** Solo requiere acción y descripción  
✅ **Auditable:** Registra todas las acciones importantes  
✅ **Middleware:** Registra automáticamente operaciones HTTP

## 📌 Notas Importantes

- Asegúrate de tener un token JWT válido en localStorage
- El middleware del backend registra automáticamente POST, PUT, PATCH, DELETE
- Los registros manuales desde el frontend son opcionales para eventos específicos
