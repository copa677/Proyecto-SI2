export interface Inventario {
  id_inventario?: number;
  nombre_materia_prima: string;
  cantidad_actual: number;
  unidad_medida: string;
  ubicacion: string;
  estado: string;
  fecha_actualizacion: string;  // ISO string, ej: '2025-10-12T10:30:00Z'
  id_lote: number;
}
