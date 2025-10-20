-- Fix para el stored procedure insertar_permisos
-- Problema: Genera error de duplicación de clave al intentar insertar un permiso que ya existe
-- Solución: Crear como PROCEDURE y verificar antes de insertar para hacer UPDATE si existe

-- Primero, eliminar cualquier versión anterior (FUNCTION o PROCEDURE)
DROP FUNCTION IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;

DROP PROCEDURE IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;

-- Crear como PROCEDURE (compatible con CALL) que maneja UPDATE cuando existe duplicación
CREATE OR REPLACE PROCEDURE insertar_permisos(
    p_username VARCHAR,
    p_ventana VARCHAR,
    p_insertar BOOLEAN,
    p_editar BOOLEAN,
    p_eliminar BOOLEAN,
    p_ver BOOLEAN
)
LANGUAGE plpgsql AS $$
DECLARE
    v_id_usuario INTEGER;
    v_permiso_existente INTEGER;
BEGIN
    -- Obtener el ID del usuario (columna 'id' en tabla usuarios)
    SELECT id INTO v_id_usuario
    FROM usuarios
    WHERE name_user = p_username;

    -- Si no se encuentra el usuario, lanzar error
    IF v_id_usuario IS NULL THEN
        RAISE EXCEPTION 'Usuario % no encontrado', p_username;
    END IF;

    -- Verificar si ya existe un permiso para este usuario y ventana
    -- Usar 'id_user' según la estructura real de la tabla permisos
    SELECT id_permiso INTO v_permiso_existente
    FROM permisos
    WHERE id_user = v_id_usuario AND vista = p_ventana;

    -- Si existe, hacer UPDATE
    IF v_permiso_existente IS NOT NULL THEN
        UPDATE permisos
        SET insertar = p_insertar,
            editar = p_editar,
            eliminar = p_eliminar,
            ver = p_ver
        WHERE id_permiso = v_permiso_existente;
        
        RAISE NOTICE 'Permiso actualizado para usuario % en ventana %', p_username, p_ventana;
    ELSE
        -- Si no existe, hacer INSERT
        INSERT INTO permisos(id_user, insertar, editar, eliminar, ver, vista)
        VALUES (v_id_usuario, p_insertar, p_editar, p_eliminar, p_ver, p_ventana);
        
        RAISE NOTICE 'Permiso creado para usuario % en ventana %', p_username, p_ventana;
    END IF;
END;
$$;

-- Comentario explicativo
COMMENT ON PROCEDURE insertar_permisos IS 
'Inserta o actualiza permisos de un usuario para una ventana específica.
Si el permiso ya existe, lo actualiza. Si no existe, lo crea.
Parámetros:
- p_username: nombre de usuario
- p_ventana: nombre de la ventana (Personal, Inventario, etc.)
- p_insertar, p_editar, p_eliminar, p_ver: permisos booleanos

Uso: CALL insertar_permisos(''usuario'', ''Personal'', true, true, false, true);';
