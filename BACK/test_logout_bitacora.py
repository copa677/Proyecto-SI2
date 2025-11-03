"""
Test rápido para verificar que el logout registre correctamente en bitácora
"""

from django.test import TestCase, Client
from django.urls import reverse
from usuarios.models import usurios
from Bitacora.models import Bitacora
from usuarios.utils import generate_jwt


class LogoutBitacoraTest(TestCase):
    def setUp(self):
        """Configuración inicial del test"""
        # Crear usuario de prueba
        self.user = usurios.objects.create(
            name_user='test_logout',
            email='test@example.com',
            tipo_usuario='empleado',
            estado='activo'
        )
        self.user.set_password('password123')
        self.user.save()
        
        # Generar token JWT
        self.token = generate_jwt(self.user)
        
        # Cliente HTTP
        self.client = Client()
    
    def test_logout_registra_en_bitacora(self):
        """Verificar que logout registre correctamente en bitácora"""
        
        # Contar registros de bitácora antes
        count_antes = Bitacora.objects.count()
        
        # Hacer logout con token
        response = self.client.post(
            '/api/usuario/logout/',
            HTTP_AUTHORIZATION=f'Bearer {self.token}'
        )
        
        # Verificar respuesta exitosa
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()['mensaje'], 'Cierre de sesión exitoso')
        
        # Verificar que se creó un registro en bitácora
        count_despues = Bitacora.objects.count()
        self.assertEqual(count_despues, count_antes + 1)
        
        # Verificar el contenido del registro
        ultimo_registro = Bitacora.objects.order_by('-id_bitacora').first()
        self.assertEqual(ultimo_registro.username, 'test_logout')
        self.assertEqual(ultimo_registro.accion, 'CIERRE_SESION')
        self.assertIn('cerró sesión', ultimo_registro.descripcion)
        
    def test_logout_sin_token(self):
        """Verificar que logout sin token retorne error"""
        response = self.client.post('/api/usuario/logout/')
        self.assertEqual(response.status_code, 401)
        self.assertIn('Token no proporcionado', response.json()['error'])


if __name__ == '__main__':
    import django
    django.setup()
    
    from django.test.utils import get_runner
    from django.conf import settings
    
    TestRunner = get_runner(settings)
    test_runner = TestRunner()
    failures = test_runner.run_tests(["__main__"])
