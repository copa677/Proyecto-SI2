from django.urls import path
from . import views

urlpatterns = [
    path('trazabilidades/', views.listar_trazabilidades, name='listar_trazabilidades'),
    path('trazabilidades/<int:id_trazabilidad>/', views.obtener_trazabilidad, name='obtener_trazabilidad'),
    path('trazabilidades/insertar/', views.insertar_trazabilidad, name='insertar_trazabilidad'),
    path('trazabilidades/actualizar/<int:id_trazabilidad>/', views.actualizar_trazabilidad, name='actualizar_trazabilidad'),
    path('trazabilidades/eliminar/<int:id_trazabilidad>/', views.eliminar_trazabilidad, name='eliminar_trazabilidad'),
]
