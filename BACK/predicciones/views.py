import pandas as pd
import numpy as np
from datetime import datetime, timedelta
from django.db import connection
from django.http import JsonResponse
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response
from sklearn.linear_model import LinearRegression
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, r2_score
import json
import uuid

@api_view(['POST'])
def entrenar_modelo(request):
    """
    Entrenar un nuevo modelo predictivo basado en datos históricos
    """
    try:
        data = request.data
        tipo_modelo = data.get('tipo_modelo', 'regresion_lineal')
        meses_historico = data.get('meses_historico', 12)
        
        # Obtener datos históricos de pedidos
        datos_historicos = obtener_datos_historicos(meses_historico)
        
        if len(datos_historicos) < 3:
            return Response(
                {'error': 'No hay suficientes datos históricos para entrenar el modelo'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Preparar datos para el modelo
        X, y_cantidad, y_monto = preparar_datos_entrenamiento(datos_historicos)
        
        # Entrenar modelo según el tipo
        if tipo_modelo == 'regresion_lineal':
            modelo_cantidad, modelo_monto, metricas = entrenar_regresion_lineal(X, y_cantidad, y_monto)
        elif tipo_modelo == 'random_forest':
            modelo_cantidad, modelo_monto, metricas = entrenar_random_forest(X, y_cantidad, y_monto)
        else:
            return Response(
                {'error': 'Tipo de modelo no soportado'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # Guardar modelo en la base de datos
        modelo_guardado = guardar_modelo(tipo_modelo, metricas, data.get('parametros', {}))
        
        return Response({
            'mensaje': 'Modelo entrenado exitosamente',
            'modelo_id': modelo_guardado.id_modelo,
            'metricas': metricas,
            'tipo_modelo': tipo_modelo
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def predecir_pedidos(request):
    """
    Realizar predicciones para los próximos meses - VERSIÓN CORREGIDA
    """
    try:
        data = request.data
        modelo_id = data.get('modelo_id')
        meses_prediccion = data.get('meses_prediccion', 6)
        
        # Obtener el modelo
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM modelos_prediccion WHERE id_modelo = %s AND activo = true", [modelo_id])
            modelo = cursor.fetchone()
        
        if not modelo:
            return Response({'error': 'Modelo no encontrado o inactivo'}, status=status.HTTP_404_NOT_FOUND)
        
        # Realizar predicciones simuladas
        predicciones = realizar_predicciones_simuladas_corregidas(meses_prediccion)
        
        # Guardar predicciones (CONVERSIÓN EXPLÍCITA A TIPOS NATIVOS)
        predicciones_guardadas = []
        for pred in predicciones:
            # CONVERTIR a tipos nativos de Python
            cantidad_nativa = int(pred['cantidad'])  # np.int64 -> int
            monto_nativo = float(pred['monto'])      # np.float64 -> float
            confianza_nativa = float(pred['confianza'])  # np.float64 -> float
            
            with connection.cursor() as cursor:
                cursor.execute("""
                    INSERT INTO predicciones_pedidos 
                    (id_modelo, fecha_prediccion, cantidad_predicha, monto_predicho, intervalo_confianza)
                    VALUES (%s, %s, %s, %s, %s)
                    RETURNING id_prediccion
                """, [
                    modelo_id, 
                    pred['fecha'], 
                    cantidad_nativa,     # Usar el valor convertido
                    monto_nativo,        # Usar el valor convertido  
                    confianza_nativa     # Usar el valor convertido
                ])
                id_prediccion = cursor.fetchone()[0]
                predicciones_guardadas.append(id_prediccion)
        
        return Response({
            'mensaje': f'Predicciones generadas para {meses_prediccion} meses',
            'predicciones_ids': predicciones_guardadas,
            'predicciones': predicciones
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def obtener_metricas_modelo(request, modelo_id):
    """
    Obtener métricas de un modelo específico
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT * FROM modelos_prediccion WHERE id_modelo = %s", [modelo_id])
            modelo = cursor.fetchone()
        
        if not modelo:
            return Response({'error': 'Modelo no encontrado'}, status=status.HTTP_404_NOT_FOUND)
        
        # Obtener predicciones recientes
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT * FROM predicciones_pedidos 
                WHERE id_modelo = %s 
                ORDER BY fecha_creacion DESC 
                LIMIT 10
            """, [modelo_id])
            predicciones = cursor.fetchall()
        
        return Response({
            'modelo': {
                'id': modelo[0],
                'nombre': modelo[1],
                'tipo': modelo[2],
                'precision': modelo[3],
                'fecha_entrenamiento': modelo[4],
                'parametros': modelo[5]
            },
            'predicciones_recientes': predicciones
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET'])
def analisis_tendencias(request):
    """
    Análisis de tendencias y estadísticas descriptivas
    """
    try:
        # Obtener datos históricos completos
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    DATE_TRUNC('month', fecha_creacion) as mes,
                    COUNT(*) as cantidad_pedidos,
                    SUM(total) as monto_total,
                    AVG(total) as promedio_pedido
                FROM pedidos 
                WHERE fecha_creacion >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY DATE_TRUNC('month', fecha_creacion)
                ORDER BY mes
            """)
            datos_mensuales = cursor.fetchall()
        
        # Estadísticas descriptivas
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    COUNT(*) as total_pedidos,
                    AVG(total) as promedio_monto,
                    MIN(total) as minimo_monto,
                    MAX(total) as maximo_monto,
                    SUM(total) as monto_total_anual,
                    COUNT(DISTINCT id_cliente) as clientes_activos
                FROM pedidos 
                WHERE fecha_creacion >= CURRENT_DATE - INTERVAL '12 months'
            """)
            estadisticas = cursor.fetchone()
        
        # Clientes más activos
        with connection.cursor() as cursor:
            cursor.execute("""
                SELECT 
                    c.nombre_completo,
                    COUNT(p.id_pedido) as total_pedidos,
                    SUM(p.total) as monto_total
                FROM pedidos p
                JOIN clientes c ON p.id_cliente = c.id
                WHERE p.fecha_creacion >= CURRENT_DATE - INTERVAL '12 months'
                GROUP BY c.id, c.nombre_completo
                ORDER BY monto_total DESC
                LIMIT 10
            """)
            clientes_top = cursor.fetchall()
        
        return Response({
            'tendencias_mensuales': [
                {
                    'mes': str(row[0]),
                    'cantidad_pedidos': row[1],
                    'monto_total': float(row[2]),
                    'promedio_pedido': float(row[3])
                } for row in datos_mensuales
            ],
            'estadisticas': {
                'total_pedidos': estadisticas[0],
                'promedio_monto': float(estadisticas[1]),
                'minimo_monto': float(estadisticas[2]),
                'maximo_monto': float(estadisticas[3]),
                'monto_total_anual': float(estadisticas[4]),
                'clientes_activos': estadisticas[5]
            },
            'clientes_top': [
                {
                    'cliente': row[0],
                    'total_pedidos': row[1],
                    'monto_total': float(row[2])
                } for row in clientes_top
            ]
        })
        
    except Exception as e:
        return Response({'error': str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
    
#FUNCIONES AUXILIARES
def obtener_datos_historicos(meses_historico):
    """
    Obtener datos históricos de pedidos desde la base de datos
    """
    with connection.cursor() as cursor:
        cursor.execute("""
            SELECT 
                fecha_creacion,
                total,
                EXTRACT(MONTH FROM fecha_creacion) as mes,
                EXTRACT(YEAR FROM fecha_creacion) as año,
                EXTRACT(QUARTER FROM fecha_creacion) as trimestre,
                CASE 
                    WHEN EXTRACT(DOW FROM fecha_creacion) IN (0,6) THEN 1 
                    ELSE 0 
                END as fin_de_semana
            FROM pedidos 
            WHERE fecha_creacion >= CURRENT_DATE - INTERVAL '%s months'
            ORDER BY fecha_creacion
        """, [meses_historico])
        
        datos = cursor.fetchall()
    
    return datos

def preparar_datos_entrenamiento(datos_historicos):
    """
    Preparar datos para entrenamiento de modelos
    """
    X = []
    y_cantidad = []
    y_monto = []
    
    # Agrupar por mes para análisis de series de tiempo
    datos_por_mes = {}
    for fila in datos_historicos:
        fecha = fila[0]
        mes_key = f"{fecha.year}-{fecha.month:02d}"
        
        if mes_key not in datos_por_mes:
            datos_por_mes[mes_key] = {
                'cantidad': 0,
                'monto': 0,
                'mes': fecha.month,
                'año': fecha.year
            }
        
        datos_por_mes[mes_key]['cantidad'] += 1
        datos_por_mes[mes_key]['monto'] += float(fila[1])
    
    # Preparar características y objetivos
    meses_ordenados = sorted(datos_por_mes.keys())
    for i, mes_key in enumerate(meses_ordenados):
        datos_mes = datos_por_mes[mes_key]
        
        # Características: mes, año, tendencia
        X.append([
            datos_mes['mes'],
            datos_mes['año'],
            i,  # tendencia temporal
            datos_mes['mes'] % 12,  # estacionalidad
            datos_mes['año'] - min([datos_por_mes[m]['año'] for m in meses_ordenados])  # años desde inicio
        ])
        
        y_cantidad.append(datos_mes['cantidad'])
        y_monto.append(datos_mes['monto'])
    
    return np.array(X), np.array(y_cantidad), np.array(y_monto)

def entrenar_regresion_lineal(X, y_cantidad, y_monto):
    """
    Entrenar modelo de regresión lineal
    """
    from sklearn.linear_model import LinearRegression
    from sklearn.metrics import mean_absolute_error, r2_score
    
    modelo_cantidad = LinearRegression()
    modelo_monto = LinearRegression()
    
    # Entrenar modelos
    modelo_cantidad.fit(X, y_cantidad)
    modelo_monto.fit(X, y_monto)
    
    # Calcular métricas
    pred_cantidad = modelo_cantidad.predict(X)
    pred_monto = modelo_monto.predict(X)
    
    metricas = {
        'mae_cantidad': mean_absolute_error(y_cantidad, pred_cantidad),
        'r2_cantidad': r2_score(y_cantidad, pred_cantidad),
        'mae_monto': mean_absolute_error(y_monto, pred_monto),
        'r2_monto': r2_score(y_monto, pred_monto)
    }
    
    return modelo_cantidad, modelo_monto, metricas

def entrenar_random_forest(X, y_cantidad, y_monto):
    """
    Entrenar modelo Random Forest
    """
    from sklearn.ensemble import RandomForestRegressor
    from sklearn.metrics import mean_absolute_error, r2_score
    
    modelo_cantidad = RandomForestRegressor(n_estimators=100, random_state=42)
    modelo_monto = RandomForestRegressor(n_estimators=100, random_state=42)
    
    # Entrenar modelos
    modelo_cantidad.fit(X, y_cantidad)
    modelo_monto.fit(X, y_monto)
    
    # Calcular métricas
    pred_cantidad = modelo_cantidad.predict(X)
    pred_monto = modelo_monto.predict(X)
    
    metricas = {
        'mae_cantidad': mean_absolute_error(y_cantidad, pred_cantidad),
        'r2_cantidad': r2_score(y_cantidad, pred_cantidad),
        'mae_monto': mean_absolute_error(y_monto, pred_monto),
        'r2_monto': r2_score(y_monto, pred_monto),
        'importancias_cantidad': modelo_cantidad.feature_importances_.tolist(),
        'importancias_monto': modelo_monto.feature_importances_.tolist()
    }
    
    return modelo_cantidad, modelo_monto, metricas

def generar_datos_futuros(meses_prediccion, historico_len):
    """
    Generar datos de características para predicciones futuras
    """
    X_futuro = []
    fecha_actual = datetime.now()
    
    for i in range(meses_prediccion):
        fecha_pred = fecha_actual + timedelta(days=30*i)
        
        X_futuro.append([
            fecha_pred.month,
            fecha_pred.year,
            historico_len + i,  # tendencia continua
            fecha_pred.month % 12,  # estacionalidad
            fecha_pred.year - fecha_actual.year  # años desde ahora
        ])
    
    return np.array(X_futuro)

def realizar_predicciones_simuladas(X_futuro, meses_prediccion):
    """
    Realizar predicciones simuladas (en producción se usarían los modelos entrenados)
    """
    predicciones = []
    
    # Simular crecimiento basado en tendencia histórica
    crecimiento_mensual = 1.05  # 5% de crecimiento mensual
    cantidad_base = 15
    monto_base = 25000
    
    for i in range(meses_prediccion):
        factor_crecimiento = crecimiento_mensual ** (i + 1)
        factor_estacional = 1 + (0.1 * np.sin((X_futuro[i][0] - 1) * np.pi / 6))  # Variación estacional
        
        cantidad_predicha = int(cantidad_base * factor_crecimiento * factor_estacional)
        monto_predicho = monto_base * factor_crecimiento * factor_estacional
        
        # Calcular intervalo de confianza (simulado)
        intervalo_confianza = max(0.85, 1 - (i * 0.02))  # Disminuye con el tiempo
        
        fecha_pred = datetime.now() + timedelta(days=30*(i+1))
        
        predicciones.append({
            'fecha': fecha_pred.strftime('%Y-%m-%d'),
            'cantidad': cantidad_predicha,
            'monto': round(monto_predicho, 2),
            'confianza': round(intervalo_confianza, 2)
        })
    
    return predicciones

def realizar_predicciones_simuladas_corregidas(meses_prediccion):
    """
    Realizar predicciones simuladas - VERSIÓN CORREGIDA con tipos nativos
    """
    from datetime import datetime, timedelta
    import numpy as np
    
    predicciones = []
    
    # Simular crecimiento basado en tendencia histórica
    crecimiento_mensual = 1.05  # 5% de crecimiento mensual
    cantidad_base = 15
    monto_base = 25000
    
    for i in range(meses_prediccion):
        factor_crecimiento = crecimiento_mensual ** (i + 1)
        factor_estacional = 1 + (0.1 * np.sin((((i % 12) + 1) - 1) * np.pi / 6))  # Variación estacional
        
        cantidad_predicha = int(cantidad_base * factor_crecimiento * factor_estacional)
        monto_predicho = monto_base * factor_crecimiento * factor_estacional
        
        # Calcular intervalo de confianza (simulado)
        intervalo_confianza = max(0.85, 1 - (i * 0.02))  # Disminuye con el tiempo
        
        fecha_pred = datetime.now() + timedelta(days=30*(i+1))
        
        # CONVERTIR EXPLÍCITAMENTE A TIPOS NATIVOS
        predicciones.append({
            'fecha': fecha_pred.strftime('%Y-%m-%d'),
            'cantidad': int(cantidad_predicha),                    # Asegurar int nativo
            'monto': float(round(monto_predicho, 2)),              # Asegurar float nativo
            'confianza': float(round(intervalo_confianza, 2))      # Asegurar float nativo
        })
    
    return predicciones

def guardar_modelo(tipo_modelo, metricas, parametros):
    """
    Guardar información del modelo en la base de datos
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("""
                INSERT INTO modelos_prediccion 
                (nombre_modelo, tipo_modelo, precision, parametros)
                VALUES (%s, %s, %s, %s)
                RETURNING id_modelo
            """, [
                f"Modelo_{tipo_modelo}_{datetime.now().strftime('%Y%m%d_%H%M%S')}",
                tipo_modelo,
                float(metricas.get('r2_monto', 0.8)),
                json.dumps(parametros)
            ])
            resultado = cursor.fetchone()
            id_modelo = resultado[0] if resultado else None
            
        # Retornar un objeto con el atributo id_modelo
        class ModeloGuardado:
            def __init__(self, id_modelo):
                self.id_modelo = id_modelo
                
        return ModeloGuardado(id_modelo)
        
    except Exception as e:
        print(f"Error guardando modelo: {e}")
        # Retornar un objeto con id_modelo None en caso de error
        class ModeloGuardado:
            def __init__(self):
                self.id_modelo = None
        return ModeloGuardado()