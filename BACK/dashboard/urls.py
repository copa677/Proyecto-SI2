from django.urls import path
from . import views

urlpatterns = [
    path('estadisticas/', views.obtener_estadisticas_dashboard, name='dashboard-estadisticas'),
    path('ordenes-recientes/', views.obtener_ordenes_recientes, name='dashboard-ordenes-recientes'),
    path('inventario-critico/', views.obtener_inventario_critico, name='dashboard-inventario-critico'),
]
