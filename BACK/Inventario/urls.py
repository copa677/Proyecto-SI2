from django.urls import path
from . import views

urlpatterns = [
    path('inventario/', views.listar_inventario, name='listar_inventario'),
    path('inventario/<int:id_inventario>/', views.obtener_inventario, name='obtener_inventario'),
    path('inventario/registrar/', views.registrar_inventario, name='registrar_inventario'),
    path('inventario/actualizar/<int:id_inventario>/', views.actualizar_inventario, name='actualizar_inventario'),
    path('inventario/eliminar/<int:id_inventario>/', views.eliminar_inventario, name='eliminar_inventario'),
]
