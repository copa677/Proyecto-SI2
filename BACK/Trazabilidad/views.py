from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Trazabilidad
from .serializers import TrazabilidadSerializer, InsertarTrazabilidadSerializer
from personal.models import personal   # Importar modelo personal


# 🟢 LISTAR TODAS LAS TRAZABILIDADES
@api_view(['GET'])
def listar_trazabilidades(request):
    trazas = Trazabilidad.objects.all()
    serializer = TrazabilidadSerializer(trazas, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 OBTENER TRAZABILIDAD POR ID
@api_view(['GET'])
def obtener_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = TrazabilidadSerializer(traza)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 INSERTAR NUEVA TRAZABILIDAD (usando nombre del personal)
@api_view(['POST'])
def insertar_trazabilidad(request):
    serializer = InsertarTrazabilidadSerializer(data=request.data)
    if serializer.is_valid():
        nombre_personal = serializer.validated_data.get('nombre_personal')

        # Buscar al personal por nombre completo
        try:
            persona = personal.objects.get(nombre_completo=nombre_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el nombre "{nombre_personal}"'}, status=status.HTTP_400_BAD_REQUEST)

        # Crear registro en Trazabilidad
        nueva_traza = Trazabilidad.objects.create(
            proceso=serializer.validated_data['proceso'],
            descripcion_proceso=serializer.validated_data['descripcion_proceso'],
            fecha_registro=serializer.validated_data['fecha_registro'],
            hora_inicio=serializer.validated_data['hora_inicio'],
            hora_fin=serializer.validated_data['hora_fin'],
            cantidad=serializer.validated_data['cantidad'],
            estado=serializer.validated_data['estado'],
            id_personal=persona.id,  # ID obtenido desde la tabla personal
            id_orden=serializer.validated_data['id_orden']
        )

        return Response({'mensaje': 'Trazabilidad registrada correctamente'}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ACTUALIZAR TRAZABILIDAD EXISTENTE
@api_view(['PUT'])
def actualizar_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = InsertarTrazabilidadSerializer(data=request.data)
    if serializer.is_valid():
        nombre_personal = serializer.validated_data.get('nombre_personal')

        try:
            persona = personal.objects.get(nombre_completo=nombre_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el nombre "{nombre_personal}"'}, status=status.HTTP_400_BAD_REQUEST)

        # Actualizar campos
        for campo, valor in serializer.validated_data.items():
            if campo != 'nombre_personal':  # este no se guarda directamente
                setattr(traza, campo, valor)
        traza.id_personal = persona.id
        traza.save()

        return Response({'mensaje': 'Trazabilidad actualizada correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ELIMINAR TRAZABILIDAD
@api_view(['DELETE'])
def eliminar_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    traza.delete()
    return Response({'mensaje': 'Trazabilidad eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)
