from django.urls import path
from .views import agregar_asistencia, obtener_asistencias
urlpatterns = [
    path('agregar', agregar_asistencia, name='agregar_asistencia'),
    path('listar', obtener_asistencias, name='obtener_asistencias'),
]
