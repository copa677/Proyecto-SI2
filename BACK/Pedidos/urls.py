from django.urls import path
from . import views

urlpatterns = [
    # CRUD Pedidos
    path('crear/', views.crear_pedido, name='crear_pedido'),
    path('listar/', views.listar_pedidos_todos, name='listar_pedidos'),
    path('listar-todos/', views.listar_pedidos_todos, name='listar_pedidos_todos'),
    path('obtener/<int:id_pedido>/', views.obtener_pedido, name='obtener_pedido'),
    path('actualizar/<int:id_pedido>/', views.actualizar_pedido, name='actualizar_pedido'),
    path('actualizar-estado/<int:id_pedido>/', views.actualizar_estado_pedido, name='actualizar_estado_pedido'),
    
    # CRUD Detalle Pedido
    path('detalles/crear/', views.crear_detalle_pedido, name='crear_detalle_pedido'),
    path('detalles/listar/<int:id_pedido>/', views.listar_detalles_pedido, name='listar_detalles_pedido'),
    path('detalles/obtener/<int:id_detalle>/', views.obtener_detalle_pedido, name='obtener_detalle_pedido'),
    path('detalles/actualizar/<int:id_detalle>/', views.actualizar_detalle_pedido, name='actualizar_detalle_pedido'),
    path('detalles/eliminar/<int:id_detalle>/', views.eliminar_detalle_pedido, name='eliminar_detalle_pedido'),
    
    # Integración con Facturas
    path('con-detalles/<int:id_pedido>/', views.obtener_pedido_con_detalles, name='obtener_pedido_con_detalles'),
    path('verificar-facturacion/<int:id_pedido>/', views.verificar_estado_facturacion, name='verificar_estado_facturacion'),
    path('facturables/', views.listar_pedidos_facturables, name='listar_pedidos_facturables'),
]