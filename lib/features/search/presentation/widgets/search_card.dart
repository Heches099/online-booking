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

  final TextEditingController _quickSearchController = TextEditingController();

  static const Color _bookingGreen = Color(0xFF098E5F);

  @override
  void dispose() {
    _quickSearchController.dispose();
    super.dispose();
  }

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

          // Search TextField above From & To options to quickly type and filter regions
          // TextField(
          //   controller: _quickSearchController,
          //   decoration: InputDecoration(
          //     hintText: 'Type region to search (e.g. Arusha, Dodoma)...',
          //     hintStyle: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          //     prefixIcon: const Icon(Icons.search_rounded, color: _bookingGreen, size: 20),
          //     suffixIcon: _quickSearchController.text.isNotEmpty
          //         ? IconButton(
          //             icon: const Icon(Icons.clear_rounded, size: 18),
          //             onPressed: () {
          //               _quickSearchController.clear();
          //               setState(() {});
          //             },
          //           )
          //         : null,
          //     isDense: true,
          //     contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          //     fillColor: const Color(0xFFF7F9F8),
          //     filled: true,
          //     border: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(8),
          //       borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          //     ),
          //     enabledBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(8),
          //       borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
          //     ),
          //     focusedBorder: OutlineInputBorder(
          //       borderRadius: BorderRadius.circular(8),
          //       borderSide: const BorderSide(color: _bookingGreen),
          //     ),
          //   ),
          //   onChanged: (val) => setState(() {}),
          // ),

          if (_quickSearchController.text.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSearchSuggestions(_quickSearchController.text.trim()),
          ],

          const SizedBox(height: 10),

          // The Route Selection Area (From & To)
          Stack(
            alignment: Alignment.centerRight,
            children: [
              Column(
                children: [
                  _buildRegionTile(
                    icon: Icons.trip_origin_rounded,
                    label: "From",
                    value: fromRegion,
                    color: _bookingGreen,
                    onTap: () => _openRegionPicker(
                      title: "From",
                      currentValue: fromRegion,
                      otherRegion: toRegion,
                      onSelected: (val) => setState(() => fromRegion = val),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildRegionTile(
                    icon: Icons.location_on_outlined,
                    label: "To",
                    value: toRegion,
                    color: _bookingGreen,
                    onTap: () => _openRegionPicker(
                      title: "To",
                      currentValue: toRegion,
                      otherRegion: fromRegion,
                      onSelected: (val) => setState(() => toRegion = val),
                    ),
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

  Widget _buildSearchSuggestions(String query) {
    final matches = tanzaniaRegions
        .where((r) => r.toLowerCase().contains(query.toLowerCase()))
        .take(4)
        .toList();

    if (matches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(10),
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE5E5E5)),
        ),
        child: const Text(
          'No matching regions found',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFD0E8DF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tap region to set:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _bookingGreen,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: matches.expand((region) {
              return [
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(
                    Icons.trip_origin_rounded,
                    size: 14,
                    color: _bookingGreen,
                  ),
                  label: Text(
                    'From: $region',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _bookingGreen),
                  onPressed: () {
                    if (region == toRegion) {
                      _showDifferentLocationsMessage();
                    } else {
                      setState(() {
                        fromRegion = region;
                        _quickSearchController.clear();
                      });
                    }
                  },
                ),
                ActionChip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: _bookingGreen,
                  ),
                  label: Text(
                    'To: $region',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: _bookingGreen),
                  onPressed: () {
                    if (region == fromRegion) {
                      _showDifferentLocationsMessage();
                    } else {
                      setState(() {
                        toRegion = region;
                        _quickSearchController.clear();
                      });
                    }
                  },
                ),
              ];
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _openRegionPicker({
    required String title,
    required String currentValue,
    required String otherRegion,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _RegionSearchSheet(
          title: title,
          currentValue: currentValue,
          otherRegion: otherRegion,
          onSelected: onSelected,
        );
      },
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

  Widget _buildRegionTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.search_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
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

class _RegionSearchSheet extends StatefulWidget {
  final String title;
  final String currentValue;
  final String otherRegion;
  final ValueChanged<String> onSelected;

  const _RegionSearchSheet({
    required this.title,
    required this.currentValue,
    required this.otherRegion,
    required this.onSelected,
  });

  @override
  State<_RegionSearchSheet> createState() => _RegionSearchSheetState();
}

class _RegionSearchSheetState extends State<_RegionSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredRegions = tanzaniaRegions;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredRegions = tanzaniaRegions;
      } else {
        _filteredRegions = tanzaniaRegions
            .where((region) => region.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.78,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD2D2D2),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Select ${widget.title} Region',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Type to search (e.g. Arusha, Dodoma)...',
                    prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF098E5F)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: _filteredRegions.isEmpty
                    ? const Center(
                        child: Text(
                          'No matching regions found',
                          style: TextStyle(color: AppColors.textMuted),
                        ),
                      )
                    : ListView.separated(
                        itemCount: _filteredRegions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final region = _filteredRegions[index];
                          final isSelected = region == widget.currentValue;
                          final isDisabled = region == widget.otherRegion;

                          return ListTile(
                            enabled: !isDisabled,
                            title: Text(
                              region,
                              style: TextStyle(
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? const Color(0xFF098E5F)
                                    : (isDisabled ? Colors.grey : AppColors.textPrimary),
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle_rounded, color: Color(0xFF098E5F))
                                : (isDisabled
                                    ? const Text(
                                        'Selected',
                                        style: TextStyle(fontSize: 11, color: Colors.grey),
                                      )
                                    : null),
                            onTap: isDisabled
                                ? null
                                : () {
                                    widget.onSelected(region);
                                    Navigator.pop(context);
                                  },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
