from django.urls import path
from . import views

urlpatterns = [
    # 🧾 NOTA SALIDA
    path('notas_salida/', views.listar_notas_salida, name='listar_notas_salida'),
    path('notas_salida/<int:id_salida>/', views.obtener_nota_salida, name='obtener_nota_salida'),
    path('notas_salida/registrar/<int:id_usuario>/', views.registrar_nota_salida, name='registrar_nota_salida'),
    path('notas_salida/actualizar/<int:id_salida>/', views.actualizar_nota_salida, name='actualizar_nota_salida'),
    path('notas_salida/eliminar/<int:id_salida>/', views.eliminar_nota_salida, name='eliminar_nota_salida'),
    path('notas_salida/crear/', views.crear_nota_salida_con_detalles, name='crear_nota_salida_con_detalles'),

    # 📦 DETALLE NOTA SALIDA
    path('detalles_salida/<int:id_salida>/', views.listar_detalles_salida, name='listar_detalles_salida'),
    path('detalle_salida/<int:id_detalle>/', views.obtener_detalle_salida, name='obtener_detalle_salida'),
    path('detalle_salida/registrar/<int:id_salida>/', views.registrar_detalle_salida, name='registrar_detalle_salida'),
    path('detalle_salida/actualizar/<int:id_detalle>/', views.actualizar_detalle_salida, name='actualizar_detalle_salida'),
    path('detalle_salida/eliminar/<int:id_detalle>/', views.eliminar_detalle_salida, name='eliminar_detalle_salida'),
]
