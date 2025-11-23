from rest_framework import serializers
from .models import Precios

class PreciosSerializer(serializers.ModelSerializer):
    class Meta:
        model = Precios
        fields = '__all__'