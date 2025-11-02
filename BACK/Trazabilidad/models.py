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


class TrazabilidadLote(models.Model):
    """
    Modelo para rastrear el consumo de lotes en operaciones (Órdenes de Producción, Notas de Salida, etc.)
    """
    id_trazabilidad_lote = models.AutoField(primary_key=True)
    id_lote = models.IntegerField()  # Lote del cual se consumió
    id_materia = models.IntegerField()  # Materia prima consumida
    nombre_materia = models.CharField(max_length=255)  # Nombre de la materia prima
    codigo_lote = models.CharField(max_length=100)  # Código del lote
    cantidad_consumida = models.DecimalField(max_digits=10, decimal_places=2)  # Cantidad consumida del lote
    unidad_medida = models.CharField(max_length=50)  # metros, kg, etc.
    tipo_operacion = models.CharField(max_length=50)  # 'orden_produccion', 'nota_salida'
    id_operacion = models.IntegerField()  # ID de la orden o nota de salida
    codigo_operacion = models.CharField(max_length=100)  # Código de la orden o nota
    fecha_consumo = models.DateTimeField()  # Fecha y hora del consumo
    id_usuario = models.IntegerField(null=True, blank=True)  # Usuario que realizó la operación
    nombre_usuario = models.CharField(max_length=255, null=True, blank=True)  # Nombre del usuario

    class Meta:
        db_table = 'trazabilidad_lote'
        managed = False