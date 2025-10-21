"""
Script para verificar la estructura de las tablas usuarios y permisos
"""
import os
import sys
import django

# Configurar Django
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backwf.settings')
django.setup()

from django.db import connection

def verificar_estructura():
    """Verifica la estructura de las tablas usuarios y permisos"""
    
    try:
        with connection.cursor() as cursor:
            print("=" * 60)
            print("ESTRUCTURA DE LA TABLA 'usuarios'")
            print("=" * 60)
            cursor.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_name = 'usuarios'
                ORDER BY ordinal_position
            """)
            
            for row in cursor.fetchall():
                print(f"  {row[0]:<20} {row[1]:<20} {'NULL' if row[2]=='YES' else 'NOT NULL'}")
            
            print("\n" + "=" * 60)
            print("ESTRUCTURA DE LA TABLA 'permisos'")
            print("=" * 60)
            cursor.execute("""
                SELECT column_name, data_type, is_nullable
                FROM information_schema.columns
                WHERE table_name = 'permisos'
                ORDER BY ordinal_position
            """)
            
            permisos_cols = []
            for row in cursor.fetchall():
                permisos_cols.append(row[0])
                print(f"  {row[0]:<20} {row[1]:<20} {'NULL' if row[2]=='YES' else 'NOT NULL'}")
            
            print("\n" + "=" * 60)
            print("DATOS DE EJEMPLO DE 'permisos'")
            print("=" * 60)
            cursor.execute("SELECT * FROM permisos LIMIT 3")
            
            if cursor.description:
                columnas = [col[0] for col in cursor.description]
                print(f"Columnas: {', '.join(columnas)}")
                print("")
                for row in cursor.fetchall():
                    print(f"  {dict(zip(columnas, row))}")
            
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == '__main__':
    verificar_estructura()
