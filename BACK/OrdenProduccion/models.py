from django.db import models

# Create your models here.
class OrdenProduccion(models.Model):
    id_orden = models.AutoField(primary_key=True)
    cod_orden = models.CharField(max_length=100,unique=True)
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField()
    fecha_entrega = models.DateField()
    estado = models.CharField(max_length=50)
    producto_modelo = models.CharField(max_length=255)
    color = models.CharField(max_length=100)
    talla = models.CharField(max_length=50)
    cantidad_total = models.IntegerField()
    id_personal = models.IntegerField()

    class Meta:
        db_table = 'orden_produccion'
        managed = False