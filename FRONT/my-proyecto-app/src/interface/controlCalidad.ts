export interface ControlCalidad {
  id_control?: number;         // opcional al crear
  observaciones: string;
  resultado: string;
  fehca_hora: string;          // formato ISO: 'YYYY-MM-DDTHH:mm:ss'
  nombre_personal: string;     // se envía el nombre, no el id
  id_trazabilidad: number;
}
