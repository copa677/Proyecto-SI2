# Sistema de Orden de Producción - Camisas y Poleras

## 📋 Descripción General

El módulo de Orden de Producción permite gestionar el proceso completo de fabricación de camisas y poleras, incluyendo:

- ✅ Creación de órdenes de producción con materias primas
- ✅ Generación automática de notas de salida
- ✅ Descuento automático de inventario
- ✅ Registro de trazabilidad completa
- ✅ Seguimiento del estado de producción

---

## 🔄 Flujo de Trabajo

### 1. Crear una Orden de Producción

**Endpoint:** `POST /api/ordenproduccion/ordenes/crear-con-materias/`

**Ejemplo de Request:**
```json
{
  "cod_orden": "OP20251020-001",
  "fecha_inicio": "2025-10-20",
  "fecha_fin": "2025-10-25",
  "fecha_entrega": "2025-10-27",
  "producto_modelo": "Camisa",
  "color": "Blanco",
  "talla": "M",
  "cantidad_total": 100,
  "id_personal": 1,
  "materias_primas": [
    {
      "id_inventario": 5,
      "cantidad": 80.00
    },
    {
      "id_inventario": 7,
      "cantidad": 200.00
    }
  ]
}
```

**Lo que sucede automáticamente:**

1. Se crea la orden de producción con estado "En Proceso"
2. Se genera una nota de salida automáticamente con el motivo: "Producción: Camisa - OP20251020-001"
3. Se verifica que hay stock suficiente de cada materia prima
4. Se crean detalles de nota de salida para cada materia prima
5. Se descuenta del inventario la cantidad consumida
6. Se registra la trazabilidad (lote → orden de producción)

**Respuesta exitosa:**
```json
{
  "mensaje": "Orden de producción creada exitosamente",
  "id_orden": 15,
  "cod_orden": "OP20251020-001",
  "id_nota_salida": 28,
  "materias_consumidas": [
    {
      "nombre": "Tela Algodón",
      "cantidad": 80.0,
      "lote": 12
    },
    {
      "nombre": "Botones",
      "cantidad": 200.0,
      "lote": 8
    }
  ]
}
```

---

## 📊 Ejemplo de Uso: Fabricación de 100 Camisas Blancas

### Materias Primas Necesarias:

| Materia Prima | Cantidad | Unidad | ID Inventario |
|---------------|----------|--------|---------------|
| Tela Algodón  | 80       | metros | 5             |
| Botones       | 200      | unidades | 7           |
| Hilo Blanco   | 10       | bobinas  | 9           |

### Crear la Orden:

```json
{
  "cod_orden": "OP20251020-CAMISA-100",
  "fecha_inicio": "2025-10-20",
  "fecha_fin": "2025-10-25",
  "fecha_entrega": "2025-10-27",
  "producto_modelo": "Camisa",
  "color": "Blanco",
  "talla": "M",
  "cantidad_total": 100,
  "id_personal": 3,
  "materias_primas": [
    { "id_inventario": 5, "cantidad": 80 },
    { "id_inventario": 7, "cantidad": 200 },
    { "id_inventario": 9, "cantidad": 10 }
  ]
}
```

### Resultado:
- ✅ Orden de producción creada
- ✅ Nota de salida N° 28 generada automáticamente
- ✅ Inventario actualizado:
  - Tela Algodón: **descontados 80 metros**
  - Botones: **descontados 200 unidades**
  - Hilo Blanco: **descontados 10 bobinas**
- ✅ Trazabilidad registrada para cada lote consumido

---

## 🔍 Consultar Trazabilidad

**Endpoint:** `GET /api/ordenproduccion/ordenes/{id_orden}/trazabilidad/`

**Ejemplo:** `GET /api/ordenproduccion/ordenes/15/trazabilidad/`

**Respuesta:**
```json
{
  "orden": "OP20251020-CAMISA-100",
  "total_trazabilidades": 3,
  "trazabilidades": [
    {
      "id_trazabilidad": 45,
      "id_lote": 12,
      "id_orden": 15,
      "cantidad_usada": "80.00",
      "fecha_registro": "2025-10-20"
    },
    {
      "id_trazabilidad": 46,
      "id_lote": 8,
      "id_orden": 15,
      "cantidad_usada": "200.00",
      "fecha_registro": "2025-10-20"
    },
    {
      "id_trazabilidad": 47,
      "id_lote": 15,
      "id_orden": 15,
      "cantidad_usada": "10.00",
      "fecha_registro": "2025-10-20"
    }
  ]
}
```

---

## 🚨 Validaciones del Sistema

El sistema valida automáticamente:

