import { ComponentFixture, TestBed } from '@angular/core/testing';

import { ControlCalidadComponent } from './control-calidad.component';

describe('ControlCalidadComponent', () => {
  let component: ControlCalidadComponent;
  let fixture: ComponentFixture<ControlCalidadComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ ControlCalidadComponent ]
    })
    .compileComponents();

    fixture = TestBed.createComponent(ControlCalidadComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
