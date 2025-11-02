from django.db import models
from django.contrib.auth.hashers import make_password, check_password

# Create your models here.
class usurios(models.Model):
    id = models.AutoField(primary_key=True)
    name_user = models.CharField(max_length=100, unique=True)
    email = models.EmailField(max_length=100)
    password = models.CharField(max_length=128)
    tipo_usuario = models.CharField(max_length=50)
    estado =  models.CharField(max_length=20)

    def set_password(self, raw_password):
        self.password = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.password)

    @property
    def is_active(self):
        """Propiedad requerida por Django REST Framework"""
        return self.estado == 'activo' if hasattr(self, 'estado') else True
    
    @property
    def is_authenticated(self):
        """Propiedad para indicar que el usuario está autenticado"""
        return True

    def __str__(self):
        return self.name_user
    
    class Meta:
        db_table = 'usuarios'  #  Este es el nombre real de tu tabla en la base de datos
        managed = False        #  Esto evita que Django intente crear/modificar la tabla
