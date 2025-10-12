export interface NotaSalida {
  id_salida?: number;
  fecha_salida: string;  // formato ISO: '2025-10-12'
  motivo: string;
  estado: string;
  id_personal?: number;
}
