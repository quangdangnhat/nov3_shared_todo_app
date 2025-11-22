import 'package:flutter/material.dart';
import 'package:shared_todo_app/features/todo_lists/presentation/widgets/maps/map_dialog.dart';

/// Widget per mostrare/selezionare la location
class LocationDisplayCard extends StatelessWidget {
  final LocationData? selectedLocation;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const LocationDisplayCard({
    super.key,
    required this.selectedLocation,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final hasLocation = selectedLocation != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: hasLocation ? Colors.blue.shade200 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      hasLocation ? Colors.blue.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.location_on,
                  color: hasLocation ? Colors.blue : Colors.grey,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasLocation ? 'Selectede place' : 'Add place',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: hasLocation ? Colors.black87 : Colors.grey[600],
                      ),
                    ),
                    if (hasLocation) ...[
                      const SizedBox(height: 4),
                      Text(
                        selectedLocation!.placeName,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else
                      Text(
                        'Touch to select a position',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
              ),
              if (hasLocation && onClear != null)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClear,
                  color: Colors.grey,
                  tooltip: 'Remove place',
                )
              else
                Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
