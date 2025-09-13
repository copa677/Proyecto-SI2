from rest_framework import serializers

class AsistenciasSerializer(serializers.Serializer):
    fecha = serializers.DateField()
    hora_marcada = serializers.TimeField()
    id_personal = serializers.IntegerField()