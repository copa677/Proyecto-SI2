-- Script para crear la tabla trazabilidad_lote
-- Ejecutar en PostgreSQL para la base de datos textiltech

CREATE TABLE IF NOT EXISTS trazabilidad_lote (
    id_trazabilidad_lote SERIAL PRIMARY KEY,
    id_lote INTEGER NOT NULL,
    id_materia INTEGER NOT NULL,
    nombre_materia VARCHAR(255) NOT NULL,
    codigo_lote VARCHAR(100) NOT NULL,
    cantidad_consumida NUMERIC(10, 2) NOT NULL,
    unidad_medida VARCHAR(50) NOT NULL,
    tipo_operacion VARCHAR(50) NOT NULL,
    id_operacion INTEGER NOT NULL,
    codigo_operacion VARCHAR(100) NOT NULL,
    fecha_consumo TIMESTAMP NOT NULL,
    id_usuario INTEGER,
    nombre_usuario VARCHAR(255)
);

-- Crear índices para mejorar el rendimiento de consultas
CREATE INDEX IF NOT EXISTS idx_trazabilidad_lote_lote ON trazabilidad_lote(id_lote);
CREATE INDEX IF NOT EXISTS idx_trazabilidad_lote_materia ON trazabilidad_lote(id_materia);
CREATE INDEX IF NOT EXISTS idx_trazabilidad_lote_operacion ON trazabilidad_lote(tipo_operacion, id_operacion);
CREATE INDEX IF NOT EXISTS idx_trazabilidad_lote_fecha ON trazabilidad_lote(fecha_consumo);

-- Comentarios para documentación
COMMENT ON TABLE trazabilidad_lote IS 'Tabla para rastrear el consumo de lotes en operaciones (Órdenes de Producción, Notas de Salida, etc.)';
COMMENT ON COLUMN trazabilidad_lote.id_trazabilidad_lote IS 'ID único de la trazabilidad de lote';
COMMENT ON COLUMN trazabilidad_lote.id_lote IS 'ID del lote del cual se consumió';
COMMENT ON COLUMN trazabilidad_lote.id_materia IS 'ID de la materia prima consumida';
COMMENT ON COLUMN trazabilidad_lote.nombre_materia IS 'Nombre de la materia prima';
COMMENT ON COLUMN trazabilidad_lote.codigo_lote IS 'Código del lote';
COMMENT ON COLUMN trazabilidad_lote.cantidad_consumida IS 'Cantidad consumida del lote';
COMMENT ON COLUMN trazabilidad_lote.unidad_medida IS 'Unidad de medida (metros, kg, etc.)';
COMMENT ON COLUMN trazabilidad_lote.tipo_operacion IS 'Tipo de operación (orden_produccion, nota_salida)';
COMMENT ON COLUMN trazabilidad_lote.id_operacion IS 'ID de la orden de producción o nota de salida';
COMMENT ON COLUMN trazabilidad_lote.codigo_operacion IS 'Código de la orden o nota';
COMMENT ON COLUMN trazabilidad_lote.fecha_consumo IS 'Fecha y hora del consumo';
COMMENT ON COLUMN trazabilidad_lote.id_usuario IS 'ID del usuario que realizó la operación';
COMMENT ON COLUMN trazabilidad_lote.nombre_usuario IS 'Nombre del usuario que realizó la operación';
