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
from Lotes.models import Lote, MateriaPrima
from personal.models import personal
from datetime import date, datetime, time

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
    
    # 2️⃣ Obtener información del personal responsable
    try:
        persona = personal.objects.get(id=data['id_personal'])
        nombre_solicitante = persona.nombre_completo
        area_solicitante = persona.rol  # Usamos el rol como área
    except personal.DoesNotExist:
        nombre_solicitante = "N/A"
        area_solicitante = "N/A"
    
    # 3️⃣ Crear nota de salida automáticamente
    nota_salida = NotaSalida.objects.create(
        fecha_salida=date.today(),
        motivo=f'Producción: {data["producto_modelo"]} - {data["cod_orden"]}',
        estado='Completado',
        id_personal=data['id_personal']
    )
    
    # 4️⃣ Procesar cada materia prima con consumo FIFO de lotes
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
        
        nombre_materia = inventario_item.nombre_materia_prima
        unidad = inventario_item.unidad_medida
        
        # 🔹 Obtener todos los LOTES disponibles de esta materia prima, ordenados por id_lote (FIFO)
        # Primero obtener el id_materia
        try:
            materia = MateriaPrima.objects.get(nombre=nombre_materia)
            id_materia = materia.id_materia
        except MateriaPrima.DoesNotExist:
            transaction.set_rollback(True)
            return Response(
                {'error': f'No se encontró la materia prima {nombre_materia}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Obtener lotes disponibles con cantidad > 0, ordenados por id (FIFO)
        lotes_disponibles = Lote.objects.filter(
            id_materia=id_materia,
            cantidad__gt=0
        ).order_by('id_lote')
        
        # Verificar stock total disponible
        stock_total = sum(lote.cantidad for lote in lotes_disponibles)
        if stock_total < cantidad_requerida:
            transaction.set_rollback(True)
            return Response(
                {'error': f'Stock insuficiente para {nombre_materia}. Disponible: {stock_total}, Requerido: {cantidad_requerida}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 🔹 Consumir de los lotes disponibles (FIFO)
        cantidad_restante = cantidad_requerida
        lotes_consumidos = []
        
        for lote in lotes_disponibles:
            if cantidad_restante <= 0:
                break
            
            # ✅ Asegurar que no se descuente más de lo disponible
            cantidad_a_consumir = min(lote.cantidad, cantidad_restante)
            
            # Solo procesar si hay algo que consumir
            if cantidad_a_consumir <= 0:
                continue
            
            # Crear detalle de nota de salida para este lote
            DetalleNotaSalida.objects.create(
                id_salida=nota_salida.id_salida,
                id_lote=lote.id_lote,
                nombre_materia_prima=nombre_materia,
                cantidad=cantidad_a_consumir,
                unidad_medida=unidad
            )
            
            # 🔹 Descontar de la tabla LOTES
            lote.cantidad -= cantidad_a_consumir
            if lote.cantidad < 0:
                lote.cantidad = 0
            lote.save()
            
            # 🔹 Descontar del INVENTARIO total
            inventario_item.cantidad_actual -= cantidad_a_consumir
            if inventario_item.cantidad_actual < 0:
                inventario_item.cantidad_actual = 0
            inventario_item.save()
            
            # Registrar lote consumido
            lotes_consumidos.append({
                'id_lote': lote.id_lote,
                'codigo_lote': lote.codigo_lote,
                'cantidad': float(cantidad_a_consumir)
            })
            
            cantidad_restante -= cantidad_a_consumir
        
        # 5️⃣ Registrar trazabilidad automática (una por materia prima)
        # Crear descripción detallada
        lotes_detalle = ', '.join([f"Lote {lc['codigo_lote']}: {lc['cantidad']} {unidad}" for lc in lotes_consumidos])
        descripcion_detallada = (
            f"Se consumió {cantidad_requerida} {unidad} de {nombre_materia} para la producción de "
            f"{data['cantidad_total']} unidades de {data['producto_modelo']} ({data['color']}/{data['talla']}). "
            f"Material extraído de {len(lotes_consumidos)} lote(s): {lotes_detalle}. "
            f"Responsable: {nombre_solicitante}."
        )
        
        # Obtener hora actual del sistema
        hora_actual = datetime.now().time()
        
        Trazabilidad.objects.create(
            proceso=f'Consumo de Materia Prima - {nombre_materia}',
            descripcion_proceso=descripcion_detallada,
            fecha_registro=datetime.now(),
            hora_inicio=hora_actual,
            hora_fin=hora_actual,
            cantidad=int(cantidad_requerida),
            estado='Completado',
            id_personal=data['id_personal'],
            id_orden=orden.id_orden
        )
        
        # Registrar en la lista de materias usadas para la respuesta
        materias_usadas.append({
            'nombre': nombre_materia,
            'cantidad_total': float(cantidad_requerida),
            'lotes_consumidos': lotes_consumidos
        })
    
    return Response({
        'mensaje': 'Orden de producción creada exitosamente',
        'id_orden': orden.id_orden,
        'cod_orden': orden.cod_orden,
        'id_nota_salida': nota_salida.id_salida,
        'solicitante': nombre_solicitante,
        'area': area_solicitante,
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

    # Enriquecer con información del personal
    trazas_data = []
    for traza in trazas:
        traza_dict = {
            'id_trazabilidad': traza.id_trazabilidad,
            'proceso': traza.proceso,
            'descripcion_proceso': traza.descripcion_proceso,
            'fecha_registro': traza.fecha_registro,
            'hora_inicio': traza.hora_inicio,
            'hora_fin': traza.hora_fin,
            'cantidad': traza.cantidad,
            'estado': traza.estado,
            'id_personal': traza.id_personal,
            'id_orden': traza.id_orden
        }
        
        # Obtener nombre del personal
        try:
            persona = personal.objects.get(id=traza.id_personal)
            traza_dict['nombre_personal'] = persona.nombre_completo
            traza_dict['rol_personal'] = persona.rol
        except personal.DoesNotExist:
            traza_dict['nombre_personal'] = 'N/A'
            traza_dict['rol_personal'] = 'N/A'
        
        trazas_data.append(traza_dict)
    
    return Response({
        'orden': orden.cod_orden,
        'total_trazabilidades': trazas.count(),
        'trazabilidades': trazas_data
    }, status=status.HTTP_200_OK)