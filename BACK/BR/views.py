import os
import subprocess
from datetime import datetime
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.conf import settings
BASE_DIR = settings.BASE_DIR

# Leer variables del entorno (desde tu .env)
DB_NAME = os.environ.get("DB_NAME")
DB_USER = os.environ.get("DB_USER")
DB_PASSWORD = os.environ.get("DB_PASSWORD")
DB_HOST = os.environ.get("DB_HOST")
DB_PORT = os.environ.get("DB_PORT")

BACKUP_DIR = os.path.join(BASE_DIR, "backups")
os.makedirs(BACKUP_DIR, exist_ok=True)


@api_view(['GET'])
def backup_database(request):
    """Genera un archivo .dump de la base de datos"""
    try:
        filename = f"{DB_NAME}_{datetime.now().strftime('%Y%m%d_%H%M%S')}.dump"
        filepath = os.path.join(BACKUP_DIR, filename)

        env = os.environ.copy()
        env["PGPASSWORD"] = DB_PASSWORD

        # ⚙️ En Windows se debe usar shell=True
        subprocess.run(
            f'"C:\\Program Files\\PostgreSQL\\17\\bin\\pg_dump.exe" -h {DB_HOST} -p {DB_PORT} -U {DB_USER} -Fc -f "{filepath}" {DB_NAME}',
            shell=True,      # ✅ necesario para que Windows encuentre pg_dump
            env=env,
            check=True
        )

        return Response({"message": f"✅ Backup creado: {filename}"}, status=status.HTTP_200_OK)

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
