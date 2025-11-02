# serializers.py
from rest_framework import serializers

class ClientesSerializer(serializers.Serializer):
    id = serializers.IntegerField()  # <-- añade esto
    nombre_completo = serializers.CharField()
    direccion = serializers.CharField()
    telefono = serializers.CharField()
    fecha_nacimiento = serializers.CharField()
    estado = serializers.CharField()
    id_usuario = serializers.IntegerField()
