import os
import subprocess
from datetime import datetime
from django.http import FileResponse
from rest_framework.response import Response
from rest_framework import status
from rest_framework.views import APIView
from django.conf import settings
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.decorators import api_view, parser_classes
import pytz
from .scheduler import programar_backup_fecha, programar_backup_intervalo, listar_backups_programados, cancelar_backup

BASE_DIR = settings.BASE_DIR

# Variables de entorno
DB_NAME = os.environ.get("DB_NAME", "WF")
DB_USER = os.environ.get("DB_USER", "postgres")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "password")
DB_HOST = os.environ.get("DB_HOST")
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
        subprocess.run(
            [
        "pg_dump",
                "-h", DB_HOST,
                "-p", DB_PORT,
                "-U", DB_USER,
                "-Fc",
                "-f", filepath,
                DB_NAME
            ],
        env=env,
        check=True
        )

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
@parser_classes([MultiPartParser, FormParser])
def restore_database(request):
    print("DEBUG - Content-Type:", request.content_type)
    print("DEBUG - FILES:", request.FILES.keys())

    file = request.FILES.get('file')
    if not file:
        return Response({
            "error": "No se envió ningún archivo",
            "keys_recibidas": list(request.FILES.keys()),
            "content_type": request.content_type
        }, status=status.HTTP_400_BAD_REQUEST)

    filepath = os.path.join(BACKUP_DIR, file.name)
    with open(filepath, 'wb') as f:
        for chunk in file.chunks():
            f.write(chunk)

    try:
        env = os.environ.copy()
        env["PGPASSWORD"] = os.environ.get("DB_PASSWORD", "password")

        subprocess.run([
            "pg_restore",
            "-h", os.environ.get("DB_HOST", "localhost"),
            "-p", os.environ.get("DB_PORT", "5432"),
            "-U", os.environ.get("DB_USER", "postgres"),
            "-d", os.environ.get("DB_NAME", "WF"),
            "-c",
            filepath
        ], env=env, check=True)

        return Response({"message": "✅ Restauración completada"}, status=200)

    except subprocess.CalledProcessError as e:
        return Response({"error": f"pg_restore falló: {e}"}, status=500)
    except Exception as e:
        return Response({"error": str(e)}, status=500)


class ProgramarBackupView(APIView):
    """Programar backup usando APScheduler (compatible con AWS y cualquier plataforma cloud)"""
    def post(self, request):
        from dateutil import parser as dateparser
        
        tipo = request.data.get('tipo')
        fecha_str = request.data.get('fecha_programada')
        intervalo_horas = request.data.get('intervalo_horas')

        if not tipo:
            return Response({'error': 'El campo tipo es requerido (fecha o intervalo).'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            if tipo == 'fecha':
                if not fecha_str:
                    return Response({'error': 'El campo fecha_programada es requerido.'}, status=status.HTTP_400_BAD_REQUEST)
                
                fecha_programada = dateparser.isoparse(fecha_str)
                if fecha_programada.tzinfo is None:
                    fecha_programada = pytz.UTC.localize(fecha_programada)
                
                if fecha_programada < datetime.now(pytz.UTC):
                    return Response({'error': 'La fecha de programación no puede ser en el pasado.'}, status=status.HTTP_400_BAD_REQUEST)
                
                job_id = programar_backup_fecha(fecha_programada)
                fecha_local = fecha_programada.astimezone()
                
                return Response({
                    'mensaje': f'Backup programado para el {fecha_local.strftime("%d de %B de %Y a las %H:%M")}.',
                    'job_id': job_id
                }, status=status.HTTP_201_CREATED)
            
            elif tipo == 'intervalo':
                if not intervalo_horas:
                    return Response({'error': 'El campo intervalo_horas es requerido.'}, status=status.HTTP_400_BAD_REQUEST)
                
                intervalo = int(intervalo_horas)
                if intervalo < 1:
                    return Response({'error': 'El intervalo debe ser al menos 1 hora.'}, status=status.HTTP_400_BAD_REQUEST)
                
                job_id = programar_backup_intervalo(intervalo)
                
                return Response({
                    'mensaje': f'Backup programado cada {intervalo} horas.',
                    'job_id': job_id
                }, status=status.HTTP_201_CREATED)
            
            else:
                return Response({'error': 'Tipo inválido.'}, status=status.HTTP_400_BAD_REQUEST)
                
        except Exception as e:
            return Response({'error': f'Error al programar: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)


class ListarBackupsView(APIView):
    """Lista todos los backups programados"""
    def get(self, request):
        try:
            jobs = listar_backups_programados()
            return Response({'backups_programados': jobs}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


class CancelarBackupView(APIView):
    """Cancela un backup programado"""
    def delete(self, request, job_id):
        try:
            if cancelar_backup(job_id):
                return Response({'mensaje': 'Backup cancelado correctamente.'}, status=status.HTTP_200_OK)
            else:
                return Response({'error': 'No se pudo cancelar el backup.'}, status=status.HTTP_404_NOT_FOUND)
        except Exception as e:
            return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
