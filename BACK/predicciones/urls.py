from django.urls import path
from . import views

urlpatterns = [
    # Modelos predictivos
    path('modelo/entrenar/', views.entrenar_modelo, name='entrenar_modelo'),
    path('modelo/predecir/', views.predecir_pedidos, name='predecir_pedidos'),
    path('modelo/<int:modelo_id>/metricas/', views.obtener_metricas_modelo, name='metricas_modelo'),
    
    # Análisis y reportes
    path('analisis/tendencias/', views.analisis_tendencias, name='analisis_tendencias'),
]