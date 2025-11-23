from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db import transaction, connection
from django.utils import timezone
from datetime import date
import uuid
from .models import Pedido, DetallePedido
from .serializers import PedidoSerializer, PedidoUpdateSerializer, DetallePedidoSerializer, DetallePedidoReadSerializer
from Precios.models import Precios  # Importamos el modelo de precios

# ========== CRUD PEDIDOS ==========

@api_view(['POST'])
@transaction.atomic
def crear_pedido(request):
    """
    Crear un nuevo pedido
    """
    try:
        data = request.data.copy()
        # Generar código de pedido automático
        data['cod_pedido'] = f"PED-{uuid.uuid4().hex[:8].upper()}"

        # Establecer valores por defecto solo si no vienen en la petición
        if 'total' not in data or data['total'] is None:
            data['total'] = 0
        if 'fecha_creacion' not in data or data['fecha_creacion'] is None:
            data['fecha_creacion'] = date.today()
        if 'estado' not in data or data['estado'] is None:
            data['estado'] = 'pendiente'  # Estado inicial

        serializer = PedidoSerializer(data=data)
        if serializer.is_valid():
            pedido = serializer.save()
            return Response(PedidoSerializer(pedido).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def listar_pedidos_todos(request):
    """
    Listar todos los pedidos
    """
    try:
        pedidos = Pedido.objects.all().order_by('-fecha_creacion')
        serializer = PedidoSerializer(pedidos, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def obtener_pedido(request, id_pedido):
    """
    Obtener un pedido específico por ID
    """
    try:
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        serializer = PedidoSerializer(pedido)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Pedido.DoesNotExist:
        return Response({'error': 'Pedido no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@transaction.atomic
def actualizar_pedido(request, id_pedido):
    """
    Actualizar un pedido existente
    Valida que el pedido no tenga factura pagada antes de permitir modificaciones
    """
    try:
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        
        # Verificar si el pedido puede modificarse
        if not pedido.puede_modificarse():
            return Response({
                'error': 'No se puede modificar un pedido que ya tiene una factura pagada o está cancelado/entregado'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        serializer = PedidoUpdateSerializer(pedido, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
    except Pedido.DoesNotExist:
        return Response({'error': 'Pedido no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@transaction.atomic
def actualizar_estado_pedido(request, id_pedido):
    """
    Actualizar el estado de un pedido existente
    Incluye validación de transiciones de estado
    """
    try:
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        estado = request.data.get('estado')

        estados_validos = ['cotizacion', 'confirmado', 'en_produccion', 'completado', 'entregado', 'cancelado']
        if estado not in estados_validos:
            return Response({
                'error': f'Estado no válido. Estados permitidos: {", ".join(estados_validos)}'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar transiciones de estado
        if pedido.estado == 'cancelado' and estado != 'cancelado':
            return Response({
                'error': 'No se puede cambiar el estado de un pedido cancelado'
            }, status=status.HTTP_400_BAD_REQUEST)
        
        if pedido.estado == 'entregado' and estado != 'entregado':
            return Response({
                'error': 'No se puede cambiar el estado de un pedido entregado'
            }, status=status.HTTP_400_BAD_REQUEST)

        # Validar que si tiene factura pagada, solo pueda avanzar en el flujo
        if pedido.tiene_factura_pagada() and estado in ['cotizacion', 'cancelado']:
            return Response({
                'error': 'No se puede retroceder o cancelar un pedido con factura pagada'
            }, status=status.HTTP_400_BAD_REQUEST)

        pedido.estado = estado
        pedido.save()
        
        return Response({
            'message': 'Estado actualizado correctamente',
            'pedido': PedidoSerializer(pedido).data
        }, status=status.HTTP_200_OK)

    except Pedido.DoesNotExist:
        return Response({'error': 'Pedido no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ========== CRUD DETALLE PEDIDO ==========

@api_view(['POST'])
@transaction.atomic
def crear_detalle_pedido(request):
    """
    Crear un nuevo detalle de pedido
    """
    try:
        data = request.data.copy()
        
        # Verificar que el precio unitario tenga un valor
        if 'precio_unitario' not in data or not data['precio_unitario']:
            return Response({'error': 'El precio unitario es requerido.'}, status=status.HTTP_400_BAD_REQUEST)
        
        # Convertir precio_unitario a float para validación
        try:
            precio_unitario = float(data['precio_unitario'])
            if precio_unitario <= 0:
                return Response({'error': 'El precio unitario debe ser mayor a 0.'}, status=status.HTTP_400_BAD_REQUEST)
        except (ValueError, TypeError):
            return Response({'error': 'El precio unitario debe ser un número válido.'}, status=status.HTTP_400_BAD_REQUEST)

        # El subtotal se calcula automáticamente en la BD (columna generada)
        # Validar datos con el serializer
        serializer = DetallePedidoSerializer(data=data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Insertar usando SQL raw para evitar que Django intente insertar subtotal
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO detalle_pedido 
                (id_pedido, tipo_prenda, cuello, manga, color, talla, material, cantidad, precio_unitario)
                VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                RETURNING id_detalle
            """, [
                data['id_pedido'],
                data['tipo_prenda'],
                data['cuello'],
                data['manga'],
                data['color'],
                data['talla'],
                data['material'],
                data['cantidad'],
                precio_unitario
            ])
            id_detalle = cursor.fetchone()[0]
        
        # Obtener el detalle creado con el subtotal calculado
        detalle = DetallePedido.objects.get(id_detalle=id_detalle)
        
        # Actualizar total del pedido
        actualizar_total_pedido(data['id_pedido'])
        
        # Devolver el detalle con subtotal calculado
        return Response(DetallePedidoReadSerializer(detalle).data, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def listar_detalles_pedido(request, id_pedido):
    """
    Listar todos los detalles de un pedido
    """
    try:
        detalles = DetallePedido.objects.filter(id_pedido=id_pedido)
        serializer = DetallePedidoReadSerializer(detalles, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def obtener_detalle_pedido(request, id_detalle):
    """
    Obtener un detalle específico por ID
    """
    try:
        detalle = DetallePedido.objects.get(id_detalle=id_detalle)
        serializer = DetallePedidoReadSerializer(detalle)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except DetallePedido.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PUT'])
@transaction.atomic
def actualizar_detalle_pedido(request, id_detalle):
    """
    Actualizar un detalle de pedido existente
    """
    try:
        detalle = DetallePedido.objects.get(id_detalle=id_detalle)
        data = request.data.copy()
        
        # Verificar que el precio unitario tenga un valor válido si viene en el payload
        if 'precio_unitario' in data:
            try:
                precio_unitario = float(data['precio_unitario'])
                if precio_unitario <= 0:
                    return Response({'error': 'El precio unitario debe ser mayor a 0.'}, status=status.HTTP_400_BAD_REQUEST)
            except (ValueError, TypeError):
                return Response({'error': 'El precio unitario debe ser un número válido.'}, status=status.HTTP_400_BAD_REQUEST)

        # El subtotal se calcula automáticamente en la BD (columna generada)
        # Validar datos con el serializer
        serializer = DetallePedidoSerializer(detalle, data=data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        # Construir la consulta UPDATE solo con los campos que se envían
        campos_actualizar = []
        valores = []
        
        for campo in ['tipo_prenda', 'cuello', 'manga', 'color', 'talla', 'material', 'cantidad', 'precio_unitario']:
            if campo in data:
                campos_actualizar.append(f"{campo} = %s")
                if campo == 'precio_unitario':
                    valores.append(precio_unitario)
                else:
                    valores.append(data[campo])
        
        if campos_actualizar:
            valores.append(id_detalle)
            with connection.cursor() as cursor:
                query = f"UPDATE detalle_pedido SET {', '.join(campos_actualizar)} WHERE id_detalle = %s"
                cursor.execute(query, valores)
        
        # Obtener el detalle actualizado con el subtotal recalculado
        detalle_actualizado = DetallePedido.objects.get(id_detalle=id_detalle)
        
        # Actualizar total del pedido
        actualizar_total_pedido(detalle_actualizado.id_pedido)
        
        # Devolver el detalle con subtotal calculado
        return Response(DetallePedidoReadSerializer(detalle_actualizado).data, status=status.HTTP_200_OK)
        
    except DetallePedido.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
@transaction.atomic
def eliminar_detalle_pedido(request, id_detalle):
    """
    Eliminación física de detalle de pedido
    """
    try:
        detalle = DetallePedido.objects.get(id_detalle=id_detalle)
        id_pedido = detalle.id_pedido
        detalle.delete()
        
        # Actualizar total del pedido
        actualizar_total_pedido(id_pedido)
        
        return Response(
            {'message': 'Detalle eliminado correctamente'}, 
            status=status.HTTP_200_OK
        )
        
    except DetallePedido.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

# ========== FUNCIONES AUXILIARES ==========

@transaction.atomic
def actualizar_total_pedido(id_pedido):
    """
    Actualizar el total de un pedido sumando todos sus detalles
    """
    try:
        detalles = DetallePedido.objects.filter(id_pedido=id_pedido)
        total = sum(detalle.subtotal for detalle in detalles)
        if total is None:
            total = 0
        
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        pedido.total = total
        pedido.save()
        
    except Exception as e:
        print(f"Error actualizando total del pedido: {e}")

# ========== ENDPOINTS ADICIONALES PARA INTEGRACIÓN CON FACTURAS ==========

@api_view(['GET'])
def obtener_pedido_con_detalles(request, id_pedido):
    """
    Obtener un pedido con todos sus detalles para facturación
    """
    try:
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        detalles = DetallePedido.objects.filter(id_pedido=id_pedido)
        
        pedido_data = PedidoSerializer(pedido).data
        pedido_data['detalles'] = DetallePedidoReadSerializer(detalles, many=True).data
        pedido_data['puede_facturarse'] = pedido.estado not in ['cancelado'] and not pedido.tiene_factura_pagada()
        pedido_data['tiene_factura_pagada'] = pedido.tiene_factura_pagada()
        
        return Response(pedido_data, status=status.HTTP_200_OK)
    except Pedido.DoesNotExist:
        return Response({'error': 'Pedido no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def verificar_estado_facturacion(request, id_pedido):
    """
    Verificar si un pedido puede ser facturado
    """
    try:
        pedido = Pedido.objects.get(id_pedido=id_pedido)
        
        puede_facturarse = True
        mensajes = []
        
        # Verificar si ya tiene factura pagada
        if pedido.tiene_factura_pagada():
            puede_facturarse = False
            mensajes.append('El pedido ya tiene una factura pagada')
        
        # Verificar estado del pedido
        if pedido.estado == 'cancelado':
            puede_facturarse = False
            mensajes.append('El pedido está cancelado')
        
        # Verificar que tenga items
        detalles_count = DetallePedido.objects.filter(id_pedido=id_pedido).count()
        if detalles_count == 0:
            puede_facturarse = False
            mensajes.append('El pedido no tiene productos')
        
        # Verificar que tenga monto total
        if pedido.total <= 0:
            puede_facturarse = False
            mensajes.append('El pedido no tiene monto total válido')
        
        return Response({
            'puede_facturarse': puede_facturarse,
            'mensajes': mensajes if not puede_facturarse else ['El pedido puede ser facturado'],
            'pedido': PedidoSerializer(pedido).data
        }, status=status.HTTP_200_OK)
        
    except Pedido.DoesNotExist:
        return Response({'error': 'Pedido no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def listar_pedidos_facturables(request):
    """
    Listar pedidos que pueden ser facturados (sin factura pagada, no cancelados)
    """
    try:
        from Facturas.models import Factura
        
        # Obtener IDs de pedidos con facturas pagadas
        pedidos_con_factura_pagada = Factura.objects.filter(
            estado_pago='completado'
        ).values_list('id_pedido', flat=True)
        
        # Filtrar pedidos facturables
        pedidos = Pedido.objects.exclude(
            id_pedido__in=pedidos_con_factura_pagada
        ).exclude(
            estado__in=['cancelado']
        ).filter(
            total__gt=0
        ).order_by('-fecha_creacion')
        
        serializer = PedidoSerializer(pedidos, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

