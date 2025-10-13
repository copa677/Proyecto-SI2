from django.urls import path
from .views import agregar_turno, obtener_turnos, desactivar_turno, actualizar_turno, eliminar_turno

urlpatterns = [
    path('agregar', agregar_turno),
    path('listar', obtener_turnos),
    path('desactivar/<int:turno_id>', desactivar_turno),
    path('actualizar/<int:turno_id>', actualizar_turno, name='actualizar_turno'),
    path('eliminar/<int:turno_id>', eliminar_turno, name='eliminar_turno'),
]