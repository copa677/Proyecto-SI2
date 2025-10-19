-- Script para corregir la secuencia de la tabla bitacora
-- Ejecutar este script en PostgreSQL para solucionar el error de clave duplicada

-- 1. Resetear la secuencia al valor máximo actual + 1
SELECT setval(pg_get_serial_sequence('bitacora', 'id_bitacora'), 
              COALESCE((SELECT MAX(id_bitacora) FROM bitacora), 1), 
              true);

-- 2. Verificar el valor actual de la secuencia
SELECT currval(pg_get_serial_sequence('bitacora', 'id_bitacora')) as secuencia_actual;

-- 3. Verificar el máximo ID en la tabla
SELECT MAX(id_bitacora) as max_id FROM bitacora;