1. ✅ **Stock suficiente**: No permite crear la orden si no hay inventario
2. ✅ **Materias primas válidas**: Verifica que el ID de inventario exista
3. ✅ **Código de orden único**: No permite duplicados
4. ✅ **Transaccionalidad**: Si falla algo, se revierte todo (rollback)

**Ejemplo de error por stock insuficiente:**
```json
{
  "error": "Stock insuficiente para Tela Algodón. Disponible: 50.00, Requerido: 80.00"
}
```

---

## 🎨 Frontend - Uso desde Angular

### 1. Abrir el Formulario de Nueva Orden

El usuario hace clic en "Nueva Orden" y el sistema:
- Genera automáticamente un código de orden único (ej: `OP20251020-387`)
- Prellenacampos con valores por defecto
- Muestra un selector de materias primas del inventario disponible

### 2. Completar la Orden

El usuario selecciona:
- **Producto**: Camisa / Polera
- **Color**: Blanco, Negro, Azul, etc.
- **Talla**: XS, S, M, L, XL, XXL
- **Cantidad a producir**: 100
- **Responsable**: Personal de producción
- **Materias primas**: Se agregan dinámicamente, mostrando el stock disponible

### 3. Guardar la Orden

Al hacer clic en "Crear Orden":
1. Se validan todos los campos
2. Se envía el POST al backend
3. El backend procesa todo automáticamente
4. El frontend muestra un mensaje de éxito indicando el N° de nota de salida generada
5. La tabla se actualiza con la nueva orden

---

## 📈 Estados de Orden de Producción

| Estado      | Descripción                           | Color en UI |
|-------------|---------------------------------------|-------------|
| En Proceso  | La orden está activa y en fabricación | Azul        |
| Completada  | La producción finalizó exitosamente   | Verde       |
| Pendiente   | La orden fue creada pero no iniciada  | Amarillo    |
| Cancelada   | La orden fue cancelada                | Rojo        |

---

## 🔗 Integración con Otros Módulos

### Módulos Relacionados:

1. **Inventario**: Se descuenta automáticamente las materias primas
2. **Nota de Salida**: Se genera automáticamente al crear la orden
3. **Trazabilidad**: Se registra qué lotes se usaron en cada orden
4. **Lotes**: Origen de las materias primas consumidas

### Flujo Completo:

```
Lote → Inventario → Orden Producción → Nota Salida → Trazabilidad
```

---

## 📝 Notas Importantes

1. ⚠️ **No se puede editar una orden después de creada** (para mantener integridad de trazabilidad)
2. ⚠️ **El inventario se descuenta inmediatamente** al crear la orden
3. ✅ **La trazabilidad es bidireccional**: Puedes ver qué órdenes usaron un lote, o qué lotes usó una orden
4. ✅ **Las notas de salida generadas automáticamente** tienen el formato: `Producción: {producto} - {código_orden}`

---

## 🧪 Ejemplo de Prueba Completa

### Paso 1: Verificar inventario disponible
```
GET /api/inventario/inventario/
```

### Paso 2: Crear orden de producción
```
POST /api/ordenproduccion/ordenes/crear-con-materias/
{
  "cod_orden": "OP-TEST-001",
  "fecha_inicio": "2025-10-20",
  "fecha_fin": "2025-10-22",
  "fecha_entrega": "2025-10-23",
  "producto_modelo": "Polera",
  "color": "Negro",
  "talla": "L",
  "cantidad_total": 50,
  "id_personal": 1,
  "materias_primas": [
    { "id_inventario": 1, "cantidad": 30 }
  ]
}
```

### Paso 3: Verificar inventario actualizado
```
GET /api/inventario/inventario/1/
```

### Paso 4: Verificar nota de salida generada
```
GET /api/notasalida/notas_salida/
```

### Paso 5: Consultar trazabilidad
```
GET /api/ordenproduccion/ordenes/{id_orden}/trazabilidad/
```

---

## ✅ Listo para Usar

El sistema está completamente implementado y listo para producción. Todos los endpoints están protegidos y validados.

**Endpoints disponibles:**
- `POST /api/ordenproduccion/ordenes/crear-con-materias/` - Crear orden con materias
- `GET /api/ordenproduccion/ordenes/` - Listar todas las órdenes
- `GET /api/ordenproduccion/ordenes/{id}/` - Obtener una orden específica
- `GET /api/ordenproduccion/ordenes/{id}/trazabilidad/` - Ver trazabilidad
- `DELETE /api/ordenproduccion/ordenes/eliminar/{id}/` - Eliminar orden

---

**Desarrollado para sistema de gestión de manufactura de camisas y poleras** 👔👕
