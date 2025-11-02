from django.urls import path
from . import views

urlpatterns = [
    path('ordenes/', views.listar_ordenes_produccion, name='listar_ordenes_produccion'),
    path('ordenes/<int:id_orden>/', views.obtener_orden_produccion, name='obtener_orden_produccion'),
    path('ordenes/insertar/', views.insertar_orden_produccion, name='insertar_orden_produccion'),
    path('ordenes/crear-con-materias/', views.crear_orden_con_materias, name='crear_orden_con_materias'),
    path('ordenes/actualizar/<int:id_orden>/', views.actualizar_orden_produccion, name='actualizar_orden_produccion'),
    path('ordenes/eliminar/<int:id_orden>/', views.eliminar_orden_produccion, name='eliminar_orden_produccion'),
    path('ordenes/<int:id_orden>/trazabilidad/', views.obtener_trazabilidad_orden, name='obtener_trazabilidad_orden'),
]
