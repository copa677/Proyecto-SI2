import { Component, OnInit } from '@angular/core';

interface ActividadItem {
  titulo: string;
  detalle: string;
  hace: string;
}

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit {

  // KPIs demo (en memoria, como en tus otras vistas)
  kpis = {
    totalPersonal: 12,
    asistenciaHoy: 8,
    usuarios: 5,
    ordenes: 9,
    inventarioCritico: 3,
    eficiencia: 0.92
  };

  actividad: ActividadItem[] = [
    { titulo: 'Registro de usuario', detalle: 'Juan Pérez se ha registrado en el sistema', hace: 'hace 2 horas' },
    { titulo: 'Modificación de datos', detalle: 'Se actualizaron datos del personal', hace: 'hace 5 horas' },
    { titulo: 'Registro de asistencia', detalle: '8 miembros del personal registraron asistencia', hace: 'hoy, 8:00 AM' }
  ];

  get asistenciaPct(): number {
    if (!this.kpis.totalPersonal) { return 0; }
    return (this.kpis.asistenciaHoy / this.kpis.totalPersonal) * 100;
  }

  ngOnInit(): void {
    // Aquí podrías llamar a tu API (Django) para traer KPIs reales.
    // this.dashboardService.getKpis().subscribe(k => this.kpis = k);
  }
}
