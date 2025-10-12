from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import NotaSalida, DetalleNotaSalida
from .serializers import (
    NotaSalidaSerializer,
    RegistrarNotaSalidaSerializer,
    DetalleNotaSalidaSerializer,
    RegistrarDetalleNotaSalidaSerializer
)
from Lotes.models import Lote, MateriaPrima
from Inventario.models import Inventario
from personal.models import personal

# ============================================================
# 🟢 CRUD NOTA SALIDA (CABECERA)
# ============================================================

@api_view(['GET'])
def listar_notas_salida(request):
    notas = NotaSalida.objects.all()
    serializer = NotaSalidaSerializer(notas, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = NotaSalidaSerializer(nota)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🔹 REGISTRAR NOTA DE SALIDA USANDO id_usuario DESDE LA URL
@api_view(['POST'])
def registrar_nota_salida(request, id_usuario):
    serializer = RegistrarNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        # Buscar el personal asociado al usuario
        try:
            persona = personal.objects.get(id_usuario=id_usuario)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal asociado al usuario con id {id_usuario}'},
                            status=status.HTTP_400_BAD_REQUEST)

        # Crear la nota de salida
        nota = NotaSalida.objects.create(
            fecha_salida=serializer.validated_data['fecha_salida'],
            motivo=serializer.validated_data['motivo'],
            estado=serializer.validated_data['estado'],
            id_personal=persona.id
        )

        return Response(
            {'mensaje': 'Nota de salida registrada correctamente', 'id_salida': nota.id_salida},
            status=status.HTTP_201_CREATED
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def actualizar_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = RegistrarNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        for campo, valor in serializer.validated_data.items():
            setattr(nota, campo, valor)
        nota.save()
        return Response({'mensaje': 'Nota de salida actualizada correctamente'}, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def eliminar_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    nota.delete()
    return Response({'mensaje': 'Nota de salida eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)


# ============================================================
# 🟢 CRUD DETALLE NOTA SALIDA
# ============================================================

@api_view(['GET'])
def listar_detalles_salida(request, id_salida):
    detalles = DetalleNotaSalida.objects.filter(id_salida=id_salida)
    serializer = DetalleNotaSalidaSerializer(detalles, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = DetalleNotaSalidaSerializer(detalle)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 REGISTRAR DETALLE DE NOTA DE SALIDA (recibe id_salida por URL)
@api_view(['POST'])
def registrar_detalle_salida(request, id_salida):
    serializer = RegistrarDetalleNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        cod_lote = serializer.validated_data['cod_lote']
        cantidad_salida = serializer.validated_data['cantidad']
        unidad_medida = serializer.validated_data['unidad_medida']

        # ✅ Verificar que la nota de salida exista
        try:
            nota = NotaSalida.objects.get(id_salida=id_salida)
        except NotaSalida.DoesNotExist:
            return Response({'error': f'No existe una nota de salida con id {id_salida}'},status=status.HTTP_400_BAD_REQUEST)

        # ✅ Buscar lote por su código
        try:
            lote = Lote.objects.get(codigo_lote=cod_lote)
        except Lote.DoesNotExist:
            return Response({'error': f'No existe un lote con código "{cod_lote}"'},
                            status=status.HTTP_400_BAD_REQUEST)

        # ✅ Obtener materia prima asociada al lote
        try:
            materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
        except MateriaPrima.DoesNotExist:
            return Response({'error': f'No existe materia prima asociada al lote "{cod_lote}"'},
                            status=status.HTTP_400_BAD_REQUEST)

        # ✅ Crear el detalle de nota de salida
        DetalleNotaSalida.objects.create(
            id_salida=id_salida,
            id_lote=lote.id_lote,
            nombre_materia_prima=materia.nombre,
            cantidad=cantidad_salida,
            unidad_medida=unidad_medida
        )

        # ✅ Actualizar inventario restando la cantidad
        try:
            inventario = Inventario.objects.get(id_lote=lote.id_lote)
            inventario.cantidad_actual -= cantidad_salida
            inventario.save()
        except Inventario.DoesNotExist:
            pass  # Si no existe, no se hace nada

        return Response({'mensaje': 'Detalle de nota de salida registrado correctamente'},
                        status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def actualizar_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    serializer = DetalleNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        for campo, valor in serializer.validated_data.items():
            setattr(detalle, campo, valor)
        detalle.save()
        return Response({'mensaje': 'Detalle actualizado correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def eliminar_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    detalle.delete()
    return Response({'mensaje': 'Detalle eliminado correctamente'}, status=status.HTTP_204_NO_CONTENT)
