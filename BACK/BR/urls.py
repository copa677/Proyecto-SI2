# backups/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('backup/', views.backup_database, name='backup'),
    path('restore/', views.restore_database, name='restore'),
    path('programar/', views.ProgramarBackupView.as_view(), name='programar-backup'),
    path('listar/', views.ListarBackupsView.as_view(), name='listar-backups'),
    path('cancelar/<str:job_id>/', views.CancelarBackupView.as_view(), name='cancelar-backup'),
]
