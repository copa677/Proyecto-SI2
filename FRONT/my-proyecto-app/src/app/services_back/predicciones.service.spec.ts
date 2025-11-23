import { TestBed } from '@angular/core/testing';

import { PrediccionesService } from './predicciones.service';

describe('PrediccionesService', () => {
  let service: PrediccionesService;

  beforeEach(() => {
    TestBed.configureTestingModule({});
    service = TestBed.inject(PrediccionesService);
  });

  it('should be created', () => {
    expect(service).toBeTruthy();
  });
});
