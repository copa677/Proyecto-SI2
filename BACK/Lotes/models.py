from django.db import models

# Create your models here.
class MateriaPrima(models.Model):
    id_materia = models.AutoField(primary_key=True)
    nombre = models.CharField(max_length=255)
    tipo_material = models.CharField(max_length=100)

    class Meta:
        db_table = 'materias_primas'
        managed = False


class Lote(models.Model):
    id_lote = models.AutoField(primary_key=True)
    codigo_lote = models.CharField(max_length=100, unique=True)
    fecha_recepcion = models.DateField()
    cantidad = models.DecimalField(max_digits=10,decimal_places=2)
    estado = models.CharField(max_length=50)
    id_materia = models.IntegerField()

    class Meta:
        db_table = 'lotes'
        managed = False

