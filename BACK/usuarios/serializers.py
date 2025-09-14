from rest_framework import serializers

class LoginSerializer(serializers.Serializer):
    name_user = serializers.CharField()
    password = serializers.CharField()

class RegisterSerializer(serializers.Serializer):
    name_user = serializers.CharField()
    password = serializers.CharField(write_only=True)
    email = serializers.EmailField()
    tipo_usuario = serializers.CharField()
    estado = serializers.CharField()

class UsuarioListSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    name_user = serializers.CharField()
    email = serializers.EmailField()
    tipo_usuario = serializers.CharField()
    estado = serializers.CharField()