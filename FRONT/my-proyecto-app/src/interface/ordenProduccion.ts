
export interface OrdenProduccion {
  id_orden?: number;           // opcional al insertar
  cod_orden: string;
  fecha_inicio: string;        // formato YYYY-MM-DD
  fecha_fin: string;           // formato YYYY-MM-DD
  fecha_entrega: string;       // formato YYYY-MM-DD
  estado: string;
  producto_modelo: string;
  color: string;
  talla: string;
  cantidad_total: number;
  id_personal: number;
}
