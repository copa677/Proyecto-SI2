import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';
import { Lote } from '../../interface/lote';
import { MateriaPrima } from '../../interface/materiaprima';

@Injectable({
  providedIn: 'root'
})
export class LotesService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
    this.myAppUrl = environment.endpoint;    // URL base del backend
    this.myApiUrl = 'api/lotes';             // endpoint principal de la app Django
  }

  // ===========================
  // 📦 SERVICES PARA MATERIAS PRIMAS
  // ===========================

  // GET listar materias primas
  getMateriasPrimas(): Observable<MateriaPrima[]> {
    return this.http.get<MateriaPrima[]>(`${this.myAppUrl}${this.myApiUrl}/listar_materias/`);
  }

  // POST insertar materia prima
  insertarMateriaPrima(nuevaMateria: MateriaPrima): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/materias/insertar/`, nuevaMateria);
  }

  // PUT actualizar materia prima
  actualizarMateriaPrima(id: number, materiaEditada: MateriaPrima): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/materias/actualizar/${id}/`, materiaEditada);
  }

  // DELETE eliminar materia prima
  eliminarMateriaPrima(id: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/materias/eliminar/${id}/`);
  }

  // ===========================
  // 🧺 SERVICES PARA LOTES
  // ===========================

  // GET listar lotes
  getLotes(): Observable<Lote[]> {
    return this.http.get<Lote[]>(`${this.myAppUrl}${this.myApiUrl}/listar_lotes/`);
  }

  // POST insertar lote
  insertarLote(nuevoLote: Lote): Observable<void> {
    return this.http.post<void>(`${this.myAppUrl}${this.myApiUrl}/lotes/insertar/`, nuevoLote);
  }

  // PUT actualizar lote
  actualizarLote(id: number, loteEditado: Lote): Observable<void> {
    return this.http.put<void>(`${this.myAppUrl}${this.myApiUrl}/lotes/actualizar/${id}/`, loteEditado);
  }

  // DELETE eliminar lote
  eliminarLote(id: number): Observable<void> {
    return this.http.delete<void>(`${this.myAppUrl}${this.myApiUrl}/lotes/eliminar/${id}/`);
  }

}
