import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ReportesIAComponent } from './reportes-ia.component';

describe('ReportesIAComponent', () => {
  let component: ReportesIAComponent;
  let fixture: ComponentFixture<ReportesIAComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ReportesIAComponent ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ReportesIAComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });

  it('should verify voice support', () => {
    component.verificarSoporteVoz();
    expect(component.soportaVoz).toBeDefined();
  });

  it('should process manual command', () => {
    component.comandoActual = 'Genera un reporte de ventas';
    component.procesarComandoManual();
    expect(component.reportes.length).toBeGreaterThan(0);
  });

  it('should filter reports by status', () => {
    component.reportes = [
      {
        id: 1,
        tipo: 'Ventas',
        descripcion: 'Test',
        fecha: new Date(),
        estado: 'completado',
        comando: 'test'
      },
      {
        id: 2,
        tipo: 'Inventario',
        descripcion: 'Test 2',
        fecha: new Date(),
        estado: 'generando',
        comando: 'test 2'
      }
    ];
    
    component.filtroEstado = 'completado';
    const filtered = component.filtrados;
    expect(filtered.length).toBe(1);
    expect(filtered[0].estado).toBe('completado');
  });

  it('should save and load command history', () => {
    component.historialComandos = ['comando 1', 'comando 2'];
    component.guardarHistorial();
    
    component.historialComandos = [];
    component.cargarHistorial();
    
    expect(component.historialComandos.length).toBe(2);
  });

  it('should use example command', () => {
    const ejemplo = 'Genera un reporte de ventas del último mes';
    component.usarEjemplo(ejemplo);
    expect(component.comandoActual).toBe(ejemplo);
  });

  it('should detect report type from command', () => {
    component.procesarComando('genera un reporte de ventas');
    expect(component.reportes[0].tipo).toBe('Ventas');
    
    component.procesarComando('muestra el inventario');
    expect(component.reportes[0].tipo).toBe('Inventario');
  });

  it('should handle report deletion', () => {
    component.reportes = [
      {
        id: 1,
        tipo: 'Ventas',
        descripcion: 'Test',
        fecha: new Date(),
        estado: 'completado',
        comando: 'test'
      }
    ];
    
    spyOn(window, 'confirm').and.returnValue(true);
    component.eliminarReporte(component.reportes[0]);
    expect(component.reportes.length).toBe(0);
  });

  it('should get correct estado class', () => {
    expect(component.getEstadoClass('completado')).toContain('green');
    expect(component.getEstadoClass('generando')).toContain('yellow');
    expect(component.getEstadoClass('error')).toContain('red');
  });

  it('should get correct estado icon', () => {
    expect(component.getEstadoIcon('completado')).toContain('check');
    expect(component.getEstadoIcon('generando')).toContain('spinner');
    expect(component.getEstadoIcon('error')).toContain('exclamation');
  });
});
