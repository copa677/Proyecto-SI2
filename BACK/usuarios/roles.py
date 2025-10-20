
# -*- coding: utf-8 -*-
def get_user_role(user):
    '''
    Obtiene el rol de un usuario a partir del modelo personal.
    '''
    try:
        # Asumiendo que el modelo personal está vinculado al usuario de Django
        # a través de un campo que coincide con user.id o user.username
        # Esta consulta puede necesitar ajuste dependiendo de tu estructura exacta
        persona = personal.objects.get(id_usuario=user.id)
        return persona.rol
    except personal.DoesNotExist:
        return None

# Define los permisos para cada rol
# Formato: 'app_label.action_model'
# actions: view, add, change, delete

PERMISSIONS = {
    'Administrador': [
        # Permisos completos para todas las aplicaciones
        # Gestión de Acceso y Administración del Sistema
        'auth.view_user', 'auth.add_user', 'auth.change_user', 'auth.delete_user',
        'auth.view_group', 'auth.add_group', 'auth.change_group', 'auth.delete_group',
        'personal.view_personal', 'personal.add_personal', 'personal.change_personal', 'personal.delete_personal',
        'asistencias.view_asistencia', 'asistencias.add_asistencia', 'asistencias.change_asistencia', 'asistencias.delete_asistencia',
        'turnos.view_turno', 'turnos.add_turno', 'turnos.change_turno', 'turnos.delete_turno',
        'Bitacora.view_bitacora', 'Bitacora.add_bitacora', 'Bitacora.change_bitacora', 'Bitacora.delete_bitacora',

        # Producción e Inventario
        'Inventario.view_inventario', 'Inventario.add_inventario', 'Inventario.change_inventario', 'Inventario.delete_inventario',
        'Lotes.view_lote', 'Lotes.add_lote', 'Lotes.change_lote', 'Lotes.delete_lote',
        'OrdenProduccion.view_ordenproduccion', 'OrdenProduccion.add_ordenproduccion', 'OrdenProduccion.change_ordenproduccion', 'OrdenProduccion.delete_ordenproduccion',
        'ControlCalidad.view_controlcalidad', 'ControlCalidad.add_controlcalidad', 'ControlCalidad.change_controlcalidad', 'ControlCalidad.delete_controlcalidad',
        'Trazabilidad.view_trazabilidad', 'Trazabilidad.add_trazabilidad', 'Trazabilidad.change_trazabilidad', 'Trazabilidad.delete_trazabilidad',
        'NotaSalida.view_notasalida', 'NotaSalida.add_notasalida', 'NotaSalida.change_notasalida', 'NotaSalida.delete_notasalida',

        # Ventas y Pedidos (Asumiendo un modelo 'pedido')
        'pedidos.view_pedido', 'pedidos.add_pedido', 'pedidos.change_pedido', 'pedidos.delete_pedido',
    ],
    'Supervisor': [
        # Gestión de Acceso
        'auth.view_user', 'auth.change_user', # Puede ver y modificar su propio usuario

        # Administración del Sistema
        'asistencias.view_asistencia', 'asistencias.add_asistencia', 'asistencias.change_asistencia', 'asistencias.delete_asistencia',
        'turnos.view_turno', 'turnos.add_turno', 'turnos.change_turno', 'turnos.delete_turno',
        'personal.view_personal', # Puede ver al personal

        # Producción e Inventario
        'Inventario.view_inventario', 'Inventario.add_inventario', 'Inventario.change_inventario', 'Inventario.delete_inventario',
        'Lotes.view_lote', 'Lotes.add_lote', 'Lotes.change_lote', 'Lotes.delete_lote',
        'OrdenProduccion.view_ordenproduccion', 'OrdenProduccion.add_ordenproduccion', 'OrdenProduccion.change_ordenproduccion', 'OrdenProduccion.delete_ordenproduccion',
        'ControlCalidad.view_controlcalidad', 'ControlCalidad.add_controlcalidad', 'ControlCalidad.change_controlcalidad', 'ControlCalidad.delete_controlcalidad',
        'Trazabilidad.view_trazabilidad', 'Trazabilidad.add_trazabilidad', 'Trazabilidad.change_trazabilidad', 'Trazabilidad.delete_trazabilidad',
        'NotaSalida.view_notasalida', 'NotaSalida.add_notasalida', 'NotaSalida.change_notasalida', 'NotaSalida.delete_notasalida',

        # Ventas y Pedidos
        'pedidos.view_pedido', 'pedidos.add_pedido', 'pedidos.change_pedido', 'pedidos.delete_pedido',

        # Reportes
        'reporting.view_report', # Asumiendo un modelo de reportes
    ],
    'Operario': [
        # Gestión de Acceso
        'auth.view_user', 'auth.change_user', # Puede ver y modificar su propio usuario

        # Producción e Inventario
        'Inventario.view_inventario', # Puede ver inventario para consultar stock
        'Lotes.view_lote',
        'OrdenProduccion.view_ordenproduccion', 'OrdenProduccion.add_ordenproduccion', 'OrdenProduccion.change_ordenproduccion', # Puede gestionar las órdenes que se le asignan
        'ControlCalidad.view_controlcalidad', 'ControlCalidad.add_controlcalidad', 'ControlCalidad.change_controlcalidad',
        'Trazabilidad.view_trazabilidad', 'Trazabilidad.add_trazabilidad',
        'NotaSalida.view_notasalida', 'NotaSalida.add_notasalida',

        # Notificaciones
        'notifications.view_notification',
    ]
}
