"""
Script de prueba para verificar que el sistema de bitácora funciona correctamente
Ejecutar con: python test_bitacora.py
"""
import os
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backwf.settings')
django.setup()

from Bitacora.models import Bitacora
from django.utils import timezone

def test_conexion_bd():
    """Prueba 1: Verificar conexión a la base de datos"""
    print("🔍 Prueba 1: Verificando conexión a la base de datos...")
    try:
        count = Bitacora.objects.count()
        print(f"✅ Conexión exitosa. Registros en bitácora: {count}")
        return True
    except Exception as e:
        print(f"❌ Error de conexión: {str(e)}")
        print("\n⚠️  Asegúrate de:")
        print("   1. Tener PostgreSQL corriendo")
        print("   2. Haber creado la tabla bitacora con el script SQL")
        print("   3. Verificar las credenciales en .env")
        return False

def test_crear_registro():
    """Prueba 2: Crear un registro de prueba"""
    print("\n🔍 Prueba 2: Creando registro de prueba...")
    try:
        registro = Bitacora.objects.create(
            username='test_usuario',
            ip='127.0.0.1',
            fecha_hora=timezone.now(),
            accion='PRUEBA_SISTEMA',
            descripcion='Registro de prueba creado automáticamente'
        )
        print(f"✅ Registro creado exitosamente. ID: {registro.id_bitacora}")
        return True
    except Exception as e:
        print(f"❌ Error al crear registro: {str(e)}")
        return False

def test_listar_registros():
    """Prueba 3: Listar últimos 5 registros"""
    print("\n🔍 Prueba 3: Listando últimos registros...")
    try:
        registros = Bitacora.objects.all().order_by('-fecha_hora')[:5]
        if registros:
            print(f"✅ Se encontraron {len(registros)} registros recientes:")
            for reg in registros:
                print(f"   - [{reg.fecha_hora}] {reg.username}: {reg.accion}")
        else:
            print("⚠️  No hay registros en la bitácora")
        return True
    except Exception as e:
        print(f"❌ Error al listar registros: {str(e)}")
        return False

def verificar_middleware():
    """Prueba 4: Verificar que el middleware esté configurado"""
    print("\n🔍 Prueba 4: Verificando configuración del middleware...")
    from django.conf import settings
    
    middleware_bitacora = 'Bitacora.middleware.BitacoraMiddleware'
    if middleware_bitacora in settings.MIDDLEWARE:
        print(f"✅ Middleware configurado correctamente")
        return True
    else:
        print(f"❌ Middleware NO está en settings.MIDDLEWARE")
        print(f"   Agregar: '{middleware_bitacora}'")
        return False

if __name__ == '__main__':
    print("=" * 60)
    print("🧪 PRUEBAS DEL SISTEMA DE BITÁCORA AUTOMÁTICA")
    print("=" * 60)
    
    resultados = []
    
    # Ejecutar pruebas
    resultados.append(test_conexion_bd())
    
    if resultados[0]:  # Solo continuar si hay conexión
        resultados.append(test_crear_registro())
        resultados.append(test_listar_registros())
    
    resultados.append(verificar_middleware())
    
    # Resumen
    print("\n" + "=" * 60)
    print("📊 RESUMEN DE PRUEBAS")
    print("=" * 60)
    exitosas = sum(resultados)
    totales = len(resultados)
    print(f"Exitosas: {exitosas}/{totales}")
    
    if exitosas == totales:
        print("\n🎉 ¡TODAS LAS PRUEBAS PASARON!")
        print("\n📝 Próximos pasos:")
        print("   1. Inicia el servidor: python manage.py runserver")
        print("   2. Realiza una petición POST (ej: login)")
        print("   3. Consulta: http://localhost:8000/api/bitacora/listar")
    else:
        print("\n⚠️  ALGUNAS PRUEBAS FALLARON")
        print("   Revisa los errores anteriores y sigue las sugerencias")
    
    print("=" * 60)
