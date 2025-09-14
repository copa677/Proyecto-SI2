
export interface Empleado{
    id_personal?: number;
    nombre_completo: string;
    direccion: string;
    telefono: string;
    rol: string;
    fecha_nacimiento: Date;
    estado: string;
    username?: string;
    email?:string;
    id_usuario?: number;
}