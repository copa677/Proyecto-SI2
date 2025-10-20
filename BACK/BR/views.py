import os
import subprocess
from datetime import datetime
from django.http import FileResponse
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings

BASE_DIR = settings.BASE_DIR

# Variables de entorno
DB_NAME = os.environ.get("DB_NAME", "WF")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "password")
DB_HOST = os.environ.get("DB_HOST", "localhost")
DB_PORT = os.environ.get("DB_PORT", "5432")

BACKUP_DIR = os.path.join(BASE_DIR, "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)


@api_view(['GET'])
def backup_database(request):
    """Genera un archivo .dump, lo guarda y lo ofrece para descargar"""
    try:
        # 📄 Nombre único con timestamp
        filename = f"{DB_NAME}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.dump"
        filepath = os.path.join(BACKUP_DIR, filename)

        env = os.environ.copy()
        env["PGPASSWORD"] = DB_PASSWORD

        # 🧠 Comando pg_dump
        command = (
            f'"C:\\Program Files\\PostgreSQL\\17\\bin\\pg_dump.exe" '
            f'-h {DB_HOST} -p {DB_PORT} -U {DB_USER} -Fc -f "{filepath}" {DB_NAME}'
        )

        subprocess.run(command, shell=True, env=env, check=True)

        # 📁 Verifica que el archivo realmente se creó
        if not os.path.exists(filepath):
            return Response(
                {"error": "No se generó el archivo de respaldo."},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

        # ✅ Enviar el archivo al usuario (descarga directa)
        response = FileResponse(
            open(filepath, 'rb'),
            as_attachment=True,
            filename=filename
        )
        return response

    except subprocess.CalledProcessError as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



@api_view(['POST'])
def restore_database(request):
    """Restaura la base de datos desde un archivo .dump"""
    file = request.FILES.get('file')
    if not file:
        return Response({"error": "No se envió ningún archivo"}, status=status.HTTP_400_BAD_REQUEST)

    filepath = os.path.join(BACKUP_DIR, file.name)
    with open(filepath, 'wb') as f:
        for chunk in file.chunks():
            f.write(chunk)

    try:
        env = os.environ.copy()
        env["PGPASSWORD"] = DB_PASSWORD

        subprocess.run([
            "pg_restore",
            "-h", DB_HOST,
            "-p", DB_PORT,
            "-U", DB_USER,
            "-d", DB_NAME,
            "-c",  # limpia antes de restaurar
            filepath
        ], env=env, check=True)

        return Response({"message": "✅ Restauración completada"}, status=status.HTTP_200_OK)

    except subprocess.CalledProcessError as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    except Exception as e:
        return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
