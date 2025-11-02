from django.urls import path
from . import views

urlpatterns = [
    # Trazabilidad de procesos (original)
    path('trazabilidades/', views.listar_trazabilidades, name='listar_trazabilidades'),
    path('trazabilidades/<int:id_trazabilidad>/', views.obtener_trazabilidad, name='obtener_trazabilidad'),
    path('trazabilidades/insertar/', views.insertar_trazabilidad, name='insertar_trazabilidad'),
    path('trazabilidades/actualizar/<int:id_trazabilidad>/', views.actualizar_trazabilidad, name='actualizar_trazabilidad'),
    path('trazabilidades/eliminar/<int:id_trazabilidad>/', views.eliminar_trazabilidad, name='eliminar_trazabilidad'),
    
    # Trazabilidad de lotes (nuevo sistema FIFO)
    path('trazabilidad-lotes/', views.listar_trazabilidad_lotes, name='listar_trazabilidad_lotes'),
    path('trazabilidad-lotes/orden/<int:id_orden>/', views.obtener_trazabilidad_por_orden, name='trazabilidad_por_orden'),
    path('trazabilidad-lotes/nota-salida/<int:id_nota>/', views.obtener_trazabilidad_por_nota_salida, name='trazabilidad_por_nota'),
    path('trazabilidad-lotes/lote/<int:id_lote>/', views.obtener_trazabilidad_por_lote, name='trazabilidad_por_lote'),
    path('trazabilidad-lotes/materia/<int:id_materia>/', views.obtener_trazabilidad_por_materia, name='trazabilidad_por_materia'),
]
