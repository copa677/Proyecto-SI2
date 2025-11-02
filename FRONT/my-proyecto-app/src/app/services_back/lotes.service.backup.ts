import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';

export interface MateriaPrima {
  id_materia: number;
  nombre: string;
  tipo_material: string;
}

export interface Lote {
  id_lote: number;
  codigo_lote: string;
  fecha_recepcion: string;
  cantidad: number;
  estado: string;
  id_materia: number;
}

@Injectable({ providedIn: 'root' })
export class LotesService {
  private apiUrl = 'http://localhost:8000/api/lotes/';

  constructor(private http: HttpClient) {}

  // Materias Primas
  getMateriasPrimas(): Observable<MateriaPrima[]> {
    return this.http.get<MateriaPrima[]>(this.apiUrl + 'listar_materias/');
  }

  createMateriaPrima(materia: Partial<MateriaPrima>): Observable<any> {
    return this.http.post(this.apiUrl + 'materias/insertar/', materia);
  }

  updateMateriaPrima(id: number, materia: Partial<MateriaPrima>): Observable<any> {
    return this.http.put(this.apiUrl + 'materias/actualizar/' + id + '/', materia);
  }

  deleteMateriaPrima(id: number): Observable<any> {
    return this.http.delete(this.apiUrl + 'materias/eliminar/' + id + '/');
  }

  // Lotes
  getLotes(): Observable<Lote[]> {
    return this.http.get<Lote[]>(this.apiUrl + 'listar_lotes/');
  }

  createLote(lote: Partial<Lote>): Observable<any> {
    return this.http.post(this.apiUrl + 'lotes/insertar/', lote);
  }

  updateLote(id: number, lote: Partial<Lote>): Observable<any> {
    return this.http.put(this.apiUrl + 'lotes/actualizar/' + id + '/', lote);
  }

  deleteLote(id: number): Observable<any> {
    return this.http.delete(this.apiUrl + 'lotes/eliminar/' + id + '/');
  }
}
