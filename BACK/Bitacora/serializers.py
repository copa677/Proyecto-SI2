from rest_framework import serializers

class RegistroBitacora (serializers.Serializer):
    username = serializers.CharField()
    ip = serializers.CharField()
    fecha_hora = serializers.DateTimeField()
    accion = serializers.CharField()
    descripcion = serializers.CharField()

class serializerBitacora (serializers.Serializer):
    id_bitacora = serializers.CharField()
    username = serializers.CharField()
    ip = serializers.CharField(max_length=45)
    fecha_hora = serializers.DateTimeField()
    accion = serializers.CharField()
    descripcion = serializers.CharField()