from django.urls import path
from .views import listar_bitacoras, registrar_bitacora

urlpatterns = [
    path('listar', listar_bitacoras, name='listar_bitacoras'),
    path('registrar', registrar_bitacora, name='registrar_bitacora'),
]
