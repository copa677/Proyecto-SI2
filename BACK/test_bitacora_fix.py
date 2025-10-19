"""
Script de prueba para verificar el sistema de bitácora
Ejecutar con: python manage.py shell < test_bitacora_fix.py
"""

from django.utils import timezone
from Bitacora.models import Bitacora
from django.db import connection

print("=" * 60)
print("VERIFICACIÓN DEL SISTEMA DE BITÁCORA")
print("=" * 60)

# 1. Verificar secuencia
print("\n1. Verificando secuencia de la base de datos...")
with connection.cursor() as cursor:
    cursor.execute("SELECT MAX(id_bitacora) FROM bitacora")
    max_id = cursor.fetchone()[0] or 0
    
    cursor.execute("SELECT currval(pg_get_serial_sequence('bitacora', 'id_bitacora'))")
    seq_val = cursor.fetchone()[0]
    
    print(f"   ✓ Máximo ID en tabla: {max_id}")
    print(f"   ✓ Valor de secuencia: {seq_val}")
    
    if seq_val >= max_id:
        print("   ✓ Secuencia correcta!")
    else:
        print("   ✗ Secuencia desincronizada - ejecutar: python manage.py fix_bitacora_sequence")

# 2. Probar inserción con SQL directo
print("\n2. Probando inserción con SQL directo...")
try:
    with connection.cursor() as cursor:
        cursor.execute("""
            INSERT INTO bitacora (username, ip, fecha_hora, accion, descripcion)
            VALUES (%s, %s, %s, %s, %s)
        """, ['test_user', '127.0.0.1', timezone.now(), 'TEST', 'Prueba del sistema de bitácora'])
    print("   ✓ Inserción exitosa con SQL directo!")
except Exception as e:
    print(f"   ✗ Error en inserción: {str(e)}")

# 3. Contar registros totales
print("\n3. Estadísticas de la bitácora...")
try:
    total = Bitacora.objects.count()
    print(f"   ✓ Total de registros: {total}")
    
    # Contar por acción
    from django.db.models import Count
    acciones = Bitacora.objects.values('accion').annotate(count=Count('accion')).order_by('-count')[:5]
    print("\n   Top 5 acciones más frecuentes:")
    for acc in acciones:
        print(f"   - {acc['accion']}: {acc['count']} veces")
        
except Exception as e:
    print(f"   ✗ Error al obtener estadísticas: {str(e)}")

# 4. Verificar últimos registros
print("\n4. Últimos 5 registros:")
try:
    ultimos = Bitacora.objects.order_by('-fecha_hora')[:5]
    for b in ultimos:
        print(f"   - [{b.fecha_hora.strftime('%Y-%m-%d %H:%M')}] {b.username}: {b.accion}")
except Exception as e:
    print(f"   ✗ Error al obtener últimos registros: {str(e)}")

print("\n" + "=" * 60)
print("VERIFICACIÓN COMPLETADA")
print("=" * 60)
