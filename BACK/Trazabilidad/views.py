from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q
from .models import Trazabilidad, TrazabilidadLote
from .serializers import TrazabilidadSerializer, InsertarTrazabilidadSerializer, TrazabilidadLoteSerializer
from personal.models import personal   # Importar modelo personal


# 🟢 LISTAR TODAS LAS TRAZABILIDADES
@api_view(['GET'])
def listar_trazabilidades(request):
    trazas = Trazabilidad.objects.all()
    
    # Enriquecer con información del personal
    trazas_data = []
    for traza in trazas:
        traza_dict = {
            'id_trazabilidad': traza.id_trazabilidad,
            'proceso': traza.proceso,
            'descripcion_proceso': traza.descripcion_proceso,
            'fecha_registro': traza.fecha_registro,
            'hora_inicio': traza.hora_inicio,
            'hora_fin': traza.hora_fin,
            'cantidad': traza.cantidad,
            'estado': traza.estado,
            'id_personal': traza.id_personal,
            'id_orden': traza.id_orden
        }
        
        # Obtener nombre del personal
        try:
            persona = personal.objects.get(id=traza.id_personal)
            traza_dict['nombre_personal'] = persona.nombre_completo
            traza_dict['rol_personal'] = persona.rol
        except personal.DoesNotExist:
            traza_dict['nombre_personal'] = 'N/A'
            traza_dict['rol_personal'] = 'N/A'
        
        trazas_data.append(traza_dict)
    
    return Response(trazas_data, status=status.HTTP_200_OK)


# 🟢 OBTENER TRAZABILIDAD POR ID
@api_view(['GET'])
def obtener_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = TrazabilidadSerializer(traza)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 INSERTAR NUEVA TRAZABILIDAD (usando nombre del personal)
@api_view(['POST'])
def insertar_trazabilidad(request):
    serializer = InsertarTrazabilidadSerializer(data=request.data)
    if serializer.is_valid():
        nombre_personal = serializer.validated_data.get('nombre_personal')

        # Buscar al personal por nombre completo
        try:
            persona = personal.objects.get(nombre_completo=nombre_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el nombre "{nombre_personal}"'}, status=status.HTTP_400_BAD_REQUEST)

        # Crear registro en Trazabilidad
        nueva_traza = Trazabilidad.objects.create(
            proceso=serializer.validated_data['proceso'],
            descripcion_proceso=serializer.validated_data['descripcion_proceso'],
            fecha_registro=serializer.validated_data['fecha_registro'],
            hora_inicio=serializer.validated_data['hora_inicio'],
            hora_fin=serializer.validated_data['hora_fin'],
            cantidad=serializer.validated_data['cantidad'],
            estado=serializer.validated_data['estado'],
            id_personal=persona.id,  # ID obtenido desde la tabla personal
            id_orden=serializer.validated_data['id_orden']
        )

        return Response({'mensaje': 'Trazabilidad registrada correctamente'}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ACTUALIZAR TRAZABILIDAD EXISTENTE
@api_view(['PUT'])
def actualizar_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = InsertarTrazabilidadSerializer(data=request.data)
    if serializer.is_valid():
        nombre_personal = serializer.validated_data.get('nombre_personal')

        try:
            persona = personal.objects.get(nombre_completo=nombre_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el nombre "{nombre_personal}"'}, status=status.HTTP_400_BAD_REQUEST)

        # Actualizar campos
        for campo, valor in serializer.validated_data.items():
            if campo != 'nombre_personal':  # este no se guarda directamente
                setattr(traza, campo, valor)
        traza.id_personal = persona.id
        traza.save()

        return Response({'mensaje': 'Trazabilidad actualizada correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ELIMINAR TRAZABILIDAD
@api_view(['DELETE'])
def eliminar_trazabilidad(request, id_trazabilidad):
    try:
        traza = Trazabilidad.objects.get(id_trazabilidad=id_trazabilidad)
    except Trazabilidad.DoesNotExist:
        return Response({'error': 'Trazabilidad no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    traza.delete()
    return Response({'mensaje': 'Trazabilidad eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)


# ========================================
# 📦 ENDPOINTS PARA TRAZABILIDAD DE LOTES
# ========================================

@api_view(['GET'])
def listar_trazabilidad_lotes(request):
    """
    Lista toda la trazabilidad de lotes con filtros opcionales
    Filtros: tipo_operacion, id_operacion, id_lote, id_materia, fecha_desde, fecha_hasta
    """
    trazas = TrazabilidadLote.objects.all()
    
    # Filtros opcionales
    tipo_operacion = request.GET.get('tipo_operacion', None)
    id_operacion = request.GET.get('id_operacion', None)
    id_lote = request.GET.get('id_lote', None)
    id_materia = request.GET.get('id_materia', None)
    fecha_desde = request.GET.get('fecha_desde', None)
    fecha_hasta = request.GET.get('fecha_hasta', None)
    
    if tipo_operacion:
        trazas = trazas.filter(tipo_operacion=tipo_operacion)
    if id_operacion:
        trazas = trazas.filter(id_operacion=id_operacion)
    if id_lote:
        trazas = trazas.filter(id_lote=id_lote)
    if id_materia:
        trazas = trazas.filter(id_materia=id_materia)
    if fecha_desde:
        trazas = trazas.filter(fecha_consumo__gte=fecha_desde)
    if fecha_hasta:
        trazas = trazas.filter(fecha_consumo__lte=fecha_hasta)
    
    # Ordenar por fecha descendente (más reciente primero)
    trazas = trazas.order_by('-fecha_consumo')
    
    serializer = TrazabilidadLoteSerializer(trazas, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_trazabilidad_por_orden(request, id_orden):
    """
    Obtiene toda la trazabilidad de lotes consumidos en una orden de producción específica
    """
    trazas = TrazabilidadLote.objects.filter(
        tipo_operacion='orden_produccion',
        id_operacion=id_orden
    ).order_by('id_lote')
    
    serializer = TrazabilidadLoteSerializer(trazas, many=True)
    return Response({
        'id_orden': id_orden,
        'total_registros': len(trazas),
        'trazabilidad': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_trazabilidad_por_nota_salida(request, id_nota):
    """
    Obtiene toda la trazabilidad de lotes consumidos en una nota de salida específica
    """
    trazas = TrazabilidadLote.objects.filter(
        tipo_operacion='nota_salida',
        id_operacion=id_nota
    ).order_by('id_lote')
    
    serializer = TrazabilidadLoteSerializer(trazas, many=True)
    return Response({
        'id_nota': id_nota,
        'total_registros': len(trazas),
        'trazabilidad': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_trazabilidad_por_lote(request, id_lote):
    """
    Obtiene todo el historial de consumo de un lote específico
    """
    trazas = TrazabilidadLote.objects.filter(id_lote=id_lote).order_by('-fecha_consumo')
    
    serializer = TrazabilidadLoteSerializer(trazas, many=True)
    return Response({
        'id_lote': id_lote,
        'total_consumos': len(trazas),
        'historial': serializer.data
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_trazabilidad_por_materia(request, id_materia):
    """
    Obtiene toda la trazabilidad de consumo de una materia prima específica
    """
    trazas = TrazabilidadLote.objects.filter(id_materia=id_materia).order_by('-fecha_consumo')
    
    serializer = TrazabilidadLoteSerializer(trazas, many=True)
    return Response({
        'id_materia': id_materia,
        'total_consumos': len(trazas),
        'historial': serializer.data
    }, status=status.HTTP_200_OK)
