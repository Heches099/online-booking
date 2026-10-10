import 'package:flutter/material.dart';
import '../../../../core/constants/route_pricing.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/tanzania_regions.dart';
import '../pages/bus_results_page.dart';

class SearchCard extends StatefulWidget {
  const SearchCard({super.key});

  @override
  State<SearchCard> createState() => _SearchCardState();
}

class _SearchCardState extends State<SearchCard> {
  String fromRegion = 'Dar es Salaam';
  String toRegion = 'Arusha';
  DateTime selectedDate = DateTime.now();
  DateTime? returnDate;
  int selectedTripType = 0;

  static const Color _bookingGreen = Color(0xFF098E5F);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE7E7E7)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              _tripTab('One Way', 0),
              _tripTab('Round Trip', 1),
              _tripTab('Multi City', 2),
            ],
          ),
          const SizedBox(height: 14),
          // The Route Selection Area
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  _buildRegionDropdown(
                    icon: Icons.trip_origin_rounded,
                    label: "From",
                    value: fromRegion,
                    color: _bookingGreen,
                    onChanged: (val) {
                      if (val != null && val != toRegion) {
                        setState(() => fromRegion = val);
                      } else if (val != null) {
                        _showDifferentLocationsMessage();
                      }
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildRegionDropdown(
                    icon: Icons.location_on_outlined,
                    label: "To",
                    value: toRegion,
                    color: _bookingGreen,
                    onChanged: (val) {
                      if (val != null && val != fromRegion) {
                        setState(() => toRegion = val);
                      } else if (val != null) {
                        _showDifferentLocationsMessage();
                      }
                    },
                  ),
                ],
              ),
              Positioned(
                right: 12,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    tooltip: 'Swap locations',
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      final previousFrom = fromRegion;
                      fromRegion = toRegion;
                      toRegion = previousFrom;
                    }),
                    icon: const Icon(Icons.swap_vert_rounded, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildDatePicker(context, isReturnDate: false),
          if (selectedTripType == 1) ...[
            const SizedBox(height: 8),
            _buildDatePicker(context, isReturnDate: true),
          ],
          if (selectedTripType == 2) ...[
            const SizedBox(height: 10),
            const Text(
              'Multi-city bookings are coming soon.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: selectedTripType == 2
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BusResultsPage(
                            from: fromRegion,
                            to: toRegion,
                            date: selectedDate,
                            priceOverride:
                                RoutePricing.priceFor(fromRegion, toRegion),
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: _bookingGreen,
                disabledBackgroundColor: const Color(0xFFBDBDBD),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              icon: const Icon(Icons.search_rounded, size: 20),
              label: const Text(
                'Search Buses',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tripTab(String label, int index) {
    final isSelected = selectedTripType == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() {
          selectedTripType = index;
          if (index == 0) returnDate = null;
        }),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFF0F7F4) : Colors.transparent,
            border: Border(
              bottom: BorderSide(
                color: isSelected ? _bookingGreen : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isSelected ? _bookingGreen : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  void _showDifferentLocationsMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('From and To locations must be different'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildRegionDropdown({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: value,
                    isDense: true,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    items: tanzaniaRegions.map((String region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: onChanged,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(BuildContext context, {required bool isReturnDate}) {
    final currentDate = isReturnDate ? returnDate : selectedDate;
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: currentDate ?? selectedDate,
          firstDate: isReturnDate ? selectedDate : DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 90)),
        );
        if (date != null) {
          setState(() {
            if (isReturnDate) {
              returnDate = date;
            } else {
              selectedDate = date;
              if (returnDate != null && returnDate!.isBefore(date)) {
                returnDate = date;
              }
            }
          });
        }
      },
      child: _buildInfoTile(
        icon: Icons.calendar_today_rounded,
        label: isReturnDate ? 'Return Date' : 'Journey Date',
        value: currentDate == null
            ? 'Select return date'
            : '${currentDate.day} ${_getMonth(currentDate.month)}',
      ),
    );
  }

  String _getMonth(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        border: Border.all(color: const Color(0xFFE5E5E5)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(icon, size: 16, color: _bookingGreen),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
