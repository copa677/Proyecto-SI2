# -*- coding: utf-8 -*-
from functools import wraps
from rest_framework.response import Response
from rest_framework import status
from .roles import PERMISSIONS
from personal.models import personal

def require_permission(permission_name):
    """
    Decorador que comprueba si un usuario tiene un permiso específico basado en su rol.
    NOTA: Este decorador debe usarse DESPUÉS de @jwt_required para que request.user esté disponible.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            # Verificar que el usuario esté autenticado
            if not hasattr(request, 'user'):
                return Response({'error': 'Usuario no autenticado. Token requerido.'}, status=status.HTTP_401_UNAUTHORIZED)
            
            # El superusuario siempre tiene acceso
            if hasattr(request.user, 'is_superuser') and request.user.is_superuser:
                return view_func(request, *args, **kwargs)

            # Obtener el rol del usuario desde la tabla personal
            try:
                user_profile = personal.objects.get(id_usuario=request.user.id)
                user_role = user_profile.rol
            except personal.DoesNotExist:
                return Response({
                    'error': 'No tienes un perfil de personal asignado.',
                    'debug_info': f'Usuario ID: {request.user.id}, Username: {getattr(request.user, "name_user", "N/A")}'
                }, status=status.HTTP_403_FORBIDDEN)

            # Obtener la lista de permisos para el rol del usuario
            user_permissions = PERMISSIONS.get(user_role, [])

            # Si el rol es Administrador, tiene todos los permisos
            if user_role == 'Administrador':
                return view_func(request, *args, **kwargs)

            # Comprobar si el permiso requerido está en la lista de permisos del usuario
            if permission_name in user_permissions:
                return view_func(request, *args, **kwargs)
            else:
                return Response({'error': f'No tienes permiso para realizar esta acción. Se requiere el permiso: {permission_name}'}, status=status.HTTP_403_FORBIDDEN)
        
        return _wrapped_view
    return decorator