"""
Script para aplicar el fix del stored procedure insertar_permisos
Este script actualiza el procedimiento almacenado para manejar UPDATE en lugar de solo INSERT
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backwf.settings')
django.setup()

from django.db import connection

def apply_fix():
    """Aplica el fix del stored procedure insertar_permisos"""
    
    # Primero eliminar tanto FUNCTION como PROCEDURE si existen
    sql_drop = """
    DROP FUNCTION IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;
    DROP PROCEDURE IF EXISTS insertar_permisos(VARCHAR, VARCHAR, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN) CASCADE;
    """
    
    # Crear como PROCEDURE (compatible con CALL)
    sql_create = """
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
    """
    
    try:
        with connection.cursor() as cursor:
            print("🔧 Eliminando versiones anteriores de insertar_permisos...")
            cursor.execute(sql_drop)
            print("✓ Eliminación completada")
            
            print("🔧 Creando PROCEDURE insertar_permisos mejorado...")
            cursor.execute(sql_create)
            print("✅ PROCEDURE creado exitosamente!")
            print("📝 El stored procedure ahora maneja INSERT y UPDATE automáticamente")
            
            # Verificar que el procedimiento fue creado
            cursor.execute("""
                SELECT p.proname, 
                       CASE p.prokind
                           WHEN 'f' THEN 'FUNCTION'
                           WHEN 'p' THEN 'PROCEDURE'
                       END as type
                FROM pg_proc p
                WHERE p.proname = 'insertar_permisos'
            """)
            result = cursor.fetchone()
            if result:
                print(f"✓ Verificado: {result[0]} (tipo: {result[1]})")
            else:
                print("⚠️ Advertencia: No se pudo verificar el procedimiento")
                
    except Exception as e:
        print(f"❌ Error al aplicar el fix: {str(e)}")
        return False
    
    return True

if __name__ == '__main__':
    print("=" * 60)
    print("FIX: Stored Procedure insertar_permisos")
    print("=" * 60)
    
    success = apply_fix()
    
    if success:
        print("\n" + "=" * 60)
        print("✅ FIX COMPLETADO CON ÉXITO")
        print("=" * 60)
        print("\nAhora puedes asignar permisos sin errores de duplicación.")
        print("El procedimiento automáticamente:")
        print("  - INSERTA si el permiso no existe")
        print("  - ACTUALIZA si el permiso ya existe")
        sys.exit(0)
    else:
        print("\n" + "=" * 60)
        print("❌ ERROR AL APLICAR FIX")
        print("=" * 60)
        print("\nRevisa el error anterior y la conexión a la base de datos.")
        sys.exit(1)
