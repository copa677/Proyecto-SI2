
from django.urls import path
from .views import (login, register, agregar_permiso, actualizar_password, obtener_usuario_por_id,
                    obtener_username_por_email, obtener_permisos_usuario, obtener_permisos_usuario_ventana,
                    obtener_tipo_usuario, editar_empleado_usuario, obtener_todos_usuarios,
                    actualizar_usuario, eliminar_usuario)

urlpatterns = [
    path('login', login, name='login'),
    path('register', register, name='register'),
    path('permisos', agregar_permiso),
    path('getuser', obtener_todos_usuarios, name='getuser'),
    path('getpermisosUser/<str:username>', obtener_permisos_usuario),
    path('getpermisosUser_Ventana/<str:username>/<str:ventana>', obtener_permisos_usuario_ventana),
    path('newPassword/<str:username>', actualizar_password),
    path('getUser/<int:id_usuario>', obtener_usuario_por_id),
    path('username_email/<str:email>', obtener_username_por_email),
    path('tipo_usuario/<str:username>', obtener_tipo_usuario),
    path('actualizarEmpleadoUsuario', editar_empleado_usuario),
    path('actualizar/<int:id_usuario>', actualizar_usuario, name='actualizar_usuario'),
    path('eliminar/<int:id_usuario>', eliminar_usuario, name='eliminar_usuario'),
]
