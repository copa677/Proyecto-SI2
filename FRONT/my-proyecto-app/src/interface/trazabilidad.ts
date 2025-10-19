export interface Trazabilidad {
    // Fields for trazabilidad component
    id_trazabilidad?: number;
    proceso: string;
    descripcion_proceso: string;
    fecha_registro: string;
    hora_inicio: string;
    hora_fin: string;
    cantidad: number;
    estado: string;
    id_personal: number;
    id_orden: number;

    // Fields for control-calidad component (as optional)
    id_lote?: number;
    nombre_lote?: string;
    tipo_proceso?: string; // This seems to be the same as 'proceso'
    responsable?: string;
    fecha_inicio?: Date;
    fecha_fin?: Date;
}