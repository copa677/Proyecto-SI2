from django.apps import AppConfig


class BrConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'BR'
    
    def ready(self):
        """Inicia el scheduler cuando Django arranca"""
        from .scheduler import scheduler
        if not scheduler.running:
            scheduler.start()
