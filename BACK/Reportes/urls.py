from django.urls import path
from .views import (
    ReporteVentasView, 
    ReporteProduccionView, 
    ReporteInventarioView,
    ReporteClientesView,
    ReporteBitacoraView,
    ReportePersonalView,
    ReportePedidosView
)

urlpatterns = [
    path('ventas/', ReporteVentasView.as_view(), name='reporte-ventas'),
    path('produccion/', ReporteProduccionView.as_view(), name='reporte-produccion'),
    path('inventario-consumo/', ReporteInventarioView.as_view(), name='reporte-inventario'),
    path('clientes/', ReporteClientesView.as_view(), name='reporte-clientes'),
    path('bitacora/', ReporteBitacoraView.as_view(), name='reporte-bitacora'),
    path('personal/', ReportePersonalView.as_view(), name='reporte-personal'),
    path('pedidos/', ReportePedidosView.as_view(), name='reporte-pedidos'),
]
