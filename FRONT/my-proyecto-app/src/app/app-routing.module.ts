import { NgModule } from '@angular/core';
import { RouterModule, Routes } from '@angular/router';
import { NotesComponent } from './pages/notes/notes.component';
import { MenuComponent } from './pages/menu/menu.component';
import { UsuariosComponent } from './pages/usuarios/usuarios.component';
import { DashboardComponent } from './pages/dashboard/dashboard.component';
import { PersonalComponent } from './pages/personal/personal.component';
import { AsistenciaComponent } from './pages/asistencia/asistencia.component';
import { ConfiguracionComponent } from './pages/configuracion/configuracion.component';
import { BitacoraComponent } from './pages/bitacora/bitacora.component';
import { authGuard } from './guards/auth.guard';
import { LotesComponent } from './pages/lotes/lotes.component';
import { OrdenProduccionComponent } from './pages/ordenproduccion/ordenproduccion.component';
import { NotaSalidaComponent } from './pages/nota-salida/nota-salida.component';
import { PermisosComponent } from './pages/permisos/permisos.component';
import { AsignarPermisosComponent } from './pages/asignar-permisos/asignar-permisos.component';
import { TurnosComponent } from './pages/turnos/turnos.component';
import { InventarioComponent } from './pages/inventario/inventario.component';
import { ControlCalidadComponent } from './pages/control-calidad/control-calidad.component';
import { TrazabilidadComponent } from './pages/trazabilidad/trazabilidad.component';


const routes: Routes = [
  {
    path: 'menu', component: MenuComponent,
    canActivate: [authGuard], 
    children: [
      { path: 'usuarios', component: UsuariosComponent },
      { path: 'dashboard', component: DashboardComponent },
      { path: 'personal', component: PersonalComponent },
      { path: 'asistencia', component: AsistenciaComponent },
      { path: 'turnos', component: TurnosComponent },
      { path: 'bitacora', component: BitacoraComponent },
      { path: 'configuracion', component: ConfiguracionComponent },
      { path: 'lotes', component: LotesComponent },
      { path: 'inventario', component: InventarioComponent },
      { path: 'ordenproduccion', component: OrdenProduccionComponent },
      { path: 'trazabilidad', component: TrazabilidadComponent },
      { path: 'control-calidad', component: ControlCalidadComponent },
      { path: 'nota-salida', component: NotaSalidaComponent },
      { path: 'permisos', component: PermisosComponent },
      { path: 'asignar-permisos', component: AsignarPermisosComponent },
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
