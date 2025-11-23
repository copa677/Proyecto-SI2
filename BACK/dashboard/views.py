
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import connection
from django.utils import timezone
from datetime import datetime, timedelta

@api_view(['GET'])
def obtener_estadisticas_dashboard(request):
	try:
		with connection.cursor() as cursor:
			cursor.execute("""
				SELECT COUNT(*) FROM personal WHERE estado = 'activo'
			""")
			total_personal = cursor.fetchone()[0] or 0
			hoy = timezone.now().date()
			cursor.execute("""
				SELECT COUNT(DISTINCT id_personal) 
				FROM control_asistencia 
				WHERE DATE(fecha) = %s
			""", [hoy])
			asistencia_hoy = cursor.fetchone()[0] or 0
			cursor.execute("""
				SELECT COUNT(*) FROM usuarios WHERE estado = 'activo'
			""")
			total_usuarios = cursor.fetchone()[0] or 0
			cursor.execute("""
				SELECT COUNT(*) 
				FROM orden_produccion 
				WHERE estado IN ('Pendiente', 'En Proceso')
			""")
			ordenes_activas = cursor.fetchone()[0] or 0
			cursor.execute("""
				SELECT COUNT(*) 
				FROM inventario 
				WHERE cantidad_actual <= stock_minimo
			""")
			inventario_critico = cursor.fetchone()[0] or 0
			ultimo_mes = timezone.now() - timedelta(days=30)
			cursor.execute("""
				SELECT 
					COUNT(*) as total,
					SUM(CASE WHEN estado = 'Completado' THEN 1 ELSE 0 END) as completadas
				FROM orden_produccion
				WHERE fecha_inicio >= %s
			""", [ultimo_mes])
			resultado_eficiencia = cursor.fetchone()
			total_ordenes = resultado_eficiencia[0] or 0
			ordenes_completadas = resultado_eficiencia[1] or 0
			eficiencia = round((ordenes_completadas / total_ordenes), 2) if total_ordenes > 0 else 0.0
			cursor.execute("""
				SELECT 
					accion,
					descripcion,
					fecha_hora,
					username
				FROM bitacora
				ORDER BY fecha_hora DESC
				LIMIT 5
			""")
			actividades_raw = cursor.fetchall()
			actividades = []
			for act in actividades_raw:
				tiempo_transcurrido = calcular_tiempo_transcurrido(act[2])
				actividades.append({
					'titulo': act[0],
					'detalle': act[1],
					'hace': tiempo_transcurrido,
					'usuario': act[3]
				})
			datos = {
				'kpis': {
					'totalPersonal': total_personal,
					'asistenciaHoy': asistencia_hoy,
					'usuarios': total_usuarios,
					'ordenes': ordenes_activas,
					'inventarioCritico': inventario_critico,
					'eficiencia': eficiencia
				},
				'actividad': actividades
			}
			return Response(datos, status=status.HTTP_200_OK)
	except Exception as e:
		return Response(
			{'error': f'Error al obtener estadísticas: {str(e)}'}, 
			status=status.HTTP_500_INTERNAL_SERVER_ERROR
		)

def calcular_tiempo_transcurrido(fecha_hora):
	if isinstance(fecha_hora, str):
		fecha_hora = datetime.fromisoformat(fecha_hora.replace('Z', '+00:00'))
	ahora = timezone.now()
	if fecha_hora.tzinfo is None:
		fecha_hora = timezone.make_aware(fecha_hora)
	diferencia = ahora - fecha_hora
	segundos = diferencia.total_seconds()
	if segundos < 60:
		return 'hace menos de 1 minuto'
	elif segundos < 3600:
		minutos = int(segundos / 60)
		return f'hace {minutos} minuto{"s" if minutos > 1 else ""}'
	elif segundos < 86400:
		horas = int(segundos / 3600)
		return f'hace {horas} hora{"s" if horas > 1 else ""}'
	elif segundos < 604800:
		dias = int(segundos / 86400)
		return f'hace {dias} día{"s" if dias > 1 else ""}'
	else:
		semanas = int(segundos / 604800)
		return f'hace {semanas} semana{"s" if semanas > 1 else ""}'

@api_view(['GET'])
def obtener_ordenes_recientes(request):
	try:
		with connection.cursor() as cursor:
			cursor.execute("""
				SELECT 
					id_orden,
					producto_modelo,
					cantidad_total,
					estado,
					fecha_inicio,
					fecha_entrega
				FROM orden_produccion
				ORDER BY fecha_inicio DESC
				LIMIT 10
			""")
			ordenes_raw = cursor.fetchall()
			ordenes = []
			for orden in ordenes_raw:
				ordenes.append({
					'id': orden[0],
					'producto': orden[1],
					'cantidad': orden[2],
					'estado': orden[3],
					'fecha_orden': orden[4],
					'fecha_entrega': orden[5]
				})
			return Response(ordenes, status=status.HTTP_200_OK)
	except Exception as e:
		return Response(
			{'error': f'Error al obtener órdenes: {str(e)}'}, 
			status=status.HTTP_500_INTERNAL_SERVER_ERROR
		)

@api_view(['GET'])
def obtener_inventario_critico(request):
	try:
		with connection.cursor() as cursor:
			cursor.execute("""
				SELECT 
					id_inventario,
					nombre_materia_prima,
					cantidad_actual,
					stock_minimo,
					unidad_medida
				FROM inventario
				WHERE cantidad_actual <= stock_minimo
				ORDER BY cantidad_actual ASC
				LIMIT 10
			""")
			productos_raw = cursor.fetchall()
			productos = []
			for prod in productos_raw:
				productos.append({
					'id': prod[0],
					'nombre': prod[1],
					'cantidad': prod[2],
					'stock_minimo': prod[3],
					'unidad': prod[4],
					'deficit': float(prod[3]) - float(prod[2])
				})
			return Response(productos, status=status.HTTP_200_OK)
	except Exception as e:
		return Response(
			{'error': f'Error al obtener inventario crítico: {str(e)}'}, 
			status=status.HTTP_500_INTERNAL_SERVER_ERROR
		)
