# clientes/views.py
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import connection, transaction
from .models import Cliente
from .serializers import ClientesSerializer
from usuarios.models import usurios  # tu modelo de usuarios


@api_view(['POST'])
def crear_cliente(request):
    """
    Crea un nuevo cliente y su respectivo usuario en la tabla usuarios.
    """
    try:
        data = request.data

        # Validar campos requeridos
        campos = ['nombre_completo', 'direccion', 'telefono', 'fecha_nacimiento', 'email', 'password', 'tipo_usuario']
        if not all(campo in data and data[campo] for campo in campos):
            return Response({'error': 'Faltan campos obligatorios'}, status=status.HTTP_400_BAD_REQUEST)

        username = data['name_user']
        nombre_completo = data['nombre_completo']
        direccion = data['direccion']
        telefono = data['telefono']
        fecha_nacimiento = data['fecha_nacimiento']
        email = data['email']
        password = data['password']
        tipo_usuario = data['tipo_usuario']

        # Verificar si ya existe un usuario con ese email o nombre
        if usurios.objects.filter(name_user=username).exists():
            return Response({'error': 'Ya existe un usuario con ese nombre'}, status=status.HTTP_400_BAD_REQUEST)

        with transaction.atomic():
            # Crear usuario
            nuevo_usuario = usurios(
                name_user=username,
                email=email,
                tipo_usuario=tipo_usuario,
                estado='activo'
            )
            nuevo_usuario.set_password(password)
            nuevo_usuario.save()

            # Crear cliente
            nuevo_cliente = Cliente(
                nombre_completo=nombre_completo,
                direccion=direccion,
                telefono=telefono,
                fecha_nacimiento=fecha_nacimiento,
                id_usuario=nuevo_usuario.id,
                estado='activo'
            )
            nuevo_cliente.save()

        return Response({'mensaje': 'Cliente y usuario creados exitosamente'}, status=status.HTTP_201_CREATED)

    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def listar_clientes(request):
    """
    Lista todos los clientes.
    """
    try:
        clientes = Cliente.objects.all().order_by('id')
        serializer = ClientesSerializer(clientes, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def obtener_cliente(request, id_cliente):
    """
    Obtiene los datos de un cliente por su ID.
    """
    try:
        cliente = Cliente.objects.get(id=id_cliente)
        serializer = ClientesSerializer(cliente)
        return Response(serializer.data, status=status.HTTP_200_OK)
    except Cliente.DoesNotExist:
        return Response({'error': 'Cliente no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PUT', 'PATCH'])
def actualizar_cliente(request, id_cliente):
    """
    Actualiza los datos de un cliente y su usuario relacionado.
    """
    try:
        cliente = Cliente.objects.get(id=id_cliente)
        data = request.data

        # Actualizar datos del cliente
        cliente.nombre_completo = data.get('nombre_completo', cliente.nombre_completo)
        cliente.direccion = data.get('direccion', cliente.direccion)
        cliente.telefono = data.get('telefono', cliente.telefono)
        cliente.fecha_nacimiento = data.get('fecha_nacimiento', cliente.fecha_nacimiento)
        cliente.estado = data.get('estado', cliente.estado)
        cliente.save()

        # Actualizar datos del usuario vinculado
        try:
            usuario = usurios.objects.get(id=cliente.id_usuario)
            usuario.name_user = cliente.nombre_completo
            usuario.email = data.get('email', usuario.email)
            usuario.tipo_usuario = data.get('tipo_usuario', usuario.tipo_usuario)
            if 'password' in data and data['password']:
                usuario.set_password(data['password'])
            usuario.save()
        except usurios.DoesNotExist:
            pass  # si no existe usuario, solo actualizamos cliente

        return Response({'mensaje': 'Cliente y usuario actualizados correctamente'}, status=status.HTTP_200_OK)

    except Cliente.DoesNotExist:
        return Response({'error': 'Cliente no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['DELETE'])
def eliminar_cliente(request, id_cliente):
    """
    Elimina un cliente y su usuario asociado.
    """
    try:
        cliente = Cliente.objects.get(id=id_cliente)
        id_usuario = cliente.id_usuario

        with transaction.atomic():
            # Eliminar cliente
            cliente.delete()

            # Eliminar usuario asociado (si existe)
            try:
                usuario = usurios.objects.get(id=id_usuario)
                usuario.delete()
            except usurios.DoesNotExist:
                pass

        return Response({'mensaje': 'Cliente y usuario eliminados correctamente'}, status=status.HTTP_200_OK)

    except Cliente.DoesNotExist:
        return Response({'error': 'Cliente no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
