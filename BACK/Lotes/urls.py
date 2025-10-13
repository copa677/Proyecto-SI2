from django.urls import path
from . import views

urlpatterns = [
    # Materias Primas
    path('listar_materias/', views.listar_materias_primas, name='listar_materias_primas'),
    path('materias/insertar/', views.insertar_materia_prima, name='insertar_materia_prima'),
    path('materias/actualizar/<int:id_materia>/', views.actualizar_materia_prima, name='actualizar_materia_prima'),
    path('materias/eliminar/<int:id_materia>/', views.eliminar_materia_prima, name='eliminar_materia_prima'),

    # Lotes
    path('listar_lotes/', views.listar_lotes, name='listar_lotes'),
    path('lotes/insertar/', views.insertar_lote, name='insertar_lote'),
    path('lotes/actualizar/<int:id_lote>/', views.actualizar_lote, name='actualizar_lote'),
    path('lotes/eliminar/<int:id_lote>/', views.eliminar_lote, name='eliminar_lote'),
]
