"""
Migration para actualizar el stored procedure insertar_permisos
Este migration se ejecuta automáticamente con 'python manage.py migrate'
No requiere intervención manual de cada desarrollador
"""
from django.db import migrations


def crear_procedure_insertar_permisos(apps, schema_editor):
    """
    Crea o actualiza el stored procedure insertar_permisos
    para manejar INSERT y UPDATE automáticamente
    """
    sql = """
    -- Eliminar versiones anteriores
    DROP FUNCTION IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;
    DROP PROCEDURE IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;

    -- Crear PROCEDURE mejorado
    CREATE PROCEDURE insertar_permisos(
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

    -- Agregar comentario
    COMMENT ON PROCEDURE insertar_permisos IS 
    'Inserta o actualiza permisos de un usuario para una ventana específica.
    Si el permiso ya existe, lo actualiza. Si no existe, lo crea.';
    """
    
    schema_editor.execute(sql)


def eliminar_procedure(apps, schema_editor):
    """
    Rollback: elimina el procedure (en caso de revertir la migration)
    """
    sql = """
    DROP PROCEDURE IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;
    """
    schema_editor.execute(sql)


class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0001_initial'),  # Ajustar al número de tu última migration
    ]

    operations = [
        migrations.RunPython(
            crear_procedure_insertar_permisos,
            reverse_code=eliminar_procedure
        ),
    ]
