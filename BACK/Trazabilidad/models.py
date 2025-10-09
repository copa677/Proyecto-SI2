from django.db import models

# Create your models here.
class Trazabilidad(models.Model):
    id_trazabilidad = models.AutoField(primary_key=True)
    proceso = models.CharField(max_length=255)
    descripcion_proceso = models.TextField()
    fecha_registro = models.DateTimeField()
    hora_inicio = models.TimeField()
    hora_fin = models.TimeField()
    cantidad = models.IntegerField()
    estado = models.CharField(max_length=50)
    id_personal = models.IntegerField()
    id_orden = models.IntegerField()

    class Meta:
        db_table = 'trazabilidad'
        managed = False