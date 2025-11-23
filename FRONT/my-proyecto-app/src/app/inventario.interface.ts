export interface Inventario {
  id_inventario: number;
  nombre_materia_prima: string;
  cantidad_actual: number;
  unidad_medida: string;
  ubicacion: string;
  estado: string;
  fecha_actualizacion: string; // ISO string
  id_lote: number;
  stock_minimo: number; // <-- Nuevo campo
}
