from rest_framework import serializers

class TurnosSerializer(serializers.Serializer):
    descripcion = serializers.CharField(max_length=200)
    dia = serializers.CharField(max_length=20)
    hora_entrada = serializers.TimeField()
    hora_salida = serializers.TimeField()
    estado = serializers.CharField(max_length=20, default='activo')
    id_personal = serializers.IntegerField()