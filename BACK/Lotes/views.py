from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db import transaction
from .models import MateriaPrima, Lote
from .serializers import MateriaPrimaSerializer, LoteSerializer
from Inventario.models import Inventario
from datetime import datetime


# ---------- MATERIA PRIMA ----------
@api_view(['GET'])
def listar_materias_primas(request):
    materias = MateriaPrima.objects.all()
    serializer = MateriaPrimaSerializer(materias, many=True)
    return Response(serializer.data)

@api_view(['POST'])
def insertar_materia_prima(request):
    serializer = MateriaPrimaSerializer(data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def actualizar_materia_prima(request, id_materia):
    try:
        materia = MateriaPrima.objects.get(id_materia=id_materia)
    except MateriaPrima.DoesNotExist:
        return Response({'error': 'Materia Prima no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = MateriaPrimaSerializer(materia, data=request.data)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
def eliminar_materia_prima(request, id_materia):
    try:
        materia = MateriaPrima.objects.get(id_materia=id_materia)
    except MateriaPrima.DoesNotExist:
        return Response({'error': 'Materia Prima no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    materia.delete()
    return Response({'mensaje': 'Materia Prima eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)


# ---------- LOTES ----------
@api_view(['GET'])
def listar_lotes(request):
    lotes = Lote.objects.all()
    serializer = LoteSerializer(lotes, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@transaction.atomic
def insertar_lote(request):
    """
    Crea un nuevo lote y actualiza el inventario total de esa materia prima.
    - Si ya existe inventario: SUMA la cantidad
    - Si no existe: CREA uno nuevo
    """
    serializer = LoteSerializer(data=request.data)
    if serializer.is_valid():
        # Crear el lote
        lote = serializer.save()
        
        # Obtener información de la materia prima
        try:
            materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
            nombre_materia = materia.nombre
            
            # 🔹 Determinar unidad de medida basada en el tipo de material
            nombre_lower = nombre_materia.lower()
            if 'hilo' in nombre_lower or 'tela' in nombre_lower or 'algodón' in nombre_lower:
                unidad_medida = 'metros'
            else:
                unidad_medida = 'kg'
                
        except MateriaPrima.DoesNotExist:
            transaction.set_rollback(True)
            return Response(
                {'error': f'No se encontró la materia prima con id {lote.id_materia}'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 🔹 Buscar inventario existente para esta materia prima
        inventario_existente = Inventario.objects.filter(
            nombre_materia_prima=nombre_materia
        ).first()
        
        if inventario_existente:
            # ✅ Ya existe: SUMAR la cantidad del nuevo lote
            inventario_existente.cantidad_actual += lote.cantidad
            inventario_existente.fecha_actualizacion = datetime.now()
            inventario_existente.save()
            
            return Response({
                'mensaje': 'Lote creado e inventario actualizado correctamente',
                'lote': serializer.data,
                'inventario_actualizado': True,
                'cantidad_total_inventario': float(inventario_existente.cantidad_actual),
                'unidad_medida': unidad_medida
            }, status=status.HTTP_201_CREATED)
        else:
            # ✅ No existe: CREAR nuevo inventario
            Inventario.objects.create(
                nombre_materia_prima=nombre_materia,
                cantidad_actual=lote.cantidad,
                unidad_medida=unidad_medida,
                ubicacion='Almacén Principal',
                estado='Disponible',
                fecha_actualizacion=datetime.now(),
                id_lote=lote.id_lote  # Referencia al primer lote
            )
            
            return Response({
                'mensaje': 'Lote e inventario creados correctamente',
                'lote': serializer.data,
                'inventario_creado': True,
                'unidad_medida': unidad_medida
            }, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
@transaction.atomic
def actualizar_lote(request, id_lote):
    """
    Actualiza un lote y ajusta el inventario total de esa materia prima.
    Calcula la diferencia y la suma/resta del inventario total.
    """
    try:
        lote = Lote.objects.get(id_lote=id_lote)
        cantidad_anterior = lote.cantidad
    except Lote.DoesNotExist:
        return Response({'error': 'Lote no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = LoteSerializer(lote, data=request.data)
    if serializer.is_valid():
        lote = serializer.save()
        
        # Calcular diferencia de cantidad
        diferencia = lote.cantidad - cantidad_anterior
        
        # Obtener nombre de la materia prima
        try:
            materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
            nombre_materia = materia.nombre
            
            # 🔹 Determinar unidad de medida
            nombre_lower = nombre_materia.lower()
            if 'hilo' in nombre_lower or 'tela' in nombre_lower or 'algodón' in nombre_lower:
                unidad_medida = 'metros'
            else:
                unidad_medida = 'kg'
                
        except MateriaPrima.DoesNotExist:
            return Response({
                'mensaje': 'Lote actualizado correctamente',
                'lote': serializer.data,
                'warning': 'Materia prima no encontrada, inventario no sincronizado'
            })
        
        # 🔹 Actualizar el inventario total sumando/restando la diferencia
        inventario = Inventario.objects.filter(nombre_materia_prima=nombre_materia).first()
        
        if inventario:
            inventario.cantidad_actual += diferencia
            if inventario.cantidad_actual < 0:
                inventario.cantidad_actual = 0
            inventario.fecha_actualizacion = datetime.now()
            inventario.save()
            
            return Response({
                'mensaje': 'Lote e inventario actualizados correctamente',
                'lote': serializer.data,
                'inventario_actualizado': True,
                'diferencia': float(diferencia),
                'cantidad_total_inventario': float(inventario.cantidad_actual)
            })
        else:
            return Response({
                'mensaje': 'Lote actualizado correctamente (sin inventario asociado)',
                'lote': serializer.data,
                'inventario_actualizado': False
            })
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@transaction.atomic
def eliminar_lote(request, id_lote):
    """
    Elimina un lote y resta su cantidad del inventario total
    """
    try:
        lote = Lote.objects.get(id_lote=id_lote)
    except Lote.DoesNotExist:
        return Response({'error': 'Lote no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    # Obtener la materia prima y restar del inventario
    try:
        materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
        nombre_materia = materia.nombre
        cantidad_lote = lote.cantidad
        
        # Buscar inventario y restar cantidad
        inventario = Inventario.objects.filter(nombre_materia_prima=nombre_materia).first()
        if inventario:
            inventario.cantidad_actual -= cantidad_lote
            if inventario.cantidad_actual < 0:
                inventario.cantidad_actual = 0
            inventario.fecha_actualizacion = datetime.now()
            inventario.save()
            inventario_ajustado = True
        else:
            inventario_ajustado = False
    except MateriaPrima.DoesNotExist:
        inventario_ajustado = False
    
    lote.delete()
    
    return Response({
        'mensaje': 'Lote eliminado correctamente',
        'inventario_ajustado': inventario_ajustado
    }, status=status.HTTP_200_OK)
