from django.db import models

class ModeloPrediccion(models.Model):
    id_modelo = models.AutoField(primary_key=True)
    nombre_modelo = models.CharField(max_length=255)
    tipo_modelo = models.CharField(max_length=100)  # 'regresion', 'series_tiempo', 'clasificacion'
    precision = models.DecimalField(max_digits=5, decimal_places=2, null=True, blank=True)
    fecha_entrenamiento = models.DateTimeField(auto_now_add=True)
    parametros = models.JSONField()  # Para guardar hiperparámetros
    activo = models.BooleanField(default=True)
    
    class Meta:
        db_table = 'modelos_prediccion'
        managed = False

class PrediccionPedido(models.Model):
    id_prediccion = models.AutoField(primary_key=True)
    id_modelo = models.IntegerField()
    fecha_prediccion = models.DateField()
    cantidad_predicha = models.IntegerField()
    monto_predicho = models.DecimalField(max_digits=10, decimal_places=2)
    intervalo_confianza = models.DecimalField(max_digits=5, decimal_places=2)  # 95%, 90%, etc.
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        db_table = 'predicciones_pedidos'
        managed = False