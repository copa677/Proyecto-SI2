from rest_framework import serializers

class ControlCalidadSerializer(serializers.Serializer):
    id_control = serializers.IntegerField()
    observaciones = serializers.CharField()
    resultado = serializers.CharField(max_length=100)
    fehca_hora = serializers.DateTimeField()
    id_personal = serializers.IntegerField()
    id_trazabilidad = serializers.IntegerField()

class InsertarControlCalidadSerializer(serializers.Serializer):
    id_control = serializers.IntegerField()
    observaciones = serializers.CharField()
    resultado = serializers.CharField(max_length=100)
    fehca_hora = serializers.DateTimeField()
    nombre_personal = serializers.CharField()
    id_trazabilidad = serializers.IntegerField()