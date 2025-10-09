from django.urls import path
from .views import agregar_asistencia, obtener_asistencias, actualizar_asistencia, eliminar_asistencia

urlpatterns = [
    path('agregar', agregar_asistencia, name='agregar_asistencia'),
    path('listar', obtener_asistencias, name='obtener_asistencias'),
    path('actualizar/<int:id_control>', actualizar_asistencia, name='actualizar_asistencia'),
    path('eliminar/<int:id_control>', eliminar_asistencia, name='eliminar_asistencia'),
]
