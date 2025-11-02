from rest_framework import serializers

class TrazabilidadSerializer(serializers.Serializer):
    id_trazabilidad = serializers.IntegerField()
    proceso = serializers.CharField(max_length=255)
    descripcion_proceso = serializers.CharField()
    fecha_registro = serializers.DateField()
    hora_inicio = serializers.TimeField()
    hora_fin = serializers.TimeField()
    cantidad = serializers.IntegerField()
    estado = serializers.CharField(max_length=50)
    id_personal = serializers.IntegerField()
    id_orden = serializers.IntegerField()

class InsertarTrazabilidadSerializer(serializers.Serializer):
    id_trazabilidad = serializers.IntegerField()
    proceso = serializers.CharField(max_length=255)
    descripcion_proceso = serializers.CharField()
    fecha_registro = serializers.DateField()
    hora_inicio = serializers.TimeField()
    hora_fin = serializers.TimeField()
    cantidad = serializers.IntegerField()
    estado = serializers.CharField(max_length=50)
    nombre_personal = serializers.CharField()
    id_orden = serializers.IntegerField()


class TrazabilidadLoteSerializer(serializers.Serializer):
    """Serializer para listar trazabilidad de lotes"""
    id_trazabilidad_lote = serializers.IntegerField()
    id_lote = serializers.IntegerField()
    id_materia = serializers.IntegerField()
    nombre_materia = serializers.CharField()
    codigo_lote = serializers.CharField()
    cantidad_consumida = serializers.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = serializers.CharField()
    tipo_operacion = serializers.CharField()
    id_operacion = serializers.IntegerField()
    codigo_operacion = serializers.CharField()
    fecha_consumo = serializers.DateTimeField()
    id_usuario = serializers.IntegerField(allow_null=True)
    nombre_usuario = serializers.CharField(allow_null=True)