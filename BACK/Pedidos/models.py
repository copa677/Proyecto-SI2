from django.db import models

# Create your models here.
class Pedido(models.Model):
    ESTADOS_PEDIDO = [
        ('cotizacion', 'Cotización'),
        ('confirmado', 'Confirmado'),
        ('en_produccion', 'En Producción'),
        ('completado', 'Completado'),
        ('entregado', 'Entregado'),
        ('cancelado', 'Cancelado'),
    ]
    
    id_pedido = models.AutoField(primary_key=True)
    cod_pedido = models.CharField(max_length=100, unique=True)
    fecha_pedido = models.DateTimeField(auto_now_add=True)
    fecha_entrega_prometida = models.DateField()
    estado = models.CharField(max_length=50, choices=ESTADOS_PEDIDO, default='cotizacion')
    id_cliente = models.IntegerField()
    total = models.DecimalField(max_digits=10, decimal_places=2, default=0)
    observaciones = models.TextField(blank=True)
    fecha_creacion = models.DateField()
    
    class Meta:
        db_table = 'pedidos'
        managed = False
    
    def __str__(self):
        return f"Pedido {self.cod_pedido} - {self.estado}"
    
    def tiene_factura_pagada(self):
        """Verifica si el pedido tiene una factura con estado completado"""
        from Facturas.models import Factura
        return Factura.objects.filter(id_pedido=self.id_pedido, estado_pago='completado').exists()
    
    def puede_modificarse(self):
        """Verifica si el pedido puede modificarse (no tiene factura pagada)"""
        return not self.tiene_factura_pagada() and self.estado not in ['cancelado', 'entregado']

class DetallePedido(models.Model):
    TIPOS_PRENDA = [
        ('polera', 'Polera'),
        ('camisa', 'Camisa'),
    ]
    
    id_detalle = models.AutoField(primary_key=True)
    id_pedido = models.IntegerField()
    tipo_prenda = models.CharField(max_length=50, choices=TIPOS_PRENDA)
    cuello = models.CharField(max_length=20)
    manga = models.CharField(max_length=20)
    color = models.CharField(max_length=100)
    talla = models.CharField(max_length=50)
    material = models.CharField(max_length=255)
    cantidad = models.IntegerField()
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2, editable=False)
    
    class Meta:
        db_table = 'detalle_pedido'
        managed = False
    
    def __str__(self):
        return f"{self.tipo_prenda} - {self.color} x{self.cantidad}"