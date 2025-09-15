from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import IntegrityError, DataError
from django.shortcuts import get_object_or_404
from datetime import time
from .models import turnos
from .serializers import TurnosSerializer

@api_view(['POST'])
def agregar_turno(request):
    try:
        # Validar datos con el serializer
        serializer = TurnosSerializer(data=request.data)
        if not serializer.is_valid():
            return Response({
                "error": "Datos inválidos",
                "detalles": serializer.errors
            }, status=status.HTTP_400_BAD_REQUEST)

        # Obtener datos validados
        descripcion = serializer.validated_data['turno']
        hora_entrada = serializer.validated_data['hora_entrada']
        hora_salida = serializer.validated_data['hora_salida']
        estado = serializer.validated_data.get('estado', 'activo')

        # Validar que la hora de entrada sea anterior a la de salida
        if hora_entrada >= hora_salida:
            return Response({
                "error": "La hora de entrada debe ser anterior a la hora de salida."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar longitud del campo turno
        if len(descripcion) > 10:
            return Response({
                "error": "El nombre del turno no puede exceder 10 caracteres."
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar superposición de horarios (solo para turnos activos)
        if estado == 'activo':
            turnos_activos = turnos.objects.filter(estado='activo')
            for turno_existente in turnos_activos:
                if (hora_entrada < turno_existente.hora_salida and 
                    hora_salida > turno_existente.hora_entrada):
                    return Response({
                        "error": "El turno se superpone con un turno activo existente.",
                        "turno_existente": turno_existente.turno
                    }, status=status.HTTP_400_BAD_REQUEST)

        # Crear y guardar el nuevo turno
        nuevo_turno = turnos(
            turno=descripcion,
            hora_entrada=hora_entrada,
            hora_salida=hora_salida,
            estado=estado
        )
        
        nuevo_turno.save()
        
        return Response({
            "message": "Turno agregado exitosamente.",
            "id": nuevo_turno.id,
            "turno": nuevo_turno.turno,
            "hora_entrada": nuevo_turno.hora_entrada,
            "hora_salida": nuevo_turno.hora_salida,
            "estado": nuevo_turno.estado
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
def obtener_turnos(request):
    turnos_list = turnos.objects.all()
    serializer = TurnosSerializer(turnos_list, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)

@api_view(['PATCH'])
def desactivar_turno(request, turno_id):
    try:
        # Buscar el turno por ID
        turno = get_object_or_404(turnos, id=turno_id)
        
        # Verificar si ya está inactivo
        if turno.estado == 'Inactivo':
            return Response({
                "message": "El turno ya está inactivo.",
                "id": turno.id,
                "turno": turno.turno,
                "estado": turno.estado
            }, status=status.HTTP_200_OK)
        
        # Cambiar el estado a inactivo
        turno.estado = 'inactivo'
        turno.save()
        
        return Response({
            "message": "Turno desactivado exitosamente.",
            "id": turno.id,
            "turno": turno.turno,
            "estado_anterior": 'activo',
            "estado_actual": turno.estado
        }, status=status.HTTP_200_OK)
        
    except Exception as e:
        return Response({
            "error": "Error interno del servidor.",
            "detalle": str(e)
        }, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


