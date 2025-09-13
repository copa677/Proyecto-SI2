from django.db import models

# Create your models here.
class personal(models.Model):
    id_control = models.AutoField(primary_key=True)
    fecha = models.DateField()
    hora_marcada = models.TimeField()
    estado = models.CharField(max_length=20)
    id_personal = models.IntegerField()
    
    class Meta:
        db_table = 'asistencias'  #  Este es el nombre real de tu tabla en la base de datos
        managed = False       #  Esto evita que Django intente crear/modificar la tabla