from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Inventario
from .serializers import InventarioSerializer, RegistrarInventarioSerializer
from Lotes.models import Lote  # 🔹 Importamos el modelo Lote
from Lotes.models import MateriaPrima 

# 🟢 LISTAR INVENTARIO COMPLETO
@api_view(['GET'])
def listar_inventario(request):
    inventarios = Inventario.objects.all()
    serializer = InventarioSerializer(inventarios, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 OBTENER UN REGISTRO ESPECÍFICO DEL INVENTARIO
@api_view(['GET'])
def obtener_inventario(request, id_inventario):
    try:
        inventario = Inventario.objects.get(id_inventario=id_inventario)
    except Inventario.DoesNotExist:
        return Response({'error': 'Registro de inventario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    serializer = InventarioSerializer(inventario)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 REGISTRAR NUEVO INVENTARIO (buscando nombre de materia prima por lote)
@api_view(['POST'])
def registrar_inventario(request):
    serializer = RegistrarInventarioSerializer(data=request.data)
    if serializer.is_valid():
        cod_lote = serializer.validated_data.get('cod_lote')

        # 1️⃣ Buscar el lote por código
        try:
            lote = Lote.objects.get(codigo_lote=cod_lote)
        except Lote.DoesNotExist:
            return Response({'error': f'No existe un lote con código "{cod_lote}"'}, status=status.HTTP_400_BAD_REQUEST)

        # 2️⃣ Buscar la materia prima asociada a ese lote
        try:
            materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
        except MateriaPrima.DoesNotExist:
            return Response({'error': f'No existe materia prima con id {lote.id_materia} asociada al lote'}, status=status.HTTP_400_BAD_REQUEST)

        # 3️⃣ Crear nuevo registro de inventario
        Inventario.objects.create(
            nombre_materia_prima=materia.nombre,
            cantidad_actual=lote.cantidad,
            unidad_medida=serializer.validated_data['unidad_medida'],
            ubicacion=serializer.validated_data['ubicacion'],
            estado=serializer.validated_data['estado'],
            fecha_actualizacion=serializer.validated_data['fecha_actualizacion'],
            id_lote=lote.id_lote
        )

        return Response({'mensaje': 'Inventario registrado correctamente'}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)



# 🟢 ACTUALIZAR UN REGISTRO DE INVENTARIO EXISTENTE
@api_view(['PUT', 'PATCH'])
def actualizar_inventario(request, id_inventario):
    try:
        inventario = Inventario.objects.get(id_inventario=id_inventario)
    except Inventario.DoesNotExist:
        return Response({'error': 'Registro de inventario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    partial = request.method == 'PATCH'
    serializer = InventarioSerializer(inventario, data=request.data, partial=partial)
    if serializer.is_valid():
        serializer.save()
        return Response({'mensaje': 'Inventario actualizado correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ELIMINAR UN REGISTRO DE INVENTARIO
@api_view(['DELETE'])
def eliminar_inventario(request, id_inventario):
    try:
        inventario = Inventario.objects.get(id_inventario=id_inventario)
    except Inventario.DoesNotExist:
        return Response({'error': 'Registro de inventario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    inventario.delete()
    return Response({'mensaje': 'Inventario eliminado correctamente'}, status=status.HTTP_204_NO_CONTENT)
