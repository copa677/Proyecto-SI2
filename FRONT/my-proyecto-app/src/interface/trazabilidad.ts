export interface Trazabilidad {
  id_trazabilidad?: number;      // opcional al crear
  proceso: string;
  descripcion_proceso: string;
  fecha_registro: string;        // formato: YYYY-MM-DDTHH:mm:ss
  hora_inicio: string;           // formato: HH:mm:ss
  hora_fin: string;              // formato: HH:mm:ss
  cantidad: number;
  estado: string;
  id_personal?: number;          // o nombre_personal, según uso
  id_orden: number;
}
