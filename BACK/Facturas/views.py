import stripe
from django.conf import settings
from django.shortcuts import get_object_or_404
from django.utils import timezone
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import Factura
from .serializers import FacturaSerializer
from Pedidos.models import Pedido, DetallePedido

# Configurar Stripe
stripe.api_key = settings.STRIPE_SECRET_KEY

@api_view(['POST'])
def crear_sesion_pago(request, id_pedido):
    """
    Crea una sesión de Stripe Checkout para una factura existente o crea una nueva si no existe
    """
    try:
        # 1. Verificar pedido
        pedido = get_object_or_404(Pedido, id_pedido=id_pedido)
        
        # 2. Verificar que no exista factura pagada para este pedido
        factura_pagada = Factura.objects.filter(
            id_pedido=id_pedido, 
            estado_pago__in=['completado', 'pagada']
        ).first()
        
        if factura_pagada:
            return Response(
                {'error': 'Este pedido ya tiene un pago completado'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 3. Buscar factura pendiente existente o crear una nueva
        factura = Factura.objects.filter(
            id_pedido=id_pedido,
            estado_pago__in=['pendiente', 'fallido']
        ).first()
        
        if not factura:
            # Solo crear factura si no existe una pendiente
            factura = Factura.objects.create(
                id_pedido=id_pedido,
                monto_total=pedido.total
            )
        else:
            # Actualizar el monto por si cambió
            factura.monto_total = pedido.total
            factura.save()
        
        # 4. Obtener detalles del pedido para productos dinámicos
        detalles = DetallePedido.objects.filter(id_pedido=id_pedido)
        line_items = []
        
        for detalle in detalles:
            line_items.append({
                'price_data': {
                    'currency': 'bob',  # Cambiar a 'pen' para soles
                    'product_data': {
                        'name': f"{detalle.tipo_prenda.capitalize()} - {detalle.color}",
                        'description': f"Talla: {detalle.talla}, Material: {detalle.material}",
                    },
                    'unit_amount': int(detalle.precio_unitario * 100),  # Stripe usa centavos
                },
                'quantity': detalle.cantidad,
            })
        
        # 5. Si no hay detalles, crear item genérico
        if not line_items:
            line_items.append({
                'price_data': {
                    'currency': 'bob',
                    'product_data': {
                        'name': f"Pedido #{pedido.cod_pedido}",
                        'description': pedido.observaciones or "Pedido personalizado",
                    },
                    'unit_amount': int(pedido.total * 100),
                },
                'quantity': 1,
            })
        
        # 6. Crear sesión de Stripe Checkout
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=line_items,
            mode='payment',
            success_url=request.build_absolute_uri(
                f'/api/facturas/pago/exito/?session_id={{CHECKOUT_SESSION_ID}}&factura_id={factura.id_factura}'
            ),
            cancel_url=request.build_absolute_uri(
                f'/api/facturas/pago/cancelado/?factura_id={factura.id_factura}'
            ),
            customer_email=obtener_email_cliente(pedido.id_cliente),
            metadata={
                'factura_id': str(factura.id_factura),
                'pedido_id': str(id_pedido),
                'cod_pedido': pedido.cod_pedido
            }
        )
        
        # 7. Actualizar factura con ID de sesión
        factura.stripe_checkout_session_id = checkout_session.id
        factura.save()
        
        return Response({
            'checkout_url': checkout_session.url,
            'session_id': checkout_session.id,
            'factura_id': factura.id_factura,
            'cod_factura': factura.cod_factura,
            'monto_total': float(factura.monto_total)
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def pago_exitoso(request):
    """
    Callback para pagos exitosos
    """
    try:
        session_id = request.GET.get('session_id')
        factura_id = request.GET.get('factura_id')
        
        # Verificar sesión en Stripe
        session = stripe.checkout.Session.retrieve(session_id)
        factura = get_object_or_404(Factura, id_factura=factura_id)
        
        if session.payment_status == 'paid':
            # Actualizar factura
            factura.estado_pago = 'completado'
            factura.stripe_payment_intent_id = session.payment_intent
            factura.fecha_pago = timezone.now()
            factura.metodo_pago = 'tarjeta'
            factura.save()
            
            # Actualizar pedido (opcional: cambiar estado)
            pedido = Pedido.objects.get(id_pedido=factura.id_pedido)
            # pedido.estado = 'confirmado'  # Si quieres cambiar estado
            
            return Response({
                'message': 'Pago completado exitosamente',
                'factura': FacturaSerializer(factura).data,
                'pedido': pedido.cod_pedido
            })
        else:
            return Response(
                {'error': 'El pago no se completó'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
            
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def pago_cancelado(request):
    """
    Callback para pagos cancelados
    """
    factura_id = request.GET.get('factura_id')
    factura = get_object_or_404(Factura, id_factura=factura_id)
    
    return Response({
        'message': 'Pago cancelado',
        'factura_id': factura_id,
        'cod_factura': factura.cod_factura
    })

#FUNCIONES AUXILIARES
def obtener_email_cliente(id_cliente):
    """
    Obtener email del cliente desde la base de datos
    """
    try:
        from Clientes.models import Cliente
        from usuarios.models import usurios
        
        cliente = Cliente.objects.get(id=id_cliente)
        usuario = usurios.objects.get(id=cliente.id_usuario)
        return usuario.email
    except Exception:
        return None  # Stripe funciona sin email

@api_view(['GET'])
def verificar_estado_pago(request, id_factura):
    """
    Verificar estado actual del pago
    """
    try:
        factura = get_object_or_404(Factura, id_factura=id_factura)
        
        if factura.stripe_checkout_session_id:
            session = stripe.checkout.Session.retrieve(factura.stripe_checkout_session_id)
            
            return Response({
                'factura': FacturaSerializer(factura).data,
                'stripe_status': session.payment_status,
                'checkout_url': session.url if session.payment_status == 'open' else None
            })
        else:
            return Response({
                'factura': FacturaSerializer(factura).data,
                'message': 'No se ha iniciado proceso de pago'
            })
            
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def webhook_stripe(request):
    """
    Webhook para eventos de Stripe (más seguro)
    """
    payload = request.body
    sig_header = request.META.get('HTTP_STRIPE_SIGNATURE', '')
    
    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, settings.STRIPE_WEBHOOK_SECRET
        )
    except ValueError:
        return Response({'error': 'Invalid payload'}, status=400)
    except stripe.error.SignatureVerificationError:
        return Response({'error': 'Invalid signature'}, status=400)
    
    # Manejar eventos
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        manejar_pago_exitoso_webhook(session)
    
    return Response({'success': True})

def manejar_pago_exitoso_webhook(session):
    """
    Manejar pago exitoso desde webhook
    """
    try:
        factura_id = session.metadata.get('factura_id')
        factura = Factura.objects.get(id_factura=factura_id)
        
        factura.estado_pago = 'completado'
        factura.stripe_payment_intent_id = session.payment_intent
        factura.fecha_pago = timezone.now()
        factura.metodo_pago = 'tarjeta'
        factura.save()
        
        # Lógica adicional: enviar email, actualizar inventario, etc.
        
    except Exception as e:
        print(f"Error en webhook: {e}")


@api_view(['GET'])
def listar_facturas(request):
    """
    Listar todas las facturas
    """
    facturas = Factura.objects.all().order_by('-fecha_creacion')
    serializer = FacturaSerializer(facturas, many=True)
    return Response(serializer.data)


@api_view(['GET'])
def obtener_factura(request, id_factura):
    """
    Obtener una factura específica
    """
    factura = get_object_or_404(Factura, id_factura=id_factura)
    serializer = FacturaSerializer(factura)
    return Response(serializer.data)


@api_view(['GET'])
def obtener_facturas_cliente(request):
    """
    Obtener facturas del cliente autenticado
    Usa el id_cliente del header o query params
    """
    from Clientes.models import Cliente
    from Pedidos.models import Pedido
    
    try:
        # Obtener id_cliente del query param o header
        id_cliente = request.GET.get('id_cliente')
        
        if not id_cliente:
            # Intentar obtener del header
            id_cliente = request.headers.get('X-Cliente-ID')
        
        if not id_cliente:
            # Intentar autenticación tradicional si existe
            user = request.user
            if user.is_authenticated and user.tipo_usuario.lower() == 'cliente':
                try:
                    cliente = Cliente.objects.get(id_usuario=user.id)
                    id_cliente = cliente.id
                except Cliente.DoesNotExist:
                    pass
        
        if not id_cliente:
            return Response(
                {'error': 'No se pudo identificar al cliente. Por favor, inicie sesión nuevamente.'}, 
                status=status.HTTP_401_UNAUTHORIZED
            )
        
        # Convertir a entero
        try:
            id_cliente = int(id_cliente)
        except (ValueError, TypeError):
            return Response(
                {'error': 'ID de cliente inválido'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar que el cliente existe
        try:
            cliente = Cliente.objects.get(id=id_cliente)
        except Cliente.DoesNotExist:
            return Response(
                {'error': 'Cliente no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Obtener todos los pedidos del cliente
        pedidos_cliente = Pedido.objects.filter(id_cliente=id_cliente).values_list('id_pedido', flat=True)
        
        # Obtener las facturas de esos pedidos
        facturas = Factura.objects.filter(id_pedido__in=pedidos_cliente).order_by('-fecha_creacion')
        serializer = FacturaSerializer(facturas, many=True)
        
        return Response(serializer.data)
        
    except Exception as e:
        return Response(
            {'error': f'Error al obtener facturas: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )


@api_view(['POST'])
def crear_factura_manual(request):
    """
    Crear factura manual para empleados (sin Stripe)
    Método de pago: efectivo, transferencia, tarjeta (sin procesamiento online)
    """
    try:
        # Validar datos recibidos
        id_pedido = request.data.get('id_pedido')
        metodo_pago = request.data.get('metodo_pago', 'efectivo')
        monto_total = request.data.get('monto_total')
        
        if not id_pedido:
            return Response(
                {'error': 'El ID del pedido es requerido'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Verificar que el pedido existe
        try:
            pedido = Pedido.objects.get(id_pedido=id_pedido)
        except Pedido.DoesNotExist:
            return Response(
                {'error': 'Pedido no encontrado'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        # Verificar que no exista factura pagada para este pedido
        factura_existente = Factura.objects.filter(
            id_pedido=id_pedido, 
            estado_pago__in=['completado', 'pagada']
        ).first()
        
        if factura_existente:
            return Response(
                {'error': 'Este pedido ya tiene una factura pagada'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Crear la factura
        factura = Factura.objects.create(
            id_pedido=id_pedido,
            monto_total=monto_total or pedido.total,
            metodo_pago=metodo_pago,
            estado_pago='completado',  # Se marca como completado inmediatamente
            fecha_pago=timezone.now()
        )
        
        # Serializar y retornar
        serializer = FacturaSerializer(factura)
        return Response(serializer.data, status=status.HTTP_201_CREATED)
        
    except Exception as e:
        return Response(
            {'error': f'Error al crear factura: {str(e)}'}, 
            status=status.HTTP_500_INTERNAL_SERVER_ERROR
        )