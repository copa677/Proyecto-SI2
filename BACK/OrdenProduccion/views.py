from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from .models import OrdenProduccion
from .serializers import (
    OrdenProduccionSerializers,
    InsertarOrdenProduccionSerializers,
    CrearOrdenConMateriasSerializer
)
# Importamos el modelo y serializer de Trazabilidad
from Trazabilidad.models import Trazabilidad
from Trazabilidad.serializers import TrazabilidadSerializer
# Importamos modelos para nota de salida e inventario
from NotaSalida.models import NotaSalida, DetalleNotaSalida
from Inventario.models import Inventario
from datetime import date

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


# 🔹 CREAR ORDEN DE PRODUCCIÓN CON MATERIAS PRIMAS Y GENERAR NOTA DE SALIDA AUTOMÁTICAMENTE
@api_view(['POST'])
@transaction.atomic
def crear_orden_con_materias(request):
    """
    Crea una orden de producción, genera automáticamente una nota de salida
    y descuenta las materias primas del inventario.
    """
    serializer = CrearOrdenConMateriasSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    
    data = serializer.validated_data
    
    # 1️⃣ Crear la orden de producción
    orden = OrdenProduccion.objects.create(
        cod_orden=data['cod_orden'],
        fecha_inicio=data['fecha_inicio'],
        fecha_fin=data['fecha_fin'],
        fecha_entrega=data['fecha_entrega'],
        estado='En Proceso',
        producto_modelo=data['producto_modelo'],
        color=data['color'],
        talla=data['talla'],
        cantidad_total=data['cantidad_total'],
        id_personal=data['id_personal']
    )
    
    # 2️⃣ Crear nota de salida automáticamente
    nota_salida = NotaSalida.objects.create(
        fecha_salida=date.today(),
        motivo=f'Producción: {data["producto_modelo"]} - {data["cod_orden"]}',
        estado='Completado',
        id_personal=data['id_personal']
    )
    
    # 3️⃣ Procesar cada materia prima
    materias_usadas = []
    for materia_data in data['materias_primas']:
        id_inventario = materia_data['id_inventario']
        cantidad_requerida = materia_data['cantidad']
        
        # Verificar que existe en inventario
        try:
            inventario_item = Inventario.objects.get(id_inventario=id_inventario)
        except Inventario.DoesNotExist:
            transaction.set_rollback(True)
            return Response(
                {'error': f'El item de inventario con id {id_inventario} no existe.'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar stock suficiente
        if inventario_item.cantidad_actual < cantidad_requerida:
            transaction.set_rollback(True)
            return Response(
                {'error': f'Stock insuficiente para {inventario_item.nombre_materia_prima}. Disponible: {inventario_item.cantidad_actual}, Requerido: {cantidad_requerida}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Crear detalle de nota de salida
        DetalleNotaSalida.objects.create(
            id_salida=nota_salida.id_salida,
            id_lote=inventario_item.id_lote,
            nombre_materia_prima=inventario_item.nombre_materia_prima,
            cantidad=cantidad_requerida,
            unidad_medida=inventario_item.unidad_medida
        )
        
        # Descontar del inventario
        inventario_item.cantidad_actual -= cantidad_requerida
        inventario_item.save()
        
        # Registrar trazabilidad
        Trazabilidad.objects.create(
            id_lote=inventario_item.id_lote,
            id_orden=orden.id_orden,
            cantidad_usada=cantidad_requerida,
            fecha_registro=date.today()
        )
        
        materias_usadas.append({
            'nombre': inventario_item.nombre_materia_prima,
            'cantidad': float(cantidad_requerida),
            'lote': inventario_item.id_lote
        })
    
    return Response({
        'mensaje': 'Orden de producción creada exitosamente',
        'id_orden': orden.id_orden,
        'cod_orden': orden.cod_orden,
        'id_nota_salida': nota_salida.id_salida,
        'materias_consumidas': materias_usadas
    }, status=status.HTTP_201_CREATED)


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