from django.db import models
# Create your models here.

class personal(models.Model):
    id = models.AutoField(primary_key=True)
    nombre_completo = models.CharField(max_length=100, unique=True)
    direccion = models.CharField(max_length=255)
    telefono = models.CharField(max_length=15)
    rol = models.CharField(max_length=100)
    fecha_nacimiento = models.DateField()
    id_usuario = models.IntegerField()
    estado = models.CharField(max_length=20)


    class Meta:
        db_table = 'personal'  
        managed = False 