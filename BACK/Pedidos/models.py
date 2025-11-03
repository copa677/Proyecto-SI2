from django.db import models

# Create your models here.
class Pedido(models.Model):
    id_pedido = models.AutoField(primary_key=True)
    cod_pedido = models.CharField(max_length=100, unique=True)
    fecha_pedido = models.DateTimeField(auto_now_add=True)
    fecha_entrega_prometida = models.DateField()
    estado = models.CharField(max_length=50)
    id_cliente = models.IntegerField()
    total = models.DecimalField(max_digits=10, decimal_places=2)
    observaciones = models.TextField(blank=True)
    fecha_creacion = models.DateField()
    
    class Meta:
        db_table = 'pedidos'
        manadged = False

class DetallePedido(models.Model):
    id_detalle = models.AutoField(primary_key=True)
    id_pedido = models.IntegerField()
    # Estos campos alimentarán la OrdenProducción
    tipo_prenda = models.CharField(max_length=50)  # 'polera', 'camisa'
    cuello = models.CharField(max_length=20)
    manga = models.CharField(max_length=20)
    color = models.CharField(max_length=100)
    talla = models.CharField(max_length=50)
    cantidad = models.IntegerField()
    precio_unitario = models.DecimalField(max_digits=10, decimal_places=2)
    subtotal = models.DecimalField(max_digits=10, decimal_places=2)
    
    class Meta:
        db_table = 'detalle_pedido'
        managed = False