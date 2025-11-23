import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { LoginService } from '../../services_back/login.service';
import { ToastrService } from 'ngx-toastr';
import { HttpClient } from '@angular/common/http';
import { environment } from '../../../environments/environment.development';

@Component({
  selector: 'app-registro-cliente',
  templateUrl: './registro-cliente.component.html',
  styleUrls: ['./registro-cliente.component.css']
})
export class RegistroClienteComponent {
  // Datos del formulario
  formData = {
    name_user: '',
    email: '',
    password: '',
    confirmPassword: '',
    nombre_completo: '',
    direccion: '',
    telefono: '',
    fecha_nacimiento: ''
  };

  loading = false;
  showPassword = false;
  showConfirmPassword = false;

  constructor(
    private router: Router,
    private loginService: LoginService,
    private toastr: ToastrService,
    private http: HttpClient
  ) {}

  togglePasswordVisibility() {
    this.showPassword = !this.showPassword;
  }

  toggleConfirmPasswordVisibility() {
    this.showConfirmPassword = !this.showConfirmPassword;
  }

  validarFormulario(): boolean {
    // Validar campos requeridos
    if (!this.formData.name_user.trim()) {
      this.toastr.warning('El nombre de usuario es obligatorio', 'Campo requerido');
      return false;
    }

    if (!this.formData.email.trim()) {
      this.toastr.warning('El correo electrónico es obligatorio', 'Campo requerido');
      return false;
    }

    // Validar formato de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(this.formData.email)) {
      this.toastr.warning('El formato del correo electrónico no es válido', 'Email inválido');
      return false;
    }

    if (!this.formData.password) {
      this.toastr.warning('La contraseña es obligatoria', 'Campo requerido');
      return false;
    }

    // Validar longitud de contraseña
    if (this.formData.password.length < 6) {
      this.toastr.warning('La contraseña debe tener al menos 6 caracteres', 'Contraseña débil');
      return false;
    }

    if (this.formData.password !== this.formData.confirmPassword) {
      this.toastr.warning('Las contraseñas no coinciden', 'Error de validación');
      return false;
    }

    if (!this.formData.nombre_completo.trim()) {
      this.toastr.warning('El nombre completo es obligatorio', 'Campo requerido');
      return false;
    }

    if (!this.formData.direccion.trim()) {
      this.toastr.warning('La dirección es obligatoria', 'Campo requerido');
      return false;
    }

    if (!this.formData.telefono.trim()) {
      this.toastr.warning('El teléfono es obligatorio', 'Campo requerido');
      return false;
    }

    // Validar formato de teléfono (solo números y guiones)
    const telefonoRegex = /^[0-9\-\+\(\)\s]+$/;
    if (!telefonoRegex.test(this.formData.telefono)) {
      this.toastr.warning('El formato del teléfono no es válido', 'Teléfono inválido');
      return false;
    }

    if (!this.formData.fecha_nacimiento) {
      this.toastr.warning('La fecha de nacimiento es obligatoria', 'Campo requerido');
      return false;
    }

    // Validar que sea mayor de edad (18 años)
    const fechaNacimiento = new Date(this.formData.fecha_nacimiento);
    const hoy = new Date();
    let edad = hoy.getFullYear() - fechaNacimiento.getFullYear();
    const mes = hoy.getMonth() - fechaNacimiento.getMonth();
    if (mes < 0 || (mes === 0 && hoy.getDate() < fechaNacimiento.getDate())) {
      edad--;
    }

    if (edad < 18) {
      this.toastr.warning('Debes ser mayor de 18 años para registrarte', 'Edad insuficiente');
      return false;
    }

    return true;
  }

  registrar() {
    if (!this.validarFormulario()) {
      return;
    }

    this.loading = true;

    // Preparar datos para enviar al backend
    const payload = {
      name_user: this.formData.name_user.trim(),
      email: this.formData.email.trim(),
      password: this.formData.password,
      nombre_completo: this.formData.nombre_completo.trim(),
      direccion: this.formData.direccion.trim(),
      telefono: this.formData.telefono.trim(),
      fecha_nacimiento: this.formData.fecha_nacimiento
    };

    // Llamar al endpoint de registro público
    this.http.post(`${environment.endpoint}api/usuario/registro-cliente`, payload).subscribe({
      next: (response: any) => {
        this.toastr.success('Registro exitoso. Ahora puedes iniciar sesión.', 'Bienvenido');
        setTimeout(() => {
          this.router.navigate(['/']);
        }, 1500);
      },
      error: (error: any) => {
        this.loading = false;
        const errorMsg = error.error?.error || 'Error al registrar. Intenta nuevamente.';
        this.toastr.error(errorMsg, 'Error de registro');
        console.error('Error al registrar:', error);
      }
    });
  }

  volverAlLogin() {
    this.router.navigate(['/']);
  }
}
