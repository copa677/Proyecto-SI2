from rest_framework import serializers
from personal.models import personal

class ControlCalidadSerializer(serializers.Serializer):
    id_control = serializers.IntegerField()
    observaciones = serializers.CharField()
    resultado = serializers.CharField(max_length=100)
    fecha_hora = serializers.DateTimeField()
    id_personal = serializers.IntegerField()
    id_trazabilidad = serializers.IntegerField()
    nombre_personal = serializers.SerializerMethodField()

    def get_nombre_personal(self, obj):
        try:
            p = personal.objects.get(id=obj.id_personal)
            return p.nombre_completo
        except personal.DoesNotExist:
            return None

class InsertarControlCalidadSerializer(serializers.Serializer):
    observaciones = serializers.CharField()
    resultado = serializers.CharField(max_length=100)
    fecha_hora = serializers.DateTimeField()
    id_personal = serializers.IntegerField()
    id_trazabilidad = serializers.IntegerField()