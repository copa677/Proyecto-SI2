import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ClienteFacturasComponent } from './cliente-facturas.component';

describe('ClienteFacturasComponent', () => {
  let component: ClienteFacturasComponent;
  let fixture: ComponentFixture<ClienteFacturasComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [ClienteFacturasComponent]
    });
    fixture = TestBed.createComponent(ClienteFacturasComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
