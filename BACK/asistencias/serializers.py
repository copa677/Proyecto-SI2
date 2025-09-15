from rest_framework import serializers

class AsistenciasSerializer(serializers.Serializer):
    nombre = serializers.CharField(max_length=100)
    fecha = serializers.DateField()
    hora_marcada = serializers.TimeField()
    turno = serializers.CharField(max_length=20)
    estado = serializers.CharField(max_length=20)