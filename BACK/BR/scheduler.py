"""
Scheduler para programar backups automáticos usando APScheduler.
Compatible con AWS y cualquier plataforma cloud.
"""
from apscheduler.schedulers.background import BackgroundScheduler
from apscheduler.triggers.date import DateTrigger
from apscheduler.triggers.interval import IntervalTrigger
from datetime import datetime
import pytz
import os
import subprocess
from pathlib import Path
from django.conf import settings
import boto3
from botocore.exceptions import NoCredentialsError

# Scheduler global
scheduler = BackgroundScheduler(timezone=pytz.UTC)
scheduler.start()

def ejecutar_backup():
    """Función que ejecuta el backup y lo sube a S3"""
    try:
        BASE_DIR = settings.BASE_DIR
        BACKUP_DIR = os.path.join(BASE_DIR, "backups")
        os.makedirs(BACKUP_DIR, exist_ok=True)
        
        DB_NAME = os.environ.get("DB_NAME", "WF")
        DB_USER = os.environ.get("DB_USER", "postgres")
        DB_PASSWORD = os.environ.get("DB_PASSWORD", "password")
        DB_HOST = os.environ.get("DB_HOST", "localhost")
        DB_PORT = os.environ.get("DB_PORT", "5432")
        
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        filename = f"backup_auto_{timestamp}.dump"
        filepath = os.path.join(BACKUP_DIR, filename)
        
        env = os.environ.copy()
        env['PGPASSWORD'] = DB_PASSWORD
        
        subprocess.run(
            ['pg_dump', '-h', DB_HOST, '-p', DB_PORT, '-U', DB_USER, '-Fc', '-f', filepath, DB_NAME],
            env=env,
            capture_output=True,
            check=True
        )
        
        if os.path.exists(filepath):
            print(f"✅ Backup automático creado: {filename}")
            subir_a_s3(filepath, filename)
            return True
        else:
            print(f"❌ No se encontró el archivo de backup: {filename}")
            return False
    except Exception as e:
        print(f"❌ Error en backup automático: {e}")
        return False

def subir_a_s3(filepath, filename):
    """Sube el archivo de backup a S3"""
    AWS_ACCESS_KEY_ID = os.environ.get('AWS_ACCESS_KEY_ID')
    AWS_SECRET_ACCESS_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY')
    AWS_S3_BUCKET = os.environ.get('AWS_S3_BUCKET')
    AWS_S3_REGION = os.environ.get('AWS_S3_REGION', 'us-east-1')
    
    if not AWS_ACCESS_KEY_ID or not AWS_SECRET_ACCESS_KEY or not AWS_S3_BUCKET:
        print("❌ Faltan credenciales o configuración de S3 en variables de entorno.")
        return False
    
    s3 = boto3.client('s3',
        aws_access_key_id=AWS_ACCESS_KEY_ID,
        aws_secret_access_key=AWS_SECRET_ACCESS_KEY,
        region_name=AWS_S3_REGION
    )
    try:
        s3.upload_file(filepath, AWS_S3_BUCKET, filename)
        print(f"✅ Backup subido a S3: {filename}")
        return True
    except NoCredentialsError:
        print("❌ Credenciales de AWS no válidas.")
        return False
    except Exception as e:
        print(f"❌ Error al subir a S3: {e}")
        return False

def programar_backup_fecha(fecha_programada):
    """Programa un backup para una fecha específica"""
    job_id = f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    trigger = DateTrigger(run_date=fecha_programada, timezone=pytz.UTC)
    scheduler.add_job(ejecutar_backup, trigger, id=job_id)
    return job_id

def programar_backup_intervalo(intervalo_horas):
    """Programa un backup cada X horas"""
    job_id = f"backup_intervalo_{intervalo_horas}h"
    # Eliminar el job anterior si existe
    if scheduler.get_job(job_id):
        scheduler.remove_job(job_id)
    
    trigger = IntervalTrigger(hours=intervalo_horas, timezone=pytz.UTC)
    scheduler.add_job(ejecutar_backup, trigger, id=job_id)
    return job_id

def listar_backups_programados():
    """Lista todos los backups programados"""
    jobs = scheduler.get_jobs()
    return [{'id': job.id, 'next_run': str(job.next_run_time)} for job in jobs]

def cancelar_backup(job_id):
    """Cancela un backup programado"""
    try:
        scheduler.remove_job(job_id)
        return True
    except:
        return False
