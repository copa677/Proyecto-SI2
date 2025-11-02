from django.db import models

# Create your models here.
class ControlCalidad(models.Model):
    id_control = models.AutoField(primary_key=True)
    observaciones = models.TextField()
    resultado = models.CharField(max_length=100)
    fecha_hora = models.DateTimeField()
    id_personal = models.IntegerField()
    id_trazabilidad = models.IntegerField()

    class Meta:
        db_table = 'control_calidad'
        managed = False