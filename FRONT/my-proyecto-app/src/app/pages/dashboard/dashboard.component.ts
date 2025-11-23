import { Component, OnInit, OnDestroy } from '@angular/core';
import { ActivatedRoute, Router } from '@angular/router';
import { Chart, registerables } from 'chart.js';
import { DashboardService, DashboardData, OrdenReciente, ProductoCritico } from 'src/app/services_back/dashboard.service';
import { ToastrService } from 'ngx-toastr';
import { Subscription } from 'rxjs';
import { KPIs } from 'src/app/services_back/dashboard.service';
import { PrediccionesService, AnalisisTendencias, PrediccionPedido } from 'src/app/services_back/predicciones.service';

@Component({
  selector: 'app-dashboard',
  templateUrl: './dashboard.component.html',
  styleUrls: ['./dashboard.component.css']
})
export class DashboardComponent implements OnInit, OnDestroy {

  // Propiedades para los datos del dashboard
  summaryData: DashboardData | null = null;
  ordenesRecientes: OrdenReciente[] = [];
  productosCriticos: ProductoCritico[] = [];
  // KPIs directos para facilitar el acceso
  kpis: KPIs | null = null;

  // Datos de predicciones
  analisisTendencias: AnalisisTendencias | null = null;
  prediccionesFuturas: PrediccionPedido[] = [];
  mesesPrediccion: number = 6; // Número de meses a predecir (configurable)
  loadingPredicciones = false;
  errorPredicciones = '';

  // Control de estados
  isLoading = true;
  errorMessage = '';
  errorAccesoDenegado = false;
  ventanaDenegada = '';

  // Modal de backup programado
  showBackupModal = false;
  backupDateTime: string = '';

  // Suscripciones y gráficos
  private dataSubscription: Subscription | undefined;
  private ordersChart: Chart | undefined;
  private activityChart: Chart | undefined;
  private prediccionesChart: Chart | undefined;
  private tendenciasChart: Chart | undefined;
  // Abrir modal de backup
  openBackupModal(): void {
    this.showBackupModal = true;
    this.backupDateTime = '';
  }

  // Cerrar modal de backup
  closeBackupModal(): void {
    this.showBackupModal = false;
    this.backupDateTime = '';
  }

  // Programar backup (enviar fecha/hora al backend)
  scheduleBackup(): void {
    if (!this.backupDateTime) return;
    // Aquí deberías llamar a un servicio que programe el backup en el backend
    // Ejemplo:
    // this.dashboardService.scheduleBackup(this.backupDateTime).subscribe(...)
    this.toastr.success('Backup programado para: ' + this.backupDateTime, 'Backup Programado');
    this.closeBackupModal();
  }

  constructor(
    private route: ActivatedRoute,
    private router: Router, // Añadido para navegación
    private dashboardService: DashboardService,
    private prediccionesService: PrediccionesService,
    private toastr: ToastrService
  ) {
    Chart.register(...registerables);
  }

  ngOnInit(): void {
    this.route.queryParams.subscribe(params => {
      if (params['error'] === 'acceso_denegado') {
        this.errorAccesoDenegado = true;
        this.ventanaDenegada = params['ventana'] || 'la sección solicitada';
        setTimeout(() => {
          this.errorAccesoDenegado = false;
        }, 5000);
      }
    });

    this.loadAllDashboardData();
    this.loadPrediccionesData();
  }

  ngOnDestroy(): void {
    this.dataSubscription?.unsubscribe();
    this.ordersChart?.destroy();
    this.activityChart?.destroy();
    this.prediccionesChart?.destroy();
    this.tendenciasChart?.destroy();
  }

  loadAllDashboardData(showToast: boolean = false): void {
    this.isLoading = true;
    this.errorMessage = '';

    // KPIs y actividad
    this.dataSubscription = this.dashboardService.getEstadisticas().subscribe({
      next: (data: DashboardData) => {
        this.summaryData = data;
        this.kpis = data.kpis;
        // Cargar órdenes recientes y productos críticos
        this.dashboardService.getOrdenesRecientes().subscribe({
          next: (ordenes: OrdenReciente[]) => {
            this.ordenesRecientes = ordenes;
          },
          error: () => {
            this.ordenesRecientes = [];
          }
        });
        this.dashboardService.getInventarioCritico().subscribe({
          next: (productos: ProductoCritico[]) => {
            this.productosCriticos = productos;
          },
          error: () => {
            this.productosCriticos = [];
          }
        });
        this.isLoading = false;
        if (showToast) {
          this.toastr.success('Datos del dashboard actualizados.', 'Éxito');
        }
        setTimeout(() => {
          this.createOrUpdateCharts();
        }, 0);
      },
      error: (error: any) => {
        this.errorMessage = 'Error al cargar los datos. Por favor, intente de nuevo.';
        this.isLoading = false;
        this.toastr.error(this.errorMessage, 'Error de Carga');
        console.error(error);
      }
    });
  }

  private createOrUpdateCharts(): void {
    if (this.ordersChart) this.ordersChart.destroy();
    if (this.activityChart) this.activityChart.destroy();
    this.createOrdersChart();
    this.createActivityChart();
    
    // Crear gráficos de predicciones si hay datos
    if (this.prediccionesFuturas.length > 0) {
      this.createPrediccionesChart();
    }
    if (this.analisisTendencias && this.analisisTendencias.tendencias_mensuales.length > 0) {
      this.createTendenciasChart();
    }
  }

  private createOrdersChart(): void {
    if (!this.ordenesRecientes || this.ordenesRecientes.length === 0) return;
    const ctx = document.getElementById('ordersChart') as HTMLCanvasElement;
    if (!ctx) return;

    // Agrupar órdenes por estado
    const estados: { [key: string]: number } = {};
    this.ordenesRecientes.forEach(o => {
      estados[o.estado] = (estados[o.estado] || 0) + 1;
    });
    
    // Colores más vibrantes y profesionales
    const colores = [
      'rgba(79, 70, 229, 0.8)',   // Indigo
      'rgba(16, 185, 129, 0.8)',  // Verde
      'rgba(245, 158, 11, 0.8)',  // Amarillo
      'rgba(239, 68, 68, 0.8)',   // Rojo
      'rgba(139, 92, 246, 0.8)',  // Púrpura
      'rgba(14, 165, 233, 0.8)'   // Azul
    ];
    
    const coloresBorde = [
      'rgba(79, 70, 229, 1)',
      'rgba(16, 185, 129, 1)',
      'rgba(245, 158, 11, 1)',
      'rgba(239, 68, 68, 1)',
      'rgba(139, 92, 246, 1)',
      'rgba(14, 165, 233, 1)'
    ];
    
    // Si solo hay un estado, asegúrate de que el color sea visible y el gráfico se dibuje correctamente
    let bgColors = colores.slice(0, Object.keys(estados).length);
    let borderColors = coloresBorde.slice(0, Object.keys(estados).length);
    if (Object.keys(estados).length === 1) {
      bgColors = ['rgba(79, 70, 229, 0.8)'];
      borderColors = ['rgba(79, 70, 229, 1)'];
    }
    this.ordersChart = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: Object.keys(estados),
        datasets: [{
          label: 'Órdenes',
          data: Object.values(estados),
          backgroundColor: bgColors,
          borderColor: borderColors,
          borderWidth: 3
        }]
      },
      options: { 
        responsive: true, 
        maintainAspectRatio: true,
        plugins: { 
          legend: { 
            position: 'bottom',
            labels: {
              padding: 15,
              font: {
                size: 12
              },
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const label = context.label || '';
                const value = context.parsed || 0;
                const total = context.dataset.data.reduce((a: number, b: number) => a + b, 0);
                const percentage = ((value / total) * 100).toFixed(1);
                return `${label}: ${value} (${percentage}%)`;
              }
            }
          }
        }
      }
    });
  }

  private createActivityChart(): void {
    // Método removido - ya no usamos este gráfico
  }

  // Navegación desde las tarjetas
  navigateTo(path: string): void {
    this.router.navigate([path]);
  }

  cerrarAlerta() {
    this.errorAccesoDenegado = false;
  }

  // Helper para formatear fechas
  formatDate(isoString: string): string {
    if (!isoString) return 'N/A';
    return new Date(isoString).toLocaleString('es-ES', { day: 'numeric', month: 'long', hour: '2-digit', minute: '2-digit' });
  }

  // Obtener número de estados únicos para el dashboard
  getEstadosUnicos(): number {
    if (!this.ordenesRecientes || this.ordenesRecientes.length === 0) return 0;
    const estadosSet = new Set(this.ordenesRecientes.map(o => o.estado));
    return estadosSet.size;
  }

  // ==================== MÉTODOS DE PREDICCIONES ====================

  /**
   * Cargar datos de predicciones y análisis de tendencias
   */
  loadPrediccionesData(): void {
    this.loadingPredicciones = true;
    this.errorPredicciones = '';

    // Cargar análisis de tendencias
    this.prediccionesService.getAnalisisTendencias().subscribe({
      next: (data) => {
        this.analisisTendencias = data;
        setTimeout(() => this.createTendenciasChart(), 100);
      },
      error: (error) => {
        console.error('Error al cargar análisis de tendencias:', error);
        this.errorPredicciones = 'Error al cargar el análisis de tendencias';
      }
    });

    // Cargar predicciones futuras (modelo_id = 1 fijo)
    this.prediccionesService.predecirPedidos(1, this.mesesPrediccion).subscribe({
      next: (response) => {
        this.prediccionesFuturas = response.predicciones;
        this.loadingPredicciones = false;
        setTimeout(() => this.createPrediccionesChart(), 100);
      },
      error: (error) => {
        console.error('Error al cargar predicciones:', error);
        this.loadingPredicciones = false;
        this.errorPredicciones = 'Error al cargar las predicciones. Asegúrate de que el modelo está entrenado.';
      }
    });
  }

  /**
   * Actualizar el número de meses de predicción
   */
  actualizarMesesPrediccion(): void {
    if (this.mesesPrediccion < 1 || this.mesesPrediccion > 12) {
      this.toastr.warning('El número de meses debe estar entre 1 y 12', 'Advertencia');
      return;
    }
    this.loadPrediccionesData();
    this.toastr.info(`Cargando predicciones para ${this.mesesPrediccion} meses...`, 'Actualizando');
  }

  /**
   * Crear gráfico de predicciones futuras
   */
  private createPrediccionesChart(): void {
    if (!this.prediccionesFuturas || this.prediccionesFuturas.length === 0) return;
    
    const ctx = document.getElementById('prediccionesChart') as HTMLCanvasElement;
    if (!ctx) return;

    if (this.prediccionesChart) {
      this.prediccionesChart.destroy();
    }

    const labels = this.prediccionesFuturas.map(p => {
      const fecha = new Date(p.fecha);
      return fecha.toLocaleDateString('es-ES', { month: 'short', year: 'numeric' });
    });

    this.prediccionesChart = new Chart(ctx, {
      type: 'line',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Cantidad Predicha',
            data: this.prediccionesFuturas.map(p => p.cantidad),
            borderColor: 'rgba(79, 70, 229, 1)',
            backgroundColor: 'rgba(79, 70, 229, 0.1)',
            tension: 0.4,
            fill: true,
            yAxisID: 'y'
          },
          {
            label: 'Monto Predicho ($)',
            data: this.prediccionesFuturas.map(p => p.monto),
            borderColor: 'rgba(16, 185, 129, 1)',
            backgroundColor: 'rgba(16, 185, 129, 0.1)',
            tension: 0.4,
            fill: true,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        interaction: {
          mode: 'index',
          intersect: false
        },
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 15,
              font: { size: 12 },
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const label = context.dataset.label || '';
                const value = context.parsed.y || 0;
                if (label.includes('Monto')) {
                  return `${label}: $${value.toFixed(2)}`;
                }
                return `${label}: ${value}`;
              }
            }
          }
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Cantidad de Pedidos'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Monto ($)'
            },
            grid: {
              drawOnChartArea: false
            }
          }
        }
      }
    });
  }

  /**
   * Crear gráfico de tendencias históricas
   */
  private createTendenciasChart(): void {
    if (!this.analisisTendencias || this.analisisTendencias.tendencias_mensuales.length === 0) return;
    
    const ctx = document.getElementById('tendenciasChart') as HTMLCanvasElement;
    if (!ctx) return;

    if (this.tendenciasChart) {
      this.tendenciasChart.destroy();
    }

    const labels = this.analisisTendencias.tendencias_mensuales.map(t => {
      const fecha = new Date(t.mes);
      return fecha.toLocaleDateString('es-ES', { month: 'short', year: 'numeric' });
    });

    this.tendenciasChart = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: labels,
        datasets: [
          {
            label: 'Cantidad de Pedidos',
            data: this.analisisTendencias.tendencias_mensuales.map(t => t.cantidad_pedidos),
            backgroundColor: 'rgba(139, 92, 246, 0.7)',
            borderColor: 'rgba(139, 92, 246, 1)',
            borderWidth: 2
          },
          {
            label: 'Monto Total ($)',
            data: this.analisisTendencias.tendencias_mensuales.map(t => t.monto_total),
            backgroundColor: 'rgba(245, 158, 11, 0.7)',
            borderColor: 'rgba(245, 158, 11, 1)',
            borderWidth: 2,
            yAxisID: 'y1'
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: true,
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              padding: 15,
              font: { size: 12 },
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const label = context.dataset.label || '';
                const value = context.parsed.y || 0;
                if (label.includes('Monto')) {
                  return `${label}: $${value.toFixed(2)}`;
                }
                return `${label}: ${value}`;
              }
            }
          }
        },
        scales: {
          y: {
            type: 'linear',
            display: true,
            position: 'left',
            title: {
              display: true,
              text: 'Cantidad de Pedidos'
            }
          },
          y1: {
            type: 'linear',
            display: true,
            position: 'right',
            title: {
              display: true,
              text: 'Monto Total ($)'
            },
            grid: {
              drawOnChartArea: false
            }
          }
        }
      }
    });
  }
}
