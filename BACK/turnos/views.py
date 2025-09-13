from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import turnos
from .serializers import TurnosSerializer
from personal.models import personal
from django.db import connection

# Create your views here.
@api_view(['POST'])
def agregar_turno(request):
    descripcion = request.data.get('descripcion')
    dia = request.data.get('dia')
    hora_entrada = request.data.get('hora_entrada')
    hora_salida = request.data.get('hora_salida')
    nombre = request.data.get('nombre_personal')
    try:
        with connection.cursor() as cursor:
            cursor.execute("CALL agregar_turno_a_personal(%s, %s, %s, %s, %s)", 
                           [descripcion, dia, hora_entrada, hora_salida, nombre]
                           )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'mensaje': 'Emeplado actualizado con éxito'}, status=status.HTTP_200_OK)

@api_view(['GET'])
def obtener_turnos(request):
    turnos_list = turnos.objects.all()
    serializer = TurnosSerializer(turnos_list, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)




