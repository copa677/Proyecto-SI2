from django.db import models
class Inventario(models.Model):
    id_inventario = models.AutoField(primary_key=True)
    nombre_materia_prima = models.CharField(max_length=255)
    cantidad_actual = models.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = models.CharField(max_length=50)
    ubicacion = models.CharField(max_length=255)
    estado = models.CharField(max_length=50)
    fecha_actualizacion = models.DateTimeField()
    id_lote = models.IntegerField()
    stock_minimo = models.DecimalField(max_digits=10, decimal_places=2, default=0)  # <-- Agrega esta línea

    class Meta:
        db_table = 'inventario'
        managed = False