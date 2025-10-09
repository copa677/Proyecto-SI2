from rest_framework import serializers

class OrdenProduccionSerializers(serializers.Serializer):
    id_orden = serializers.IntegerField()
    cod_orden = serializers.CharField(max_length=100)
    fecha_inicio = serializers.DateField()
    fecha_fin = serializers.DateField()
    fecha_entrega = serializers.DateField()
    estado = serializers.CharField(max_length=50)
    producto_modelo = serializers.CharField(max_length=255)
    color = serializers.CharField(max_length=100)
    talla = serializers.CharField(max_length=50)
    cantidad_total = serializers.IntegerField()
    id_personal = serializers.IntegerField()

class InsertarOrdenProduccionSerializers(serializers.Serializer):
    cod_orden = serializers.CharField(max_length=100)
    fecha_inicio = serializers.DateField()
    fecha_fin = serializers.DateField()
    fecha_entrega = serializers.DateField()
    estado = serializers.CharField(max_length=50)
    producto_modelo = serializers.CharField(max_length=255)
    color = serializers.CharField(max_length=100)
    talla = serializers.CharField(max_length=50)
    cantidad_total = serializers.IntegerField()
    id_personal = serializers.IntegerField()