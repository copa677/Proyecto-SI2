from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Bitacora
from .serializers import RegistroBitacora, serializerBitacora
from django.utils import timezone


# � Función auxiliar para obtener el usuario del request
def obtener_usuario_request(request):
    """
    Extrae el username del request para registrar en bitácora.
    Úsala en tus vistas agregando: username = obtener_usuario_request(request)
    """
    # Intentar obtener del body
    if hasattr(request, 'data') and isinstance(request.data, dict):
        return request.data.get('name_user') or request.data.get('username') or request.data.get('user') or 'Sistema'
    return 'Sistema'


# �📋 Listar todas las bitácoras
@api_view(["GET"])
def listar_bitacoras(request):
    bitacoras = Bitacora.objects.all().order_by("-fecha_hora")  # orden descendente
    serializer = serializerBitacora(bitacoras, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 📝 Registrar una nueva bitácora
@api_view(["POST"])
def registrar_bitacora(request):
    serializer = RegistroBitacora(data=request.data)
    if serializer.is_valid():
        try:
            # Usar SQL directo para evitar problemas con la secuencia
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO bitacora (username, ip, fecha_hora, accion, descripcion)
                    VALUES (%s, %s, %s, %s, %s)
                """, [
                    serializer.validated_data["username"],
                    serializer.validated_data["ip"],
                    serializer.validated_data["fecha_hora"],
                    serializer.validated_data["accion"],
                    serializer.validated_data["descripcion"]
                ])
            return Response({"message": "Bitácora registrada correctamente"}, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": f"Error al registrar: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
