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

# 🔹 Serializer para materias primas en la orden
class MateriaPrimaOrdenSerializer(serializers.Serializer):
    id_inventario = serializers.IntegerField()
    cantidad = serializers.DecimalField(max_digits=10, decimal_places=2)

# 🔹 Serializer para crear orden con materias primas y generar nota de salida automáticamente
class CrearOrdenConMateriasSerializer(serializers.Serializer):
    cod_orden = serializers.CharField(max_length=100)
    fecha_inicio = serializers.DateField()
    fecha_fin = serializers.DateField()
    fecha_entrega = serializers.DateField()
    producto_modelo = serializers.CharField(max_length=255)
    color = serializers.CharField(max_length=100)
    talla = serializers.CharField(max_length=50)
    cantidad_total = serializers.IntegerField()
    id_personal = serializers.IntegerField()
    materias_primas = MateriaPrimaOrdenSerializer(many=True)  # Lista de materias a consumir