import datetime
import jwt
from django.conf import settings
from rest_framework.response import Response
from rest_framework import status
from functools import wraps
from .models import usurios

def jwt_required(view_func):
    @wraps(view_func)
    def wrapper(request, *args, **kwargs):
        auth_header = request.headers.get('Authorization')

        if not auth_header:
            return Response({'error': 'Token no proporcionado'}, status=status.HTTP_401_UNAUTHORIZED)

        try:
            token = auth_header.split(" ")[1]
            payload = jwt.decode(token, settings.SECRET_KEY, algorithms=["HS256"])
            user = usurios.objects.get(id=payload['id'])
            request.user = user
        except jwt.ExpiredSignatureError:
            return Response({'error': 'El token ha expirado'}, status=status.HTTP_401_UNAUTHORIZED)
        except (jwt.InvalidTokenError, IndexError):
            return Response({'error': 'Token inválido'}, status=status.HTTP_401_UNAUTHORIZED)
        except usurios.DoesNotExist:
            return Response({'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

        return view_func(request, *args, **kwargs)

    return wrapper



def generate_jwt(user):
    payload = {
        'id': user.id,
        'name_user': user.name_user,
        'exp': datetime.datetime.utcnow() + datetime.timedelta(minutes=30),
        'iat': datetime.datetime.utcnow()
    }
    token = jwt.encode(payload, settings.SECRET_KEY, algorithm='HS256')
    return token


def es_administrador(user):
    """
    Verifica si el usuario tiene rol de administrador
    """
    try:
        return user.rol == 'Administrador'
    except AttributeError:
        return False