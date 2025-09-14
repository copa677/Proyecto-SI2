from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import usurios
from .serializers import LoginSerializer, RegisterSerializer ,UsuarioListSerializer
from .utils import generate_jwt
from django.db import connection 
# Create your views here.

@api_view(['POST'])
def login(request):
    serializer = LoginSerializer(data=request.data)
    if serializer.is_valid():
        username = serializer.validated_data['name_user']
        password = serializer.validated_data['password']

        try:
            user = usurios.objects.get(name_user=username)
        except usurios.DoesNotExist:
            return Response({'error': 'Usuario o password incorrecto'}, status=status.HTTP_404_NOT_FOUND)

        if user.check_password(password):
            token = generate_jwt(user)
            return Response({'token': token}, status=status.HTTP_200_OK)
        else:
            return Response({'error': 'Usuario o password incorrecto'}, status=status.HTTP_400_BAD_REQUEST)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def register(request):
    serializer = RegisterSerializer(data=request.data)
    if serializer.is_valid():
        data = serializer.validated_data
        if (usurios.objects.filter(name_user=data['name_user']).exists()):
            return Response({'error': 'El usuario ya existe'}, status=status.HTTP_400_BAD_REQUEST)

        nuevo_usuario = usurios(
            name_user=data['name_user'], 
            email=data['email'],
            tipo_usuario=data['tipo_usuario'],
            estado=data['estado']
        )
        nuevo_usuario.set_password(data['password'])
        nuevo_usuario.save()

        return Response({'mensaje': 'Usuario registrado con éxito'}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
def agregar_permiso(request):
    username = request.data.get('name_user')
    tipo_insertar = request.data.get('insertar')
    tipo_editar = request.data.get('editar')
    tipo_eliminar = request.data.get('eliminar')
    tipo_ver = request.data.get('ver')
    tipo_ventana = request.data.get('ventana')


    if not username:
        return Response({'error': 'El username y los permisos son obligatorios'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "CALL insertar_permisos(%s, %s, %s, %s, %s, %s)", 
                [username, tipo_ventana, tipo_insertar, tipo_editar, tipo_eliminar, tipo_ver]
            )
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    return Response({'mensaje': 'Permiso agregado con éxito'}, status=status.HTTP_200_OK)



@api_view(['GET'])
def obtener_permisos_usuario(request, username):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM get_permisos_usuario(%s)", [username])
            columnas = [col[0] for col in cursor.description]
            resultados = [
                dict(zip(columnas, fila))
                for fila in cursor.fetchall()
            ]
            return Response({'permisos': resultados}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
@api_view(['GET'])
def obtener_permisos_usuario_ventana(request, username, ventana):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM get_permisos_usuario_ventana(%s, %s)", [username, ventana])
            columnas = [col[0] for col in cursor.description]
            fila = cursor.fetchone()

            if fila:
                permisos = dict(zip(columnas, fila))
            else:
                # Si no hay datos, devolvemos todo en false
                permisos = {
                    'insertar': False,
                    'editar': False,
                    'eliminar': False,
                    'ver': False
                }

            return Response(permisos, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def actualizar_password(request, username):
    # Obtener el nuevo password desde la petición
    nuevo_password = request.data.get('password')

    if not nuevo_password:
        return Response({'error': 'El nuevo password es obligatorio'}, status=status.HTTP_400_BAD_REQUEST)

    try:
        # Buscar al usuario por el nombre de usuario
        usuario = usurios.objects.get(name_user=username)
        
        # Actualizar el password del usuario
        usuario.set_password(nuevo_password)
        usuario.save()
        
        return Response({'mensaje': 'Contraseña actualizada con éxito'}, status=status.HTTP_200_OK)

    except usurios.DoesNotExist:
        return Response({'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
@api_view(['GET'])
def obtener_usuario_por_id(request, id_usuario):
    try:
        usuario = usurios.objects.get(id=id_usuario)
        serializer = RegisterSerializer(usuario)  # Usa el serializer adecuado según los campos que quieras mostrar
        return Response(serializer.data, status=status.HTTP_200_OK)
    except usurios.DoesNotExist:
        return Response({'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)


@api_view(['GET'])
def obtener_username_por_email(request, email):
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT obtener_username_por_email(%s)", [email])
            username = cursor.fetchone()[0]
            return Response({'username': username}, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_404_NOT_FOUND)
    

@api_view(['GET'])
def obtener_tipo_usuario(request, username):
    try:
        usuario = usurios.objects.get(name_user=username)
        return Response({'tipo_usuario': usuario.tipo_usuario}, status=status.HTTP_200_OK)
    except usurios.DoesNotExist:
        return Response({'error': 'Usuario no encontrado'}, status=status.HTTP_404_NOT_FOUND)

@api_view(['GET'])
def obtener_todos_usuarios(request):
    try:
        usuarios = usurios.objects.all().order_by('id')
        serializer = UsuarioListSerializer(usuarios, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)   

@api_view(['POST'])
def editar_empleado_usuario(request):
    try:
        data = request.data
        id_usuario = data.get('id_usuario')
        nombre_empleado = data.get('nombre_completo')
        email = data.get('email')
        telefono = data.get('telefono')
        direccion = data.get('direccion')
        fecha_nacimiento = data.get('fecha_nacimiento')  # Asegúrate de que esté en formato 'YYYY-MM-DD'

        # Validación rápida de campos requeridos
        if not all([id_usuario, nombre_empleado, email, telefono, direccion, fecha_nacimiento]):
            return Response({'error': 'Faltan parámetros requeridos'}, status=status.HTTP_400_BAD_REQUEST)

        with connection.cursor() as cursor:
            cursor.execute("""
                CALL editar_empleado_usuario(%s, %s, %s, %s, %s, %s)
            """, [
                id_usuario,
                nombre_empleado,
                email,
                telefono,
                direccion,
                fecha_nacimiento
            ])

        return Response({'mensaje': 'Empleado actualizado correctamente'}, status=status.HTTP_200_OK)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    


