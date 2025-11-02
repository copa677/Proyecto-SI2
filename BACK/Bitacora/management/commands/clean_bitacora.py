from django.core.management.base import BaseCommand
from Bitacora.models import Bitacora
from django.utils import timezone
from datetime import timedelta


class Command(BaseCommand):
    help = 'Limpia registros de bitácora antiguos (más de X días)'

    def add_arguments(self, parser):
        parser.add_argument(
            '--days',
            type=int,
            default=90,
            help='Número de días de antigüedad para limpiar (por defecto: 90)',
        )

    def handle(self, *args, **options):
        dias = options['days']
        fecha_limite = timezone.now() - timedelta(days=dias)
        
        try:
            # Contar registros a eliminar
            count = Bitacora.objects.filter(fecha_hora__lt=fecha_limite).count()
            
            if count == 0:
                self.stdout.write(self.style.WARNING(f'No hay registros de bitácora mayores a {dias} días.'))
                return
            
            # Confirmar acción
            self.stdout.write(self.style.WARNING(f'Se eliminarán {count} registros de bitácora mayores a {dias} días.'))
            confirmacion = input('¿Desea continuar? (s/n): ')
            
            if confirmacion.lower() == 's':
                # Eliminar registros antiguos
                Bitacora.objects.filter(fecha_hora__lt=fecha_limite).delete()
                self.stdout.write(self.style.SUCCESS(f'✓ Se eliminaron {count} registros antiguos de la bitácora.'))
            else:
                self.stdout.write(self.style.WARNING('Operación cancelada.'))
                
        except Exception as e:
            self.stdout.write(self.style.ERROR(f'✗ Error al limpiar bitácora: {str(e)}'))
