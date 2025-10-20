from rest_framework import serializers

class NotaSalidaSerializer(serializers.Serializer):
    id_salida = serializers.IntegerField()
    fecha_salida = serializers.DateField()
    motivo = serializers.CharField()
    estado = serializers.CharField(max_length=50)
    id_personal =serializers.IntegerField()

class RegistrarNotaSalidaSerializer(serializers.Serializer):
    fecha_salida = serializers.DateField()
    motivo = serializers.CharField()
    estado = serializers.CharField(max_length=50)

class DetalleNotaSalidaSerializer(serializers.Serializer):
    id_detalle = serializers.IntegerField()
    id_salida = serializers.IntegerField()
    id_lote = serializers.IntegerField()
    nombre_materia_prima = serializers.CharField(max_length=255)
    cantidad = serializers.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = serializers.CharField(max_length=50)

class RegistrarDetalleNotaSalidaSerializer(serializers.Serializer):
    id_salida = serializers.IntegerField()
    cod_lote = serializers.CharField()
    cantidad = serializers.DecimalField(max_digits=10, decimal_places=2)
    unidad_medida = serializers.CharField(max_length=50)

class DetalleNotaSalidaCreateSerializer(serializers.Serializer):
    id_inventario = serializers.IntegerField()
    cantidad = serializers.DecimalField(max_digits=10, decimal_places=2)

class NotaSalidaConDetallesSerializer(serializers.Serializer):
    fecha_salida = serializers.DateField()
    motivo = serializers.CharField()
    id_personal = serializers.IntegerField()
    area = serializers.CharField()
    detalles = DetalleNotaSalidaCreateSerializer(many=True)
