"""
Script para verificar si insertar_permisos es FUNCTION o PROCEDURE
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backwf.settings')
django.setup()

from django.db import connection

def check_procedure_type():
    """Verifica si insertar_permisos existe y su tipo"""
    
    try:
        with connection.cursor() as cursor:
            # Verificar en pg_proc (funciones)
            cursor.execute("""
                SELECT 
                    p.proname,
                    pg_catalog.pg_get_function_identity_arguments(p.oid) as args,
                    CASE p.prokind
                        WHEN 'f' THEN 'FUNCTION'
                        WHEN 'p' THEN 'PROCEDURE'
                        WHEN 'a' THEN 'AGGREGATE'
                        WHEN 'w' THEN 'WINDOW'
                    END as type
                FROM pg_proc p
                WHERE p.proname = 'insertar_permisos'
            """)
            
            results = cursor.fetchall()
            
            if not results:
                print("❌ insertar_permisos NO EXISTE en la base de datos")
                print("\nCreando la función desde cero...")
                return None
            
            for row in results:
                print(f"✓ Encontrado: {row[0]}")
                print(f"  Argumentos: {row[1]}")
                print(f"  Tipo: {row[2]}")
                return row[2]
                
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        return None

if __name__ == '__main__':
    result = check_procedure_type()
    if result:
        print(f"\nResultado: insertar_permisos es un {result}")
