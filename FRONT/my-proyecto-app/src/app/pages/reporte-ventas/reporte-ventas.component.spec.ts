import { ComponentFixture, TestBed, fakeAsync, tick } from '@angular/core/testing';
import { ReactiveFormsModule } from '@angular/forms';
import { CommonModule } from '@angular/common';

import { ReporteVentasComponent } from './reporte-ventas.component';

describe('ReporteVentasComponent', () => {
  let component: ReporteVentasComponent;
  let fixture: ComponentFixture<ReporteVentasComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      imports: [ReporteVentasComponent, ReactiveFormsModule, CommonModule]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ReporteVentasComponent);
    component = fixture.componentInstance;
  });

  it('should create', () => {
    fixture.detectChanges();
    expect(component).toBeTruthy();
  });

  it('should initialize the filter form with empty values', () => {
    fixture.detectChanges();
    const form = component.filtroForm;
    expect(form).toBeDefined();
    expect(form.get('lote')?.value).toBe('');
    expect(form.get('cliente')?.value).toBe('');
  });

  it('should load mock data when generarReporte is called', fakeAsync(() => {
    fixture.detectChanges(); // ngOnInit llama a generarReporte

    expect(component.isLoading).toBe(true);
    expect(component.reporteVentas.length).toBe(0);

    tick(1000); // Simula el paso de 1 segundo del setTimeout

    expect(component.isLoading).toBe(false);
    expect(component.reporteVentas.length).toBeGreaterThan(0);
  }));
});