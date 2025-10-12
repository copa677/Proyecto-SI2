export interface DetalleNotaSalida {
  id_detalle?: number;
  id_salida: number;
  id_lote: number;
  nombre_materia_prima: string;
  cantidad: number;
  unidad_medida: string;
}
