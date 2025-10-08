// src/app/interface/bitacora.ts
export interface Bitacora {
  id_bitacora?: number;   // opcional al registrar
  username: string;
  ip: string;
  fecha_hora: string;     // formato ISO (YYYY-MM-DDTHH:mm:ss)
  accion: string;
  descripcion: string;
}
