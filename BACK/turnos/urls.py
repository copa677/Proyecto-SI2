from django.urls import path
from .views import agregar_turno, obtener_turnos, desactivar_turno

urlpatterns = [
    path('agregar', agregar_turno),
    path('listar', obtener_turnos),
    path('desactivar/<int:turno_id>', desactivar_turno),
]