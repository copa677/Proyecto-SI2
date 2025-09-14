from rest_framework import serializers

class TurnosSerializer(serializers.Serializer):
    turno = serializers.CharField(max_length=10)
    hora_entrada = serializers.TimeField()
    hora_salida = serializers.TimeField()
    estado = serializers.CharField(max_length=20, default='activo')