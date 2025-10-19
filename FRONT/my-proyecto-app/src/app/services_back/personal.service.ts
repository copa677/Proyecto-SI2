import { Injectable } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { Observable } from 'rxjs';
import { environment } from '../../environments/environment.development';
import { Personal } from '../../interface/personal';

@Injectable({
  providedIn: 'root'
})
export class PersonalService {
  private myAppUrl: string;
  private myApiUrl: string;

  constructor(private http: HttpClient) {
  this.myAppUrl = environment.endpoint;
  this.myApiUrl = 'api/personal/getEmpleados';
  }

  getPersonales(): Observable<Personal[]> {
    return this.http.get<Personal[]>(`${this.myAppUrl}${this.myApiUrl}`);
  }
}