import { Component } from '@angular/core';

type Lote = 'personal' | 'asistencia' | 'usuarios';

@Component({
  selector: 'app-configuracion',
  templateUrl: './configuracion.component.html',
  styleUrls: ['./configuracion.component.css']
})
export class ConfiguracionComponent {

  // Archivos seleccionados para importar
  files: Partial<Record<Lote, File>> = {};

  // Preferencias del sistema (demo en memoria)
  prefs = {
    notificaciones: true,
    darkMode: false,
    idioma: 'es'
  };

  // Toast simple
  toast = { show: false, msg: '' as string };
  private toastTimer: any;

  // === Exportación (demo CSV) ===
  exportar(tipo: Lote) {
    const csv = this.csvDemo(tipo);
    const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
    const a = document.createElement('a');
    a.href = URL.createObjectURL(blob);
    a.download = `export_${tipo}.csv`;
    a.click();
    URL.revokeObjectURL(a.href);
    this.ok(`Exportado ${tipo} (demo)`);
  }

  // === Importación ===
  onFileSelected(tipo: Lote, ev: Event) {
    const input = ev.target as HTMLInputElement | null;
    const file = input?.files && input.files[0] ? input.files[0] : undefined;
    if (file) {
      this.files[tipo] = file;
      this.ok(`Archivo seleccionado (${tipo}): ${file.name}`);
    }
  }

  importarSeleccionados() {
    const lotes = (Object.keys(this.files) as Lote[]).filter(k => !!this.files[k]);
    if (!lotes.length) {
      this.warn('No hay archivos seleccionados');
      return;
    }
    // Aquí harías upload al backend. Demo:
    this.ok(`Importación en curso: ${lotes.join(', ')}`);
    // Limpieza demo
    setTimeout(() => {
      this.files = {};
      this.ok('Importación finalizada (demo)');
    }, 800);
  }

  // === Preferencias ===
  guardarPreferencias() {
    // Aquí llamarías a tu API para persistir prefs
    this.ok('Preferencias guardadas');
    // Demo: aplicar darkMode al <html> si quieres
    document.documentElement.classList.toggle('dark', this.prefs.darkMode);
  }

  // === Utilidades ===
  private csvDemo(tipo: Lote): string {
    if (tipo === 'personal') {
      return `id,nombre,email,rol
1,Juan Pérez,juan@ejemplo.com,Supervisor
2,María González,maria@ejemplo.com,Operario`;
    }
    if (tipo === 'asistencia') {
      return `fecha,nombre,turno,estado
2025-04-16,Juan Pérez,Mañana,Presente
2025-04-16,María González,Tarde,Ausente`;
    }
    return `id,nombre,email,tipo,estado
1,Admin Usuario,admin@ejemplo.com,Administrador,Activo
2,Juan Pérez,juan@ejemplo.com,Supervisor,Activo`;
  }

  private ok(msg: string)   { this.toastMsg(msg); }
  private warn(msg: string) { this.toastMsg(msg); }

  private toastMsg(msg: string) {
    this.toast.msg = msg;
    this.toast.show = true;
    clearTimeout(this.toastTimer);
    this.toastTimer = setTimeout(() => this.toast.show = false, 1800);
  }
}
