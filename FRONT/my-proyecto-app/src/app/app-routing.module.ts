import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { NotesComponent } from './pages/notes/notes.component';
import { MenuComponent } from './pages/menu/menu.component';
import { UsuariosComponent } from './pages/usuarios/usuarios.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PersonalComponent } from './pages/personal/personal.component';
import { AsistenciaComponent } from './pages/asistencia/asistencia.component';
import { ConfiguracionComponent } from './pages/configuracion/configuracion.component';
import { authGuard } from './guards/auth.guard';


const routes: Routes = [
  {
    path: 'menu', component: MenuComponent,
    canActivate: [authGuard], 
    children: [
      { path: 'usuarios', component: UsuariosComponent },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'personal', component: PersonalComponent },
      { path: 'asistencia', component: AsistenciaComponent },
      { path: 'configuracion', component: ConfiguracionComponent }
    ]
  },
  { path: 'notes', component: NotesComponent },
  { path: '', redirectTo: 'notes', pathMatch: 'full' },

];

@NgModule({
  imports: [RouterModule.forRoot(routes)],
  exports: [RouterModule]
})
export class AppRoutingModule { }
