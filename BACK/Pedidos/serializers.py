from rest_framework import serializers
from .models import Pedido, DetallePedido

class PedidoSerializer(serializers.ModelSerializer):
    tiene_factura_pagada = serializers.SerializerMethodField()
    puede_modificarse = serializers.SerializerMethodField()
    estado_display = serializers.CharField(source='get_estado_display', read_only=True)
    
    class Meta:
        model = Pedido
        fields = '__all__'
        extra_kwargs = {
            'id_pedido': {'read_only': True},
            'fecha_pedido': {'read_only': True},
        }
    
    def get_tiene_factura_pagada(self, obj):
        return obj.tiene_factura_pagada()
    
    def get_puede_modificarse(self, obj):
        return obj.puede_modificarse()

class PedidoUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Pedido
        fields = '__all__'
        extra_kwargs = {
            'id_pedido': {'read_only': True},
            'cod_pedido': {'read_only': True},
            'fecha_pedido': {'read_only': True},
        }

class DetallePedidoSerializer(serializers.ModelSerializer):
    """Serializer para crear/actualizar detalles (sin subtotal)"""
    class Meta:
        model = DetallePedido
        exclude = ['subtotal']  # Excluir subtotal ya que es una columna generada
        extra_kwargs = {
            'id_detalle': {'read_only': True},
        }
    
    def create(self, validated_data):
        # Asegurar que subtotal no esté en validated_data
        validated_data.pop('subtotal', None)
        return super().create(validated_data)
    
    def update(self, instance, validated_data):
        # Asegurar que subtotal no esté en validated_data
        validated_data.pop('subtotal', None)
        return super().update(instance, validated_data)

class DetallePedidoReadSerializer(serializers.ModelSerializer):
    """Serializer para leer detalles (incluye subtotal calculado)"""
    class Meta:
        model = DetallePedido
        fields = '__all__'
