from rest_framework import serializers
from .models import Inventario

class InventarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Inventario
        fields = '__all__'


class RegistrarInventarioSerializer(serializers.Serializer):
    unidad_medida = serializers.CharField(max_length=50)
    ubicacion = serializers.CharField(max_length=255)
    estado = serializers.CharField(max_length=50)
    fecha_actualizacion = serializers.DateTimeField()
    cod_lote = serializers.CharField()