import { Component, OnInit } from '@angular/core';
import { NotaSalidaService } from '../../services_back/nota-salida.service';

@Component({
  selector: 'app-nota-salida',
  templateUrl: './nota-salida.component.html',
  styleUrls: ['./nota-salida.component.css']
})
export class NotaSalidaComponent implements OnInit {
  notasSalida: any[] = [];
  detalles: any[] = [];
  notaSeleccionada: any = null;
  modalVisible: boolean = false;

  constructor(private notaSalidaService: NotaSalidaService) {}

  ngOnInit(): void {
    this.cargarNotasSalida();
  }

  cargarNotasSalida() {
    this.notaSalidaService.getNotasSalida().subscribe({
      next: (data: any) => {
        this.notasSalida = data;
        console.log('Notas de salida cargadas:', data);
      },
      error: (error: any) => {
        console.error('Error al cargar notas de salida:', error);
      }
    });
  }

  seleccionarNota(nota: any) {
    this.notaSeleccionada = nota;
    this.notaSalidaService.getDetallesSalida(nota.id_salida).subscribe({
      next: (data: any) => {
        this.detalles = data;
        console.log('Detalles cargados:', data);
          this.modalVisible = true;
      },
      error: (error: any) => {
        console.error('Error al cargar detalles:', error);
          this.modalVisible = true;
      }
    });
  }
}
