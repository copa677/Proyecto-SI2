from django.shortcuts import render
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import personal
from .serializers import EmpleadoSerializer
from django.db import connection 

# Create your views here.

@api_view(['POST'])
def registrar_Empleado(request):
    nombre_completo = request.data.get('nombre_completo')
    direccion = request.data.get('direccion')
    telefono = request.data.get('telefono')
    rol = request.data.get('rol')
    fecha_nacimiento = request.data.get('fecha_nacimiento')
    estado = request.data.get('estado')
    username = request.data.get('username')

    if personal.objects.filter(nombre_completo=nombre_completo).exists():
            return Response({'error': 'El Empleado ya existe'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "CALL registrar_empleado(%s, %s, %s, %s, %s, %s, %s)", 
                [nombre_completo, direccion, telefono, rol, fecha_nacimiento, estado, username]
            )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'mensaje': 'Empleado agregado con éxito'}, status=status.HTTP_200_OK)



@api_view(['GET'])
def obtener_empleados(request):
    empleados = personal.objects.all()
    serializer = EmpleadoSerializer(empleados, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_empleado_nombre(request, nombre):
    try:
        empleado = personal.objects.get(nombre_completo=nombre)
        serializer = EmpleadoSerializer(empleado)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except personal.DoesNotExist:
        return Response({'error': 'Empleado no encontrado'}, status=status.HTTP_404_NOT_FOUND)

 
@api_view(['GET'])
def obtener_empleado_por_usuario(request, id_usuario):
    try:
        empleado = personal.objects.get(id_usuario=id_usuario)
        serializer = EmpleadoSerializer(empleado)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except personal.DoesNotExist:
        return Response({'error': 'Empleado no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    
@api_view(['POST'])
def actualizar_empleado(request):
    nombre_completo = request.data.get('nombre_completo')
    direccion = request.data.get('direccion')
    telefono = request.data.get('telefono')
    rol = request.data.get('rol')
    fecha_nacimiento = request.data.get('fecha_nacimiento')
    estado = request.data.get('estado')
    id_usuario = request.data.get('id_usuario')
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "CALL actualizar_empleado(%s, %s, %s, %s, %s, %s, %s)", 
                [nombre_completo, direccion, telefono, rol, fecha_nacimiento, estado, id_usuario]
            )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'mensaje': 'Empleado agregado con éxito'}, status=status.HTTP_200_OK)

@api_view(['POST'])
def eliminar_empleado(request):
    id_usuario = request.data.get('id_usuario')
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "CALL eliminar_empleado_usuario(%s)", 
                [id_usuario]
            )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'mensaje': 'Empleado y Usuario Eliminado con éxito'}, status=status.HTTP_200_OK)