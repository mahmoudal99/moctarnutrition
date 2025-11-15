import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/services/progress_service.dart';
import 'measurement_card.dart';

class MeasurementsTab extends StatelessWidget {
  final Future<List<String>>? typesFuture;
  final Map<String, Future<List<MeasurementDataPoint>>> dataFutures;

  const MeasurementsTab({
    super.key,
    this.typesFuture,
    required this.dataFutures,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: typesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 24,
                  color: AppConstants.errorColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading measurements',
                  style: AppTextStyles.bodyLarge,
                ),
              ],
            ),
          );
        }

        final types = snapshot.data ?? [];

        if (types.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/tape-measure-stroke-rounded.svg",
                        height: 20,
                        color: Colors.black,
                      ),
                      const SizedBox(width: 10),
                      Text('No Measurements', style: AppTextStyles.heading5),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start logging body measurements in check-ins to track changes!',
                    style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: types.length,
          itemBuilder: (context, index) {
            final type = types[index];
            final dataFuture = dataFutures[type];

            return MeasurementCard(
              measurementType: type,
              dataFuture: dataFuture,
            );
          },
        );
      },
    );
  }
}
