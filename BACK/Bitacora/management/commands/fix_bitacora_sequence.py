from django.core.management.base import BaseCommand
from django.db import connection


class Command(BaseCommand):
    help = 'Corrige la secuencia de la tabla bitacora en PostgreSQL'

    def handle(self, *args, **options):
        try:
            with connection.cursor() as cursor:
                # Resetear la secuencia al valor máximo actual + 1
                cursor.execute("""
                    SELECT setval(
                        pg_get_serial_sequence('bitacora', 'id_bitacora'), 
                        COALESCE((SELECT MAX(id_bitacora) FROM bitacora), 1), 
                        true
                    )
                """)
                
                # Obtener el valor actual de la secuencia
                cursor.execute("""
                    SELECT currval(pg_get_serial_sequence('bitacora', 'id_bitacora'))
                """)
                secuencia_actual = cursor.fetchone()[0]
                
                # Obtener el máximo ID en la tabla
                cursor.execute("SELECT MAX(id_bitacora) FROM bitacora")
                max_id = cursor.fetchone()[0] or 0
                
                self.stdout.write(self.style.SUCCESS(f'✓ Secuencia corregida exitosamente!'))
                self.stdout.write(self.style.SUCCESS(f'  Máximo ID en tabla: {max_id}'))
                self.stdout.write(self.style.SUCCESS(f'  Valor de secuencia: {secuencia_actual}'))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error al corregir la secuencia: {str(e)}'))
