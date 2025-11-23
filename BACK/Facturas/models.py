from django.db import models
import uuid

class Factura(models.Model):
    ESTADOS_PAGO = [
        ('pendiente', 'Pendiente'),
        ('completado', 'Completado'),
        ('fallido', 'Fallido'),
        ('reembolsado', 'Reembolsado'),
    ]

    id_factura = models.AutoField(primary_key=True)
    id_pedido = models.IntegerField()
    cod_factura = models.CharField(max_length=100, unique=True, default=lambda: f"FAC-{uuid.uuid4().hex[:8].upper()}")
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    monto_total = models.DecimalField(max_digits=10, decimal_places=2)
    
    # Campos Stripe
    stripe_payment_intent_id = models.CharField(max_length=255, blank=True, null=True)
    stripe_checkout_session_id = models.CharField(max_length=255, blank=True, null=True)
    estado_pago = models.CharField(max_length=20, choices=ESTADOS_PAGO, default='pendiente')
    metodo_pago = models.CharField(max_length=50, blank=True, null=True)
    fecha_pago = models.DateTimeField(blank=True, null=True)
    
    # Datos del pago
    codigo_autorizacion = models.CharField(max_length=100, blank=True, null=True)
    ultimos_digitos_tarjeta = models.CharField(max_length=4, blank=True, null=True)
    tipo_tarjeta = models.CharField(max_length=50, blank=True, null=True)
    
    class Meta:
        db_table = 'facturas'
        managed = False