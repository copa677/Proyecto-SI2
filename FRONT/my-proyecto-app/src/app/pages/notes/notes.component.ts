import { Component } from '@angular/core';
import { Router } from '@angular/router'; // añadido

@Component({
  selector: 'app-notes',
  templateUrl: './notes.component.html',
  styleUrls: ['./notes.component.css']
})
export class NotesComponent {
 constructor(private router: Router) {} //  añadido

  onLogin(event: Event) { //  añadido
    event.preventDefault(); // evita recargar la página
    this.router.navigate(['/menu/dashboard']); // redirige al menú (dashboard por ahora)
  }
}
