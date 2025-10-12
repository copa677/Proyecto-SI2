from rest_framework import serializers

class InventarioSerializer(serializers.Serializer):
    id_inventario = serializers.IntegerField()
    nombre_materia_prima = serializers.CharField(max_length=255)
    cantidad_actual = serializers.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = serializers.CharField(max_length=50)
    ubicacion = serializers.CharField(max_length=255)
    estado = serializers.CharField(max_length=50)
    fecha_actualizacion = serializers.DateTimeField()
    id_lote = serializers.IntegerField()

class RegistrarInventarioSerializer(serializers.Serializer):
    unidad_medida = serializers.CharField(max_length=50)
    ubicacion = serializers.CharField(max_length=255)
    estado = serializers.CharField(max_length=50)
    fecha_actualizacion = serializers.DateTimeField()
    cod_lote = serializers.CharField()