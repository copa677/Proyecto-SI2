export interface Lote {
  id_lote?: number;           // opcional al insertar
  codigo_lote: string;
  fecha_recepcion: string;    // formato YYYY-MM-DD
  cantidad: number;
  estado: string;
  id_materia: number;         // FK hacia MateriaPrima
}
