from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from django.db import models
from .models import Precios
from .serializers import PreciosSerializer

# GET - Listar precios activos
@api_view(['GET'])
def precios_list(request):
    """
    Listar todos los precios activos
    """
    precios = Precios.objects.filter(activo=True)
    serializer = PreciosSerializer(precios, many=True)
    return Response(serializer.data)

# GET - Listar TODOS los precios (incluyendo inactivos)
@api_view(['GET'])
def precios_list_all(request):
    """
    Listar TODOS los precios (incluyendo inactivos)
    """
    precios = Precios.objects.all()
    serializer = PreciosSerializer(precios, many=True)
    return Response(serializer.data)

# GET - Obtener un precio específico por ID
@api_view(['GET'])
def precios_detail(request, pk):
    """
    Obtener un precio específico por ID
    """
    try:
        precio = Precios.objects.get(id_precio=pk)
        serializer = PreciosSerializer(precio)
        return Response(serializer.data)
    except Precios.DoesNotExist:
        return Response(
            {'error': 'Precio no encontrado'}, 
            status=status.HTTP_404_NOT_FOUND
        )

# GET - Buscar precios
@api_view(['GET'])
def precios_search(request):
    """
    Buscar precios por descripción, material o talla
    """
    query = request.GET.get('q', '')
    
    if query:
        precios = Precios.objects.filter(
            models.Q(decripcion__icontains=query) |
            models.Q(material__icontains=query) |
            models.Q(talla__icontains=query),
            activo=True
        )
    else:
        precios = Precios.objects.filter(activo=True)
    
    serializer = PreciosSerializer(precios, many=True)
    return Response(serializer.data)

# POST - Crear nuevo precio
@api_view(['POST'])
def precios_create(request):
    """
    Crear un nuevo precio
    """
    serializer = PreciosSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# PUT - Actualizar precio existente
@api_view(['PUT'])
def precios_update(request, pk):
    """
    Actualizar un precio existente
    """
    try:
        precio = Precios.objects.get(id_precio=pk)
    except Precios.DoesNotExist:
        return Response(
            {'error': 'Precio no encontrado'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    serializer = PreciosSerializer(precio, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

# DELETE - Eliminación lógica
@api_view(['DELETE'])
def precios_delete(request, pk):
    """
    Eliminar (desactivar) un precio (eliminación lógica)
    """
    try:
        precio = Precios.objects.get(id_precio=pk)
    except Precios.DoesNotExist:
        return Response(
            {'error': 'Precio no encontrado'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    precio.activo = False
    precio.save()
    return Response(
        {'message': 'Precio desactivado correctamente'}, 
        status=status.HTTP_200_OK
    )

# PUT - Reactivar precio
@api_view(['PUT'])
def precios_activate(request, pk):
    """
    Reactivar un precio previamente desactivado
    """
    try:
        precio = Precios.objects.get(id_precio=pk)
    except Precios.DoesNotExist:
        return Response(
            {'error': 'Precio no encontrado'}, 
            status=status.HTTP_404_NOT_FOUND
        )
    
    precio.activo = True
    precio.save()
    serializer = PreciosSerializer(precio)
    return Response(serializer.data)