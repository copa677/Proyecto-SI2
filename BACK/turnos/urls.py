from django.urls import path
from .views import agregar_turno

urlpatterns = [
    path('agregar', agregar_turno),
]