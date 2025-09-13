
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class Dashboard extends StatelessWidget {
	const Dashboard({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
			return Container(
				color: AppColors.blanco,
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(16),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: [
							// Métricas principales
							Row(
								mainAxisAlignment: MainAxisAlignment.spaceEvenly,
								children: const [
									_MetricCard(
										title: 'Total Personal',
										value: '12',
										icon: Icons.people_alt_rounded,
										color: AppColors.azulPrincipal,
									),
									_MetricCard(
										title: 'Asistencia Hoy',
										value: '8 / 12',
										icon: Icons.check_circle_outline,
										color: AppColors.verdePrincipal,
									),
									   _MetricCard(
										   title: 'Usuarios del Sistema',
										   value: '5',
										   icon: Icons.person_outline,
										   color: AppColors.grisLineas,
										   disabled: true,
									   ),
								],
							),
							const SizedBox(height: 28),
							const Text(
								'Actividad Reciente',
								style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
							),
							const SizedBox(height: 10),
							_ActivityList(),
							const SizedBox(height: 28),
							Row(
								crossAxisAlignment: CrossAxisAlignment.start,
								children: const [
									Expanded(child: _QuickAccess()),
									SizedBox(width: 16),
									Expanded(child: _Indicators()),
								],
							),
						],
					),
				),
			);
		}
}

class _MetricCard extends StatelessWidget {
	final String title;
	final String value;
	final IconData icon;
	final Color color;
		final bool disabled;
		const _MetricCard({required this.title, required this.value, required this.icon, required this.color, this.disabled = false});

	@override
	Widget build(BuildContext context) {
		return Expanded(
			child: Card(
				color: AppColors.blanco,
				shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
				elevation: 4,
				child: Padding(
					padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
					child: Column(
						mainAxisSize: MainAxisSize.min,
						children: [
							CircleAvatar(
								backgroundColor: disabled ? AppColors.grisLineas.withOpacity(0.18) : color.withOpacity(0.1),
								child: Icon(icon, color: disabled ? AppColors.grisTextoSecundario : color, size: 28),
								radius: 22,
							),
							const SizedBox(height: 10),
							Text(
								value,
								style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: disabled ? AppColors.grisTextoSecundario : color),
							),
							const SizedBox(height: 6),
							Text(
								title,
								textAlign: TextAlign.center,
								style: TextStyle(fontSize: 13, color: AppColors.grisTextoSecundario),
							),
						],
					),
				),
			),
		);
	}
}



class _ActivityList extends StatelessWidget {
	const _ActivityList();

	@override
	Widget build(BuildContext context) {
		return Card(
			color: AppColors.blanco,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
				child: Column(
					children: const [
							_ActivityItem(
								title: 'Registro de usuario',
								subtitle: 'Juan Pérez se ha registrado en el sistema',
								time: 'hace 2 horas',
								icon: Icons.person_add_alt_1,
								color: AppColors.azulPrincipal,
							),
							Divider(height: 1, color: AppColors.grisLineas),
							_ActivityItem(
								title: 'Modificación de datos',
								subtitle: 'Se actualizaron datos del personal',
								time: 'hace 5 horas',
								icon: Icons.edit_note,
								color: AppColors.azulClaro,
							),
							Divider(height: 1, color: AppColors.grisLineas),
							_ActivityItem(
								title: 'Registro de asistencia',
								subtitle: '8 miembros del personal registraron asistencia',
								time: 'hoy, 8:00 AM',
								icon: Icons.check_circle_outline,
								color: AppColors.verdePrincipal,
							),
					],
				),
			),
		);
	}
}


class _ActivityItem extends StatelessWidget {
	final String title;
	final String subtitle;
	final String time;
	final IconData icon;
	final Color color;
	const _ActivityItem({
		required this.title,
		required this.subtitle,
		required this.time,
		required this.icon,
		required this.color,
	});

	@override
	Widget build(BuildContext context) {
		return ListTile(
									leading: CircleAvatar(
											backgroundColor: (title == 'Modificación de datos' || title == 'Modificación de dato' || title == 'Modificación de datos del sistema')
												? AppColors.grisLineas.withOpacity(0.18)
												: color.withOpacity(0.12),
											child: Icon(icon, color: (title == 'Modificación de datos' || title == 'Modificación de dato' || title == 'Modificación de datos del sistema') ? AppColors.grisTextoSecundario : color, size: 22),
									),
									title: Text(
										title,
										style: TextStyle(
											color: (title == 'Modificación de datos' || title == 'Modificación de dato' || title == 'Modificación de datos del sistema') ? AppColors.grisTextoSecundario : color,
											fontWeight: FontWeight.bold,
										),
									),
									subtitle: Text(subtitle, style: const TextStyle(color: AppColors.grisTextoSecundario)),
			trailing: Text(time, style: const TextStyle(fontSize: 12, color: AppColors.grisTextoSecundario)),
		);
	}
}


class _QuickAccess extends StatelessWidget {
	const _QuickAccess();

	@override
	Widget build(BuildContext context) {
		return Card(
			color: AppColors.blanco,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
				child: Column(
					children: [
						const Text('Accesos rápidos', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
						const SizedBox(height: 12),
																		Column(
																				children: [
																						_QuickButton(
																							text: 'Personal',
																							icon: Icons.people_alt_rounded,
																							onTap: () => DefaultTabController.of(context)?.animateTo(1),
																						),
																						SizedBox(height: 10),
																						_QuickButton(
																							text: 'Asistencia',
																							icon: Icons.check_circle_outline,
																							onTap: () => DefaultTabController.of(context)?.animateTo(2),
																						),
																						SizedBox(height: 10),
																						_QuickButton(
																							text: 'Usuarios',
																							icon: Icons.person_outline,
																							onTap: () => DefaultTabController.of(context)?.animateTo(3),
																						),
																						SizedBox(height: 10),
																						_QuickButton(
																							text: 'Configuración',
																							icon: Icons.settings,
																							onTap: () => DefaultTabController.of(context)?.animateTo(4),
																						),
																				],
																		),
					],
				),
			),
		);
	}
}

class _QuickButton extends StatelessWidget {
		final String text;
		final IconData icon;
		final VoidCallback? onTap;
		const _QuickButton({required this.text, required this.icon, this.onTap});

	@override
	Widget build(BuildContext context) {
				return OutlinedButton.icon(
					onPressed: onTap,
					icon: Icon(icon, color: AppColors.azulPrincipal),
					label: Text(
						text,
						style: TextStyle(
							fontSize: text == 'Configuración' ? 13 : 15,
							color: AppColors.azulPrincipal,
						),
						overflow: TextOverflow.ellipsis,
					),
					style: OutlinedButton.styleFrom(
						minimumSize: const Size.fromHeight(40),
						shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
						side: const BorderSide(color: AppColors.azulPrincipal),
					),
				);
	}
}


class _Indicators extends StatelessWidget {
	const _Indicators();

	@override
	Widget build(BuildContext context) {
		return Card(
			color: AppColors.blanco,
			shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
			elevation: 2,
			child: Padding(
				padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
				child: Column(
					crossAxisAlignment: CrossAxisAlignment.start,
					children: const [
						Text('Indicadores de hoy', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
						SizedBox(height: 12),
						_IndicatorItem(label: 'Órdenes activas', value: '9'),
						_IndicatorItem(label: 'Inventario crítico', value: '3'),
						_IndicatorItem(label: 'Eficiencia', value: '92%'),
					],
				),
			),
		);
	}
}


class _IndicatorItem extends StatelessWidget {
	final String label;
	final String value;
	const _IndicatorItem({required this.label, required this.value});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 6),
			child: Row(
				mainAxisAlignment: MainAxisAlignment.spaceBetween,
				children: [
					Text(label, style: const TextStyle(fontSize: 15, color: AppColors.grisTextoSecundario)),
					Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.azulPrincipal)),
				],
			),
		);
	}
}
