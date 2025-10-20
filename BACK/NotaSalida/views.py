from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from rest_framework import serializers
from .models import NotaSalida, DetalleNotaSalida
from .serializers import (
    NotaSalidaSerializer,
    RegistrarNotaSalidaSerializer,
    DetalleNotaSalidaSerializer,
    RegistrarDetalleNotaSalidaSerializer,
    NotaSalidaConDetallesSerializer
)
from Lotes.models import Lote, MateriaPrima
from Inventario.models import Inventario
from personal.models import personal
from Trazabilidad.models import TrazabilidadLote
from django.db import transaction
from datetime import datetime

# ============================================================
# 🟢 CRUD NOTA SALIDA (CABECERA)
# ============================================================

@api_view(['POST'])
@transaction.atomic
def crear_nota_salida_con_detalles(request):
    serializer = NotaSalidaConDetallesSerializer(data=request.data)
    if serializer.is_valid():
        # Crear la nota de salida
        nota_data = serializer.validated_data
        nota = NotaSalida.objects.create(
            fecha_salida=nota_data['fecha_salida'],
            motivo=nota_data['motivo'],
            id_personal=nota_data['id_personal'],
            estado='Completado', # O el estado que corresponda
            # area no está en el modelo NotaSalida
        )

        detalles_data = nota_data['detalles']
        for detalle_data in detalles_data:
            id_inventario = detalle_data['id_inventario']
            cantidad_solicitada = detalle_data['cantidad']

            try:
                inventario_item = Inventario.objects.get(id_inventario=id_inventario)
            except Inventario.DoesNotExist:
                raise serializers.ValidationError(f"El item de inventario con id {id_inventario} no existe.")

            nombre_materia = inventario_item.nombre_materia_prima
            unidad = inventario_item.unidad_medida
            
            # 🔹 Obtener el id_materia para buscar los lotes
            try:
                materia = MateriaPrima.objects.get(nombre=nombre_materia)
                id_materia = materia.id_materia
            except MateriaPrima.DoesNotExist:
                raise serializers.ValidationError(f"No se encontró la materia prima {nombre_materia}")
            
            # Obtener lotes disponibles con cantidad > 0, ordenados por id (FIFO)
            lotes_disponibles = Lote.objects.filter(
                id_materia=id_materia,
                cantidad__gt=0
            ).order_by('id_lote')
            
            # Verificar stock total disponible
            stock_total = sum(lote.cantidad for lote in lotes_disponibles)
            if stock_total < cantidad_solicitada:
                raise serializers.ValidationError(
                    f"Stock insuficiente para {nombre_materia}. Solicitado: {cantidad_solicitada}, Disponible: {stock_total}"
                )
            
            # 🔹 Consumir de los lotes disponibles (FIFO)
            cantidad_restante = cantidad_solicitada
            for lote in lotes_disponibles:
                if cantidad_restante <= 0:
                    break
                
                # ✅ Asegurar que no se descuente más de lo disponible
                cantidad_a_consumir = min(lote.cantidad, cantidad_restante)
                
                # Solo procesar si hay algo que consumir
                if cantidad_a_consumir <= 0:
                    continue
                
                # Crear el detalle de la nota de salida para este lote
                DetalleNotaSalida.objects.create(
                    id_salida=nota.id_salida,
                    id_lote=lote.id_lote,
                    nombre_materia_prima=nombre_materia,
                    cantidad=cantidad_a_consumir,
                    unidad_medida=unidad
                )
                
                # 🔹 Descontar de la tabla LOTES
                lote.cantidad -= cantidad_a_consumir
                if lote.cantidad < 0:
                    lote.cantidad = 0
                lote.save()
                
                # 🔹 Descontar del INVENTARIO total
                inventario_item.cantidad_actual -= cantidad_a_consumir
                if inventario_item.cantidad_actual < 0:
                    inventario_item.cantidad_actual = 0
                inventario_item.save()
                
                # 🔹 REGISTRAR TRAZABILIDAD DE LOTE
                # Obtener información del personal
                try:
                    persona = personal.objects.get(id=nota_data['id_personal'])
                    nombre_usuario = persona.nombre_completo
                except personal.DoesNotExist:
                    nombre_usuario = "N/A"
                
                TrazabilidadLote.objects.create(
                    id_lote=lote.id_lote,
                    id_materia=id_materia,
                    nombre_materia=nombre_materia,
                    codigo_lote=lote.codigo_lote,
                    cantidad_consumida=cantidad_a_consumir,
                    unidad_medida=unidad,
                    tipo_operacion='nota_salida',
                    id_operacion=nota.id_salida,
                    codigo_operacion=f"NS-{nota.id_salida}",
                    fecha_consumo=datetime.now(),
                    id_usuario=nota_data['id_personal'],
                    nombre_usuario=nombre_usuario
                )
                
                cantidad_restante -= cantidad_a_consumir

        return Response({'mensaje': 'Nota de salida creada correctamente', 'id_salida': nota.id_salida}, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
def listar_notas_salida(request):
    notas = NotaSalida.objects.all()
    
    # Enriquecer cada nota con información del personal
    notas_data = []
    for nota in notas:
        nota_dict = {
            'id_salida': nota.id_salida,
            'fecha_salida': nota.fecha_salida,
            'motivo': nota.motivo,
            'estado': nota.estado,
            'id_personal': nota.id_personal
        }
        
        # Obtener información del personal
        try:
            persona = personal.objects.get(id=nota.id_personal)
            nota_dict['solicitante'] = persona.nombre_completo
            nota_dict['area'] = persona.rol
        except personal.DoesNotExist:
            nota_dict['solicitante'] = 'N/A'
            nota_dict['area'] = 'N/A'
        
        notas_data.append(nota_dict)
    
    return Response(notas_data, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = NotaSalidaSerializer(nota)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🔹 REGISTRAR NOTA DE SALIDA USANDO id_usuario DESDE LA URL
@api_view(['POST'])
def registrar_nota_salida(request, id_usuario):
    serializer = RegistrarNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        # Buscar el personal asociado al usuario
        try:
            persona = personal.objects.get(id_usuario=id_usuario)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal asociado al usuario con id {id_usuario}'},
                            status=status.HTTP_400_BAD_REQUEST)

        # Crear la nota de salida
        nota = NotaSalida.objects.create(
            fecha_salida=serializer.validated_data['fecha_salida'],
            motivo=serializer.validated_data['motivo'],
            estado=serializer.validated_data['estado'],
            id_personal=persona.id
        )

        return Response(
            {'mensaje': 'Nota de salida registrada correctamente', 'id_salida': nota.id_salida},
            status=status.HTTP_201_CREATED
        )

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PUT'])
def actualizar_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    serializer = RegistrarNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        for campo, valor in serializer.validated_data.items():
            setattr(nota, campo, valor)
        nota.save()
        return Response({'mensaje': 'Nota de salida actualizada correctamente'}, status=status.HTTP_200_OK)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def eliminar_nota_salida(request, id_salida):
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)

    nota.delete()
    return Response({'mensaje': 'Nota de salida eliminada correctamente'}, status=status.HTTP_204_NO_CONTENT)


# ============================================================
# 🟢 CRUD DETALLE NOTA SALIDA
# ============================================================

@api_view(['GET'])
def listar_detalles_salida(request, id_salida):
    """
    Lista los detalles de una nota de salida con información adicional
    """
    # Obtener la nota de salida para información adicional
    try:
        nota = NotaSalida.objects.get(id_salida=id_salida)
        try:
            persona = personal.objects.get(id=nota.id_personal)
            solicitante = persona.nombre_completo
            area = persona.rol
        except personal.DoesNotExist:
            solicitante = "N/A"
            area = "N/A"
    except NotaSalida.DoesNotExist:
        return Response({'error': 'Nota de salida no encontrada'}, status=status.HTTP_404_NOT_FOUND)
    
    # Obtener detalles
    detalles = DetalleNotaSalida.objects.filter(id_salida=id_salida)
    
    # Serializar detalles
    serializer = DetalleNotaSalidaSerializer(detalles, many=True)
    
    # Agregar información adicional a la respuesta
    return Response({
        'fecha': nota.fecha_salida,
        'motivo': nota.motivo,
        'solicitante': solicitante,
        'area': area,
        'estado': nota.estado,
        'detalles': serializer.data,
        'total_items': len(serializer.data)
    }, status=status.HTTP_200_OK)


@api_view(['GET'])
def obtener_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)
    
    serializer = DetalleNotaSalidaSerializer(detalle)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 REGISTRAR DETALLE DE NOTA DE SALIDA (recibe id_salida por URL)
@api_view(['POST'])
def registrar_detalle_salida(request, id_salida):
    serializer = RegistrarDetalleNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        cod_lote = serializer.validated_data['cod_lote']
        cantidad_salida = serializer.validated_data['cantidad']
        unidad_medida = serializer.validated_data['unidad_medida']

        # ✅ Verificar que la nota de salida exista
        try:
            nota = NotaSalida.objects.get(id_salida=id_salida)
        except NotaSalida.DoesNotExist:
            return Response({'error': f'No existe una nota de salida con id {id_salida}'},status=status.HTTP_400_BAD_REQUEST)

        # ✅ Buscar lote por su código
        try:
            lote = Lote.objects.get(codigo_lote=cod_lote)
        except Lote.DoesNotExist:
            return Response({'error': f'No existe un lote con código "{cod_lote}"'},
                            status=status.HTTP_400_BAD_REQUEST)

        # ✅ Obtener materia prima asociada al lote
        try:
            materia = MateriaPrima.objects.get(id_materia=lote.id_materia)
        except MateriaPrima.DoesNotExist:
            return Response({'error': f'No existe materia prima asociada al lote "{cod_lote}"'},
                            status=status.HTTP_400_BAD_REQUEST)

        # ✅ Crear el detalle de nota de salida
        DetalleNotaSalida.objects.create(
            id_salida=id_salida,
            id_lote=lote.id_lote,
            nombre_materia_prima=materia.nombre,
            cantidad=cantidad_salida,
            unidad_medida=unidad_medida
        )

        # ✅ Actualizar inventario restando la cantidad
        try:
            inventario = Inventario.objects.get(id_lote=lote.id_lote)
            inventario.cantidad_actual -= cantidad_salida
            inventario.save()
        except Inventario.DoesNotExist:
            pass  # Si no existe, no se hace nada

        return Response({'mensaje': 'Detalle de nota de salida registrado correctamente'},
                        status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['PUT'])
def actualizar_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    serializer = DetalleNotaSalidaSerializer(data=request.data)
    if serializer.is_valid():
        for campo, valor in serializer.validated_data.items():
            setattr(detalle, campo, valor)
        detalle.save()
        return Response({'mensaje': 'Detalle actualizado correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


@api_view(['DELETE'])
def eliminar_detalle_salida(request, id_detalle):
    try:
        detalle = DetalleNotaSalida.objects.get(id_detalle=id_detalle)
    except DetalleNotaSalida.DoesNotExist:
        return Response({'error': 'Detalle no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    detalle.delete()
    return Response({'mensaje': 'Detalle eliminado correctamente'}, status=status.HTTP_204_NO_CONTENT)
