import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../search/domain/entities/bus.dart';
import 'payment_page.dart';

class PassengerDetailsPage extends StatefulWidget {
  final Bus bus;
  final List<String> selectedSeats;
  final DateTime travelDate;

  const PassengerDetailsPage({
    super.key,
    required this.bus,
    required this.selectedSeats,
    required this.travelDate,
  });

  @override
  State<PassengerDetailsPage> createState() => _PassengerDetailsPageState();
}

class _PassengerDetailsPageState extends State<PassengerDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _nameControllers = [];
  final List<String> _genders = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nidaController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  String _networkProvider = "Unknown";
  Color _providerColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    for (var i = 0; i < widget.selectedSeats.length; i++) {
      _nameControllers.add(TextEditingController());
      _genders.add('Male');
    }
    _phoneController.addListener(_determineProvider);
  }

  void _determineProvider() {
    String val = _phoneController.text;
    if (val.length >= 3) {
      String prefix = val.substring(0, 3);
      setState(() {
        if (["074", "075", "076"].contains(prefix)) {
          _networkProvider = "VODACOM (M-PESA)";
          _providerColor = Colors.red;
        } else if (["065", "067", "071"].contains(prefix)) {
          _networkProvider = "TIGO (Mix By Yas)";
          _providerColor = Colors.blue;
        } else if (["068", "069", "078"].contains(prefix)) {
          _networkProvider = "AIRTEL (AIRTEL MONEY)";
          _providerColor = Colors.red.shade900;
        } else if (["062", "061"].contains(prefix)) {
          _networkProvider = "HALOTEL (HALOPESA)";
          _providerColor = Colors.orange;
        } else if (["073"].contains(prefix)) {
          _networkProvider = "TTCL (T-PESA)";
          _providerColor = Colors.blue.shade900;
        } else {
          _networkProvider = "Unknown";
          _providerColor = Colors.grey;
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _nameControllers) {
      controller.dispose();
    }
    _phoneController.dispose();
    _nidaController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBusSummary(),
                    const SizedBox(height: 32),
                    _buildSectionHeader("IDENTITY VERIFICATION"),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _nidaController,
                      label: "NIDA Number (20 Digits)",
                      icon: Icons.fingerprint_rounded,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.length != 20) {
                          return "Valid 20-digit NIDA required";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    _buildSectionHeader("PASSENGER DETAILS"),
                    const SizedBox(height: 16),
                    ...List.generate(widget.selectedSeats.length, (index) {
                      return FadeInUp(
                        delay: Duration(milliseconds: index * 100),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: AppColors.softShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withAlpha(26),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      widget.selectedSeats[index],
                                      style: const TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text("PASSENGER ${index + 1}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14,
                                          color: AppColors.textPrimary)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _nameControllers[index],
                                label: "Full Name (As per NIDA)",
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  _genderOption(
                                      index, 'Male', Icons.male_rounded),
                                  const SizedBox(width: 12),
                                  _genderOption(
                                      index, 'Female', Icons.female_rounded),
                                  const SizedBox(width: 12),
                                  _genderOption(
                                      index, 'Child', Icons.child_care_rounded),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    _buildSectionHeader("PAYMENT CONTACT"),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        children: [
                          _buildTextField(
                            controller: _phoneController,
                            label: "Phone Number",
                            icon: Icons.phone_android_rounded,
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.length < 10) {
                                return "Enter valid number";
                              }
                              return null;
                            },
                          ),
                          if (_networkProvider != "Unknown")
                            FadeInDown(
                              child: Container(
                                margin: const EdgeInsets.only(top: 12),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _providerColor.withAlpha(13),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: _providerColor.withAlpha(51)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.verified_user_rounded,
                                        color: _providerColor, size: 16),
                                    const SizedBox(width: 12),
                                    Text(_networkProvider,
                                        style: TextStyle(
                                            color: _providerColor,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 11,
                                            letterSpacing: 0.5)),
                                  ],
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _emailController,
                            label: "Email Address",
                            icon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildBottomAction(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: AppColors.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const Text(
          "PASSENGER INFO",
          style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2),
        ),
        background: Container(
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient)),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
          color: AppColors.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(13),
              blurRadius: 20,
              offset: const Offset(0, -5))
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: AppColors.premiumShadow,
          ),
          child: ElevatedButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PaymentPage(
                      bus: widget.bus,
                      selectedSeats: widget.selectedSeats,
                      passengerNames:
                          _nameControllers.map((c) => c.text).toList(),
                      phone: _phoneController.text,
                      travelDate: widget.travelDate,
                    ),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
            ),
            child: const Text("PROCEED TO PAYMENT",
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1)),
          ),
        ),
      ),
    );
  }

  Widget _genderOption(int passengerIndex, String label, IconData icon) {
    bool isSelected = _genders[passengerIndex] == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _genders[passengerIndex] = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isSelected ? AppColors.primary : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  size: 20),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isSelected ? Colors.white : AppColors.textSecondary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBusSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(26),
                borderRadius: BorderRadius.circular(14)),
            child: const Icon(Icons.directions_bus_rounded,
                color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.bus.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.textPrimary)),
                Text(
                    "${widget.bus.type} • ${widget.selectedSeats.length} Seats",
                    style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(
            "TZS ${(widget.selectedSeats.length * widget.bus.price).toStringAsFixed(0)}",
            style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
        validator: validator ??
            (value) => value == null || value.isEmpty ? "Required" : null,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600),
          prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Colors.transparent,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }
}
