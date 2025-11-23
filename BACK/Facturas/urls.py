from django.urls import path
from . import views

urlpatterns = [
    # Stripe Checkout
    path('pago/crear-sesion/<int:id_pedido>/', views.crear_sesion_pago, name='crear_sesion_pago'),
    path('pago/exito/', views.pago_exitoso, name='pago_exitoso'),
    path('pago/cancelado/', views.pago_cancelado, name='pago_cancelado'),
    path('pago/verificar/<int:id_factura>/', views.verificar_estado_pago, name='verificar_estado_pago'),
    
    # Webhook
    path('webhook/stripe/', views.webhook_stripe, name='webhook_stripe'),
    
    # CRUD Facturas
    path('', views.listar_facturas, name='listar_facturas'),
    path('<int:id_factura>/', views.obtener_factura, name='obtener_factura'),
    path('mis-facturas/', views.obtener_facturas_cliente, name='obtener_facturas_cliente'),
    
    # Factura manual (para empleados)
    path('crear-manual/', views.crear_factura_manual, name='crear_factura_manual'),
]