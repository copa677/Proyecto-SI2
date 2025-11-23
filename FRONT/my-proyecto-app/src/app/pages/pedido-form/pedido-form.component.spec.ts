import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PedidoFormComponent } from './pedido-form.component';

describe('PedidoFormComponent', () => {
  let component: PedidoFormComponent;
  let fixture: ComponentFixture<PedidoFormComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [PedidoFormComponent]
    });
    fixture = TestBed.createComponent(PedidoFormComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
