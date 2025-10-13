from django.db import models

# Create your models here.
class NotaSalida(models.Model):
    id_salida = models.AutoField(primary_key=True)
    fecha_salida = models.DateField()
    motivo = models.TextField()
    estado = models.CharField(max_length=50)
    id_personal =models.IntegerField()

    class Meta:
        db_table = 'nota_salida'
        managed = False


class DetalleNotaSalida(models.Model):
    id_detalle = models.AutoField(primary_key=True)
    id_salida = models.IntegerField()
    id_lote = models.IntegerField()
    nombre_materia_prima = models.CharField(max_length=255)
    cantidad = models.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = models.CharField(max_length=50)

    class Meta:
        db_table = 'detalle_nota_salida'
        managed = False