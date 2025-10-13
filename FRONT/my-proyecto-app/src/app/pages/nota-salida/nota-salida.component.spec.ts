import { ComponentFixture, TestBed } from '@angular/core/testing';
import { NotaSalidaComponent } from './nota-salida.component';
import { NotaSalidaService } from '../../services_back/nota-salida.service';
import { HttpClientTestingModule } from '@angular/common/http/testing';

describe('NotaSalidaComponent', () => {
  let component: NotaSalidaComponent;
  let fixture: ComponentFixture<NotaSalidaComponent>;

  beforeEach(async () => {
    await TestBed.configureTestingModule({
      declarations: [ NotaSalidaComponent ],
      imports: [ HttpClientTestingModule ],
      providers: [ NotaSalidaService ]
    })
    .compileComponents();
  });

  beforeEach(() => {
    fixture = TestBed.createComponent(NotaSalidaComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
