from django.utils import timezone
from .models import Bitacora
import json


class BitacoraMiddleware:
    """
    Middleware que registra automáticamente todas las peticiones HTTP relevantes en la bitácora.
    Registra: POST, PUT, PATCH, DELETE (acciones que modifican datos)
    """
    
    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Capturar el body antes de procesar (para tener acceso al username)
        body_data = None
        if request.method in ['POST', 'PUT', 'PATCH'] and request.body:
            try:
                body_data = json.loads(request.body.decode('utf-8'))
            except:
                body_data = None
        
        # Procesar la petición
        response = self.get_response(request)
        
        # Solo registrar métodos que modifican datos y respuestas exitosas
        metodos_registrar = ['POST', 'PUT', 'PATCH', 'DELETE']
        
        # No registrar peticiones a /admin/ o /static/
        rutas_excluir = ['/admin/', '/static/', '/media/', '/api/bitacora/']
        
        if (request.method in metodos_registrar and 
            response.status_code < 400 and 
            not any(request.path.startswith(ruta) for ruta in rutas_excluir)):
            
            self._registrar_accion(request, response, body_data)
        
        return response

    def _registrar_accion(self, request, response, body_data=None):
        """Registra la acción en la bitácora"""
        try:
            # Determinar la acción basándose en el método y la ruta
            accion = self._determinar_accion(request)
            
            # Obtener el usuario del body capturado
            username = self._obtener_usuario(request, body_data)
            
            # Obtener la IP del cliente
            ip = self._obtener_ip(request)
            
            # Crear descripción detallada con contexto adicional
            descripcion = self._crear_descripcion_detallada(request, response, body_data)
            
            # Guardar en la bitácora usando SQL directo para evitar problemas con la secuencia
            from django.db import connection
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO bitacora (username, ip, fecha_hora, accion, descripcion)
                    VALUES (%s, %s, %s, %s, %s)
                """, [username, ip, timezone.now(), accion, descripcion])
                
        except Exception as e:
            # No queremos que un error en la bitácora afecte la aplicación
            print(f"Error al registrar en bitácora: {str(e)}")

    def _obtener_usuario(self, request, body_data=None):
        """Obtiene el nombre de usuario de la petición de forma robusta."""
        # PRIORIDAD 1: Usuario autenticado en el request (JWT o Sesión)
        # Si el usuario está autenticado, usamos su representación de cadena (__str__)
        # que en el modelo 'usurios' devuelve 'name_user'. Esto es definitivo.
        if hasattr(request, 'user') and request.user and getattr(request.user, 'is_authenticated', False):
            user_str = str(request.user)
            if user_str:
                return user_str

        # PRIORIDAD 2: Para acciones sin autenticación (login, registro), buscar en el body.
        # Campo especial de bitácora para forzar un usuario.
        if body_data and isinstance(body_data, dict):
            bitacora_user = body_data.get('__bitacora_user__')
            if bitacora_user:
                return bitacora_user
            
            # Campos comunes de usuario en el body.
            username = body_data.get('name_user') or body_data.get('username') or body_data.get('user')
            if username:
                return username

        # PRIORIDAD 3: Datos de formulario (form-data).
        if request.method == 'POST':
            username = request.POST.get('name_user') or request.POST.get('username') or request.POST.get('user')
            if username:
                return username
                
        # Si no se encuentra de ninguna forma, es anónimo.
        return 'Anónimo'

    def _obtener_ip(self, request):
        """Obtiene la dirección IP del cliente"""
        # Obtener IP real si está detrás de un proxy
        x_forwarded_for = request.META.get('HTTP_X_FORWARDED_FOR')
        if x_forwarded_for:
            ip = x_forwarded_for.split(',')[0]
        else:
            ip = request.META.get('REMOTE_ADDR', '0.0.0.0')
        return ip

    def _determinar_accion(self, request):
        """Determina el tipo de acción basándose en el método HTTP y la ruta"""
        metodo = request.method
        ruta = request.path.lower()
        
        # === AUTENTICACIÓN Y USUARIOS ===
        if 'login' in ruta:
            return 'INICIO_SESION'
        elif 'register' in ruta or 'registro' in ruta:
            return 'REGISTRO_USUARIO'
        elif 'logout' in ruta:
            return 'CIERRE_SESION'
        elif 'newpassword' in ruta or 'actualizar_password' in ruta:
            return 'CAMBIO_PASSWORD'
        elif 'permisos' in ruta:
            if metodo == 'POST':
                return 'ASIGNACION_PERMISOS'
            elif metodo in ['PUT', 'PATCH']:
                return 'MODIFICACION_PERMISOS'
            elif metodo == 'DELETE':
                return 'ELIMINACION_PERMISOS'
            else:
                return 'CONSULTA_PERMISOS'
        elif 'usuario' in ruta:
            if metodo == 'POST':
                return 'CREACION_USUARIO'
            elif metodo in ['PUT', 'PATCH']:
                return 'ACTUALIZACION_USUARIO'
            elif metodo == 'DELETE':
                return 'ELIMINACION_USUARIO'
        
        # === PERSONAL/EMPLEADOS ===
        elif 'personal' in ruta or 'empleado' in ruta:
            if metodo == 'POST':
                return 'REGISTRO_EMPLEADO'
            elif metodo in ['PUT', 'PATCH']:
                return 'ACTUALIZACION_EMPLEADO'
            elif metodo == 'DELETE':
                return 'ELIMINACION_EMPLEADO'
        
        # === TURNOS ===
        elif 'turno' in ruta:
            if 'desactivar' in ruta:
                return 'DESACTIVACION_TURNO'
            elif metodo == 'POST':
                return 'CREACION_TURNO'
            elif metodo in ['PUT', 'PATCH']:
                return 'ACTUALIZACION_TURNO'
            elif metodo == 'DELETE':
                return 'ELIMINACION_TURNO'
        
        # === ASISTENCIAS ===
        elif 'asistencia' in ruta:
            if metodo == 'POST':
                return 'REGISTRO_ASISTENCIA'
            elif metodo in ['PUT', 'PATCH']:
                return 'ACTUALIZACION_ASISTENCIA'
            elif metodo == 'DELETE':
                return 'ELIMINACION_ASISTENCIA'
        
        # === GENÉRICO ===
        elif metodo == 'POST':
            return 'CREACION'
        elif metodo == 'PUT':
            return 'ACTUALIZACION_COMPLETA'
        elif metodo == 'PATCH':
            return 'ACTUALIZACION_PARCIAL'
        elif metodo == 'DELETE':
            return 'ELIMINACION'
        
        return f'{metodo}_REQUEST'

    def _crear_descripcion(self, request, response):
        """Crea una descripción legible y natural de la acción"""
        ruta = request.path.lower()
        metodo = request.method
        
        # === AUTENTICACIÓN ===
        if 'login' in ruta:
            return 'Usuario inició sesión en el sistema'
        
        if 'register' in ruta or 'registro' in ruta:
            return 'Se registró un nuevo usuario en el sistema'
        
        if 'logout' in ruta:
            return 'Usuario cerró sesión'
        
        if 'newpassword' in ruta or 'actualizar_password' in ruta:
            return 'Usuario cambió su contraseña'
        
        # === PERMISOS ===
        if 'permisos' in ruta:
            if metodo == 'POST':
                return 'Usuario asignó permisos a otro usuario'
            elif metodo in ['PUT', 'PATCH']:
                return 'Usuario modificó los permisos de otro usuario'
            elif metodo == 'DELETE':
                return 'Usuario eliminó permisos de otro usuario'
            else:
                return 'Usuario consultó permisos'
        
        # === USUARIOS ===
        if 'usuario' in ruta and 'empleado' not in ruta:
            if 'actualizarempleadousuario' in ruta:
                return 'Usuario actualizó la vinculación empleado-usuario'
            elif 'tipo_usuario' in ruta:
                return 'Usuario consultó el tipo de usuario'
            elif 'username_email' in ruta:
                return 'Usuario consultó información por email'
            elif metodo == 'POST':
                return 'Usuario creó una nueva cuenta de usuario'
            elif metodo in ['PUT', 'PATCH']:
                return 'Usuario actualizó información de un usuario'
            elif metodo == 'DELETE':
                return 'Usuario eliminó una cuenta de usuario'
        
        # === PERSONAL/EMPLEADOS ===
        if 'personal' in ruta or 'empleado' in ruta:
            if 'registrar' in ruta or metodo == 'POST':
                return 'Usuario registró un nuevo empleado en el sistema'
            elif 'actualizar' in ruta or metodo in ['PUT', 'PATCH']:
                return 'Usuario actualizó la información de un empleado'
            elif 'eliminar' in ruta or metodo == 'DELETE':
                return 'Usuario eliminó un empleado del sistema'
            elif 'getempleado' in ruta:
                return 'Usuario consultó información de empleados'
        
        # === TURNOS ===
        if 'turno' in ruta:
            if 'desactivar' in ruta:
                return 'Usuario desactivó un turno'
            elif 'agregar' in ruta or metodo == 'POST':
                return 'Usuario creó un nuevo turno de trabajo'
            elif metodo in ['PUT', 'PATCH']:
                return 'Usuario modificó un turno existente'
            elif metodo == 'DELETE':
                return 'Usuario eliminó un turno'
            elif 'listar' in ruta:
                return 'Usuario consultó la lista de turnos'
        
        # === ASISTENCIAS ===
        if 'asistencia' in ruta:
            if 'agregar' in ruta or metodo == 'POST':
                return 'Usuario registró una asistencia de empleado'
            elif metodo in ['PUT', 'PATCH']:
                return 'Usuario modificó un registro de asistencia'
            elif metodo == 'DELETE':
                return 'Usuario eliminó un registro de asistencia'
            elif 'listar' in ruta:
                return 'Usuario consultó registros de asistencias'
        
        # === GENÉRICO CON CONTEXTO ===
        modulo = self._extraer_modulo(ruta)
        
        if metodo == 'POST':
            return f'Usuario creó un nuevo registro en {modulo}'
        elif metodo in ['PUT', 'PATCH']:
            return f'Usuario actualizó información en {modulo}'
        elif metodo == 'DELETE':
            return f'Usuario eliminó un registro de {modulo}'
        
        return f'Usuario realizó una operación en {modulo}'
    
    def _extraer_modulo(self, ruta):
        """Extrae el módulo de la ruta para descripciones genéricas"""
        partes = ruta.split('/')
        if len(partes) > 2:
            modulo = partes[2]
            # Capitalizar y hacer más legible
            return modulo.replace('_', ' ').capitalize()
        return 'el sistema'
    
    def _crear_descripcion_detallada(self, request, response, body_data=None):
        """Crea descripción con información adicional relevante"""
        descripcion_base = self._crear_descripcion(request, response)
        detalles_extra = []
        
        # Agregar información específica según el tipo de acción
        ruta = request.path.lower()
        
        # Para empleados, agregar nombre si está disponible
        if 'empleado' in ruta or 'personal' in ruta:
            if body_data and isinstance(body_data, dict):
                nombre = body_data.get('nombre') or body_data.get('nombre_completo')
                if nombre:
                    detalles_extra.append(f"Empleado: {nombre}")
        
        # Para turnos, agregar tipo de turno
        if 'turno' in ruta:
            if body_data and isinstance(body_data, dict):
                turno = body_data.get('turno') or body_data.get('turno_nombre')
                if turno:
                    detalles_extra.append(f"Turno: {turno}")
        
        # Para asistencias, agregar información del empleado
        if 'asistencia' in ruta:
            if body_data and isinstance(body_data, dict):
                nombre = body_data.get('nombre')
                estado = body_data.get('estado')
                if nombre:
                    detalles_extra.append(f"Empleado: {nombre}")
                if estado:
                    detalles_extra.append(f"Estado: {estado}")
        
        # Para usuarios, agregar email o tipo
        if 'usuario' in ruta and body_data and isinstance(body_data, dict):
            email = body_data.get('email')
            tipo_usuario = body_data.get('tipo_usuario')
            if email and 'register' in ruta:
                detalles_extra.append(f"Email: {email}")
            if tipo_usuario:
                detalles_extra.append(f"Tipo: {tipo_usuario}")
        
        # Para permisos, agregar usuario afectado
        if 'permiso' in ruta and body_data and isinstance(body_data, dict):
            usuario_afectado = body_data.get('name_user') or body_data.get('username')
            ventana = body_data.get('ventana')
            if usuario_afectado:
                detalles_extra.append(f"Para usuario: {usuario_afectado}")
            if ventana:
                detalles_extra.append(f"Ventana: {ventana}")
        
        # Construir descripción final
        if detalles_extra:
            return f"{descripcion_base} ({', '.join(detalles_extra)})"
        
        return descripcion_base

    def _filtrar_datos_sensibles(self, data):
        """Filtra información sensible como contraseñas"""
        if not isinstance(data, dict):
            return {}
        
        datos_filtrados = data.copy()
        campos_sensibles = ['password', 'pwd', 'token', 'secret', 'api_key']
        
        for campo in campos_sensibles:
            if campo in datos_filtrados:
                datos_filtrados[campo] = '***OCULTO***'
        
        return datos_filtrados
