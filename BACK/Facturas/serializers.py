from rest_framework import serializers
from .models import Factura

class FacturaSerializer(serializers.ModelSerializer):
    # Campos adicionales de la base de datos que no están en el modelo
    numero_factura = serializers.CharField(source='cod_factura', read_only=True)
    fecha_emision = serializers.DateTimeField(source='fecha_creacion', read_only=True)
    fecha_vencimiento = serializers.SerializerMethodField()
    
    class Meta:
        model = Factura
        fields = [
            'id_factura', 'id_pedido', 'numero_factura', 'cod_factura',
            'fecha_emision', 'fecha_creacion', 'fecha_vencimiento',
            'monto_total', 'stripe_payment_intent_id', 'stripe_checkout_session_id',
            'estado_pago', 'metodo_pago', 'fecha_pago',
            'codigo_autorizacion', 'ultimos_digitos_tarjeta', 'tipo_tarjeta'
        ]
        read_only_fields = [
            'id_factura', 'cod_factura', 'fecha_creacion', 
            'stripe_payment_intent_id', 'stripe_checkout_session_id',
            'estado_pago', 'metodo_pago', 'fecha_pago',
            'codigo_autorizacion', 'ultimos_digitos_tarjeta', 'tipo_tarjeta'
        ]
    
    def get_fecha_vencimiento(self, obj):
        """
        Calcula la fecha de vencimiento (30 días después de la creación)
        """
        from datetime import timedelta
        if obj.fecha_creacion:
            fecha_venc = obj.fecha_creacion + timedelta(days=30)
            return fecha_venc
        return None