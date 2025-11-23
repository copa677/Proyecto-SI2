import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PedidoDetalleComponent } from './pedido-detalle.component';

describe('PedidoDetalleComponent', () => {
  let component: PedidoDetalleComponent;
  let fixture: ComponentFixture<PedidoDetalleComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [PedidoDetalleComponent]
    });
    fixture = TestBed.createComponent(PedidoDetalleComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
