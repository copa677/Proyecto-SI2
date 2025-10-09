from django.urls import path
from . import views

urlpatterns = [
    path('controles/', views.listar_controles_calidad, name='listar_controles_calidad'),
    path('controles/<int:id_control>/', views.obtener_control_calidad, name='obtener_control_calidad'),
    path('controles/insertar/', views.insertar_control_calidad, name='insertar_control_calidad'),
    path('controles/actualizar/<int:id_control>/', views.actualizar_control_calidad, name='actualizar_control_calidad'),
    path('controles/eliminar/<int:id_control>/', views.eliminar_control_calidad, name='eliminar_control_calidad'),
]
