from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError, DataError
from django.shortcuts import get_object_or_404
from datetime import datetime, date, time
from .models import asistencia
from personal.models import personal
from turnos.models import turnos

@api_view(['POST'])
def agregar_asistencia(request):
    try:
        # Obtener datos del request
        nombre = request.data.get('nombre')
        fecha = request.data.get('fecha', date.today())
        turno_nombre = request.data.get('turno')
        estado = request.data.get('estado')
        hora_actual = datetime.now().time()
        # Validar campos requeridos
        if not nombre:
            return Response({
                "error": "El campo 'nombre' es requerido."
            }, status=status.HTTP_400_BAD_REQUEST)

        if not turno_nombre:
            return Response({
                "error": "El campo 'turno' es requerido."
            }, status=status.HTTP_400_BAD_REQUEST)

        if not estado:
            return Response({
                "error": "El campo 'estado' es requerido."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar que el personal exista por nombre y obtener su ID
        try:
            # AJUSTA ESTA CONSULTA según tu modelo de Personal
            personal_obj = personal.objects.get(nombre_completo=nombre)
            id_personal = personal_obj.id
        except personal.DoesNotExist:
            return Response({
                "error": f"El personal con nombre '{nombre}' no existe en la base de datos."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar que el turno exista y esté activo
        try:
            turno_obj = turnos.objects.get(turno=turno_nombre, estado='activo')
            id_turno = turno_obj.id
            print(id_turno)
        except turnos.DoesNotExist:
            return Response({
                "error": f"No se encontró un turno activo con el nombre '{turno_nombre}'."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar que el estado sea válido
        estados_permitidos = ['Presente', 'Ausente', 'Tarde', 'Licencia']
        if estado not in estados_permitidos:
            return Response({
                "error": f"Estado debe ser uno de: {', '.join(estados_permitidos)}"
            }, status=status.HTTP_400_BAD_REQUEST)

        # Crear y guardar la nueva asistencia
        nueva_asistencia = asistencia(
            fecha=fecha,
            hora_marcado=hora_actual,
            estado=estado,
            id_personal=id_personal,
            id_turno=id_turno
        )
        
        nueva_asistencia.save()
        
        return Response({
            "message": "Asistencia registrada exitosamente.",
            "id_control": nueva_asistencia.id_control,
            "fecha": nueva_asistencia.fecha,
            "estado": nueva_asistencia.estado,
            "nombre_personal": nombre,
            "id_personal": id_personal,
            "turno": turno_nombre,
            "id_turno": id_turno
        }, status=status.HTTP_201_CREATED)

    except IntegrityError as e:
        return Response({
            "error": "Error de integridad en la base de datos.",
            "detalle": str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except DataError as e:
        return Response({
            "error": "Error en los datos proporcionados.",
            "detalle": str(e)
        }, status=status.HTTP_400_BAD_REQUEST)
    
    except Exception as e:
        return Response({
            "error": "Error interno del servidor.",
            "detalle": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['GET'])
def obtener_asistencias(request):
    try:
        # Obtener todas las asistencias
        asistencias = asistencia.objects.all()
        
        # Lista para almacenar los datos formateados
        asistencias_formateadas = []
        
        for asist in asistencias:
            try:
                # Obtener el nombre del personal
                personal_obj = personal.objects.get(id=asist.id_personal)
                nombre_personal = personal_obj.nombre_completo
            except personal.DoesNotExist:
                nombre_personal = "Personal no encontrado"
            
            try:
                # Obtener los datos del turno
                turno_obj = turnos.objects.get(id=asist.id_turno)
                # Formatear el string del turno: "Turno (HH:MM - HH:MM)"
                turno_str = f"{turno_obj.turno} ({turno_obj.hora_entrada.strftime('%H:%M')} - {turno_obj.hora_salida.strftime('%H:%M')})"
            except turnos.DoesNotExist:
                turno_str = "Turno no encontrado"
            
            # Crear el objeto formateado
            asistencia_formateada = {
                "id_control": asist.id_control,
                "fecha": asist.fecha,
                "hora_marcada": asist.hora_marcado,
                "estado": asist.estado,
                "nombre_personal": nombre_personal,
                "turno_completo": turno_str,
                "id_personal": asist.id_personal,  # Por si acaso
                "id_turno": asist.id_turno         # Por si acaso
            }
            
            asistencias_formateadas.append(asistencia_formateada)
        
        return Response({
            "asistencias": asistencias_formateadas,
            "total": len(asistencias_formateadas)
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            "error": "Error al obtener las asistencias",
            "detalle": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT', 'PATCH'])
def actualizar_asistencia(request, id_control):
    try:
        # Buscar la asistencia por ID
        asist = get_object_or_404(asistencia, id_control=id_control)
        
        # Obtener datos del request
        nombre = request.data.get('nombre')
        fecha = request.data.get('fecha')
        turno_nombre = request.data.get('turno')
        estado = request.data.get('estado')
        
        # Actualizar fecha si se proporciona
        if fecha:
            asist.fecha = fecha
        
        # Actualizar estado si se proporciona
        if estado:
            estados_permitidos = ['Presente', 'Ausente', 'Tarde', 'Licencia']
            if estado not in estados_permitidos:
                return Response({
                    "error": f"Estado debe ser uno de: {', '.join(estados_permitidos)}"
                }, status=status.HTTP_400_BAD_REQUEST)
            asist.estado = estado
        
        # Actualizar personal si se proporciona
        if nombre:
            try:
                personal_obj = personal.objects.get(nombre_completo=nombre)
                asist.id_personal = personal_obj.id
            except personal.DoesNotExist:
                return Response({
                    "error": f"El personal con nombre '{nombre}' no existe."
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Actualizar turno si se proporciona
        if turno_nombre:
            try:
                turno_obj = turnos.objects.get(turno=turno_nombre, estado='activo')
                asist.id_turno = turno_obj.id
            except turnos.DoesNotExist:
                return Response({
                    "error": f"No se encontró un turno activo con el nombre '{turno_nombre}'."
                }, status=status.HTTP_400_BAD_REQUEST)
        
        # Guardar cambios
        asist.save()
        
        return Response({
            "message": "Asistencia actualizada exitosamente.",
            "id_control": asist.id_control,
            "fecha": asist.fecha,
            "estado": asist.estado
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            "error": "Error al actualizar la asistencia",
            "detalle": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
def eliminar_asistencia(request, id_control):
    try:
        # Buscar la asistencia por ID
        asist = get_object_or_404(asistencia, id_control=id_control)
        
        # Guardar info antes de eliminar
        info_eliminada = {
            "id_control": asist.id_control,
            "fecha": asist.fecha,
            "estado": asist.estado
        }
        
        # Eliminar la asistencia
        asist.delete()
        
        return Response({
            "message": "Asistencia eliminada exitosamente.",
            "asistencia_eliminada": info_eliminada
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            "error": "Error al eliminar la asistencia",
            "detalle": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)