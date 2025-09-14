from django.db import models

# Create your models here.
class turnos(models.Model):
    id = models.AutoField(primary_key=True)
    turno = models.CharField(max_length=10)
    hora_entrada = models.TimeField()
    hora_salida = models.TimeField()
    estado = models.CharField(max_length=20)

    class Meta:
        db_table = 'turnos'  #  Este es el nombre real de tu tabla en la base de datos
        managed = False       #  Esto evita que Django intente crear/modificar la tabla