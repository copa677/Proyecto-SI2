
from django.urls import path
from .views import registrar_Empleado,obtener_empleados,obtener_empleado_nombre,actualizar_empleado,eliminar_empleado,obtener_empleado_por_usuario

urlpatterns = [
    path('registrar', registrar_Empleado),
    path('getEmpleados', obtener_empleados),
    path('getEmpleado/<str:nombre>', obtener_empleado_nombre),
    path('getEmpleadoID/<str:id_usuario>', obtener_empleado_por_usuario),
    path('actualizar', actualizar_empleado),
    path('eliminar', eliminar_empleado),
]
