from django.db import models

# Create your models here.
class turnos(models.Model):
    id_turnos = models.AutoField(primary_key=True)
    descripcion = models.CharField(max_length=200)
    dia = models.CharField(max_length=20)
    hora_entrada = models.TimeField()
    hora_salida = models.TimeField()
    estado = models.CharField(max_length=20)
    id_personal = models.IntegerField()

    class Meta:
        db_table = 'turnos'  #  Este es el nombre real de tu tabla en la base de datos
        managed = False       #  Esto evita que Django intente crear/modificar la tabla