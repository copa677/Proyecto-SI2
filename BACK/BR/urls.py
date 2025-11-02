# backups/urls.py
from django.urls import path
from . import views

urlpatterns = [
    path('backup/', views.backup_database, name='backup'),
    path('restore/', views.restore_database, name='restore'),
]
