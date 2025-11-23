from django.db import models

# Create your models here.
class Precios(models.Model):
    id_precio = models.AutoField(primary_key=True)
    decripcion = models.CharField(max_length=255)
    material = models.CharField(max_length=255)
    talla = models.CharField(max_length=50)
    precio_base = models.DecimalField(max_digits=10, decimal_places=2)
    activo = models.BooleanField(default=True)

    class Meta:
        db_table = 'precios'
        managed = False