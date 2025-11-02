from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import ControlCalidad
from .serializers import ControlCalidadSerializer, InsertarControlCalidadSerializer
from personal.models import personal   # Importamos el modelo personal


# 🟢 LISTAR TODOS LOS CONTROLES DE CALIDAD
@api_view(['GET'])
def listar_controles_calidad(request):
    controles = ControlCalidad.objects.all()
    serializer = ControlCalidadSerializer(controles, many=True)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 OBTENER UN CONTROL DE CALIDAD POR ID
@api_view(['GET'])
def obtener_control_calidad(request, id_control):
    try:
        control = ControlCalidad.objects.get(id_control=id_control)
    except ControlCalidad.DoesNotExist:
        return Response({'error': 'Control de calidad no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    serializer = ControlCalidadSerializer(control)
    return Response(serializer.data, status=status.HTTP_200_OK)


# 🟢 INSERTAR NUEVO CONTROL DE CALIDAD (usando nombre del personal)
@api_view(['POST'])
def insertar_control_calidad(request):
    serializer = InsertarControlCalidadSerializer(data=request.data)
    if serializer.is_valid():
        id_personal = serializer.validated_data.get('id_personal')

        # Verificar que el personal existe
        try:
            persona = personal.objects.get(id=id_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el id {id_personal}'}, status=status.HTTP_400_BAD_REQUEST)

        # Crear nuevo registro
        nuevo_control = ControlCalidad.objects.create(
            observaciones=serializer.validated_data['observaciones'],
            resultado=serializer.validated_data['resultado'],
            fecha_hora=serializer.validated_data['fecha_hora'],
            id_personal=persona.id,
            id_trazabilidad=serializer.validated_data['id_trazabilidad']
        )

        return Response({'mensaje': 'Control de calidad registrado correctamente'}, status=status.HTTP_201_CREATED)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ACTUALIZAR CONTROL DE CALIDAD EXISTENTE
@api_view(['PUT'])
def actualizar_control_calidad(request, id_control):
    try:
        control = ControlCalidad.objects.get(id_control=id_control)
    except ControlCalidad.DoesNotExist:
        return Response({'error': 'Control de calidad no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    serializer = InsertarControlCalidadSerializer(data=request.data)
    if serializer.is_valid():
        nombre_personal = serializer.validated_data.get('nombre_personal')

        try:
            persona = personal.objects.get(nombre_completo=nombre_personal)
        except personal.DoesNotExist:
            return Response({'error': f'No existe un personal con el nombre "{nombre_personal}"'}, status=status.HTTP_400_BAD_REQUEST)

        # Actualizar campos
        control.observaciones = serializer.validated_data['observaciones']
        control.resultado = serializer.validated_data['resultado']
        control.fecha_hora = serializer.validated_data['fecha_hora']
        control.id_personal = persona.id
        control.id_trazabilidad = serializer.validated_data['id_trazabilidad']
        control.save()

        return Response({'mensaje': 'Control de calidad actualizado correctamente'}, status=status.HTTP_200_OK)

    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


# 🟢 ELIMINAR CONTROL DE CALIDAD
@api_view(['DELETE'])
def eliminar_control_calidad(request, id_control):
    try:
        control = ControlCalidad.objects.get(id_control=id_control)
    except ControlCalidad.DoesNotExist:
        return Response({'error': 'Control de calidad no encontrado'}, status=status.HTTP_404_NOT_FOUND)

    control.delete()
    return Response({'mensaje': 'Control de calidad eliminado correctamente'}, status=status.HTTP_204_NO_CONTENT)
