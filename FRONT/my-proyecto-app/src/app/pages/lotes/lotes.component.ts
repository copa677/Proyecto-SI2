import { Component, OnInit } from '@angular/core';
import { LotesService } from '../../services_back/lotes.service';
import { Lote } from '../../../interface/lote';
import { MateriaPrima } from '../../../interface/materiaprima';

@Component({
  selector: 'app-lotes',
  templateUrl: './lotes.component.html',
  styleUrls: ['./lotes.component.css']
})
export class LotesComponent implements OnInit {
  lotes: Lote[] = [];
  materiasPrimas: MateriaPrima[] = [];
  selectedLote: Lote | null = null;
  showForm = false;
  showMateriaForm = false;
  formData: Partial<Lote> = {};
  materiaFormData: Partial<MateriaPrima> = {};
  activeTab: 'lotes' | 'materias' = 'lotes';

  constructor(private lotesService: LotesService) {}

  ngOnInit(): void {
      // Datos mockup para pruebas visuales
      this.materiasPrimas = [
        { id_materia: 1, nombre: 'Harina', tipo_material: 'Orgánico' },
        { id_materia: 2, nombre: 'Azúcar', tipo_material: 'Orgánico' },
        { id_materia: 3, nombre: 'Sal', tipo_material: 'Inorgánico' }
      ];
      this.lotes = [
        { id_lote: 101, codigo_lote: 'LT-001', fecha_recepcion: '2025-10-01', cantidad: 100, estado: 'Disponible', id_materia: 1 },
        { id_lote: 102, codigo_lote: 'LT-002', fecha_recepcion: '2025-10-03', cantidad: 50, estado: 'En Uso', id_materia: 2 },
        { id_lote: 103, codigo_lote: 'LT-003', fecha_recepcion: '2025-10-05', cantidad: 0, estado: 'Agotado', id_materia: 3 }
      ];
      // Si quieres volver a usar el backend, comenta las líneas mockup y descomenta las siguientes:
      // this.getLotes();
      // this.getMateriasPrimas();
  }

  getLotes() {
    this.lotesService.getLotes().subscribe((data: Lote[]) => this.lotes = data);
  }

  getMateriasPrimas() {
    this.lotesService.getMateriasPrimas().subscribe((data: MateriaPrima[]) => this.materiasPrimas = data);
  }

  selectLote(lote: Lote) {
    this.selectedLote = lote;
    this.showForm = false;
  }

  openForm(lote?: Lote) {
    this.showForm = true;
    this.formData = lote ? { ...lote } : {};
  }

  openMateriaForm(materia?: MateriaPrima) {
    this.showMateriaForm = true;
    this.materiaFormData = materia ? { ...materia } : {};
  }

  saveLote() {
    if (this.formData.id_lote) {
      this.lotesService.actualizarLote(this.formData.id_lote, this.formData as Lote).subscribe(() => {
        this.getLotes();
        this.showForm = false;
      });
    } else {
      this.lotesService.insertarLote(this.formData as Lote).subscribe(() => {
        this.getLotes();
        this.showForm = false;
      });
    }
  }

  saveMateria() {
    if (this.materiaFormData.id_materia) {
      this.lotesService.actualizarMateriaPrima(this.materiaFormData.id_materia, this.materiaFormData as MateriaPrima).subscribe(() => {
        this.getMateriasPrimas();
        this.showMateriaForm = false;
      });
    } else {
      this.lotesService.insertarMateriaPrima(this.materiaFormData as MateriaPrima).subscribe(() => {
        this.getMateriasPrimas();
        this.showMateriaForm = false;
      });
    }
  }

  deleteLote(id: number) {
    if (confirm('¿Está seguro de eliminar este lote?')) {
      this.lotesService.eliminarLote(id).subscribe(() => this.getLotes());
    }
  }

  deleteMateria(id: number) {
    if (confirm('¿Está seguro de eliminar esta materia prima?')) {
      this.lotesService.eliminarMateriaPrima(id).subscribe(() => this.getMateriasPrimas());
    }
  }

  getMateriaNombre(id_materia: number): string {
    const materia = this.materiasPrimas.find(m => m.id_materia === id_materia);
    return materia ? materia.nombre : 'N/A';
  }
}
