from rest_framework import serializers
from .models import ModeloPrediccion, PrediccionPedido

class ModeloPrediccionSerializer(serializers.ModelSerializer):
    class Meta:
        model = ModeloPrediccion
        fields = '__all__'

class PrediccionPedidoSerializer(serializers.ModelSerializer):
    class Meta:
        model = PrediccionPedido
        fields = '__all__'

class EntrenamientoSerializer(serializers.Serializer):
    tipo_modelo = serializers.ChoiceField(choices=[
        'regresion_lineal', 
        'arima', 
        'prophet', 
        'random_forest'
    ])
    meses_historico = serializers.IntegerField(default=12)
    parametros = serializers.JSONField(required=False)