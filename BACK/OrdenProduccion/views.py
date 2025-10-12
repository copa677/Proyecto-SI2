from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import OrdenProduccion
from .serializers import (
    OrdenProduccionSerializers,
    InsertarOrdenProduccionSerializers
)
# Importamos el modelo y serializer de Trazabilidad
from Trazabilidad.models import Trazabilidad
from Trazabilidad.serializers import TrazabilidadSerializer

# 🟢 LISTAR TODAS LAS ÓRDENES
@api_view(['GET'])
def listar_ordenes_produccion(request):
    ordenes = OrdenProduccion.objects.all()
    serializer = OrdenProduccionSerializers(ordenes, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 OBTENER ORDEN POR ID
@api_view(['GET'])
def obtener_orden_produccion(request, id_orden):
    try:
        orden = OrdenProduccion.objects.get(id_orden=id_orden)
    except OrdenProduccion.DoesNotExist:
        return Response({'error': 'Orden de producción no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = OrdenProduccionSerializers(orden)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 INSERTAR NUEVA ORDEN
@api_view(['POST'])
def insertar_orden_produccion(request):
    serializer = InsertarOrdenProduccionSerializers(data=request.data)
    if serializer.is_valid():
        OrdenProduccion.objects.create(**serializer.validated_data)
        return Response({'mensaje': 'Orden de producción registrada correctamente'}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ACTUALIZAR ORDEN EXISTENTE
@api_view(['PUT'])
def actualizar_orden_produccion(request, id_orden):
    try:
        orden = OrdenProduccion.objects.get(id_orden=id_orden)
    except OrdenProduccion.DoesNotExist:
        return Response({'error': 'Orden de producción no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = InsertarOrdenProduccionSerializers(data=request.data)
    if serializer.is_valid():
        for campo, valor in serializer.validated_data.items():
            setattr(orden, campo, valor)
        orden.save()
        return Response({'mensaje': 'Orden de producción actualizada correctamente'}, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ELIMINAR ORDEN
@api_view(['DELETE'])
def eliminar_orden_produccion(request, id_orden):
    try:
        orden = OrdenProduccion.objects.get(id_orden=id_orden)
    except OrdenProduccion.DoesNotExist:
        return Response({'error': 'Orden de producción no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    orden.delete()
    return Response({'mensaje': 'Orden de producción eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)

# 🟣 OBTENER TRAZABILIDAD DE UNA ORDEN DE PRODUCCIÓN
@api_view(['GET'])
def obtener_trazabilidad_orden(request, id_orden):
    """
    Retorna todas las trazabilidades asociadas a una orden de producción.
    """
    try:
        # Primero, verificar si la orden existe
        orden = OrdenProduccion.objects.get(id_orden=id_orden)
    except OrdenProduccion.DoesNotExist:
        return Response({'error': 'Orden de producción no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    # Obtener todas las trazabilidades relacionadas
    trazas = Trazabilidad.objects.filter(id_orden=id_orden)

    if not trazas.exists():
        return Response({'mensaje': 'No hay trazabilidades registradas para esta orden'}, status=status.HTTP_200_OK)

    serializer = TrazabilidadSerializer(trazas, many=True)
    return Response({
        'orden': orden.cod_orden,
        'total_trazabilidades': trazas.count(),
        'trazabilidades': serializer.data
    }, status=status.HTTP_200_OK)