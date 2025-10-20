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