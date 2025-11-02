from django.urls import path
from . import views

urlpatterns = [
    path('crear/', views.crear_cliente, name='crear_cliente'),
    path('listar/', views.listar_clientes, name='listar_clientes'),
    path('obtener/<int:id_cliente>/', views.obtener_cliente, name='obtener_cliente'),
    path('actualizar/<int:id_cliente>/', views.actualizar_cliente, name='actualizar_cliente'),
    path('eliminar/<int:id_cliente>/', views.eliminar_cliente, name='eliminar_cliente'),
]
