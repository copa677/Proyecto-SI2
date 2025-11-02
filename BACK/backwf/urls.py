
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/usuario/', include('usuarios.urls')),
    path('api/personal/', include('personal.urls')),
    path('api/turnos/', include('turnos.urls')),
    path('api/asistencias/', include('asistencias.urls')),
    path('api/bitacora/', include('Bitacora.urls')),
    path('api/lotes/', include('Lotes.urls')),
    path('api/ordenproduccion/', include('OrdenProduccion.urls')),
    path('api/trazabilidad/', include('Trazabilidad.urls')),
    path('api/controlcalidad/', include('ControlCalidad.urls')),
    path('api/inventario/', include('Inventario.urls')),
    path('api/notasalida/', include('NotaSalida.urls')),
    path('api/br/', include('BR.urls')),
    path('api/clientes/', include('Clientes.urls')),
]
