from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import MateriaPrima, Lote
from .serializers import MateriaPrimaSerializer, LoteSerializer


# ---------- MATERIA PRIMA ----------
@api_view(['GET'])
def listar_materias_primas(request):
    materias = MateriaPrima.objects.all()
    serializer = MateriaPrimaSerializer(materias, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def insertar_materia_prima(request):
    serializer = MateriaPrimaSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def actualizar_materia_prima(request, id_materia):
    try:
        materia = MateriaPrima.objects.get(id_materia=id_materia)
    except MateriaPrima.DoesNotExist:
        return Response({'error': 'Materia Prima no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = MateriaPrimaSerializer(materia, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def eliminar_materia_prima(request, id_materia):
    try:
        materia = MateriaPrima.objects.get(id_materia=id_materia)
    except MateriaPrima.DoesNotExist:
        return Response({'error': 'Materia Prima no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    materia.delete()
    return Response({'mensaje': 'Materia Prima eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)


# ---------- LOTES ----------
@api_view(['GET'])
def listar_lotes(request):
    lotes = Lote.objects.all()
    serializer = LoteSerializer(lotes, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def insertar_lote(request):
    serializer = LoteSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def actualizar_lote(request, id_lote):
    try:
        lote = Lote.objects.get(id_lote=id_lote)
    except Lote.DoesNotExist:
        return Response({'error': 'Lote no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = LoteSerializer(lote, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def eliminar_lote(request, id_lote):
    try:
        lote = Lote.objects.get(id_lote=id_lote)
    except Lote.DoesNotExist:
        return Response({'error': 'Lote no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    lote.delete()
    return Response({'mensaje': 'Lote eliminado correctamente'}, status=status.HTTP_204_NO_CONTENT)
