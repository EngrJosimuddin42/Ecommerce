import 'package:flutter/material.dart';

class SpecificationSection extends StatefulWidget {
  final TextEditingController brandController;
  final TextEditingController materialController;
  final TextEditingController warrantyController;
  final TextEditingController availabilityController;
  final TextEditingController shipsFromController;

  const SpecificationSection({
    Key? key,
    required this.brandController,
    required this.materialController,
    required this.warrantyController,
    required this.availabilityController,
    required this.shipsFromController,
  }) : super(key: key);

  @override
  State<SpecificationSection> createState() => _SpecificationSectionState();
}

class _SpecificationSectionState extends State<SpecificationSection> {
  bool _showSpecs = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _showSpecs = !_showSpecs),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), // আগের 8 -> 6
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Specifications",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Icon(
                  _showSpecs ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4), // আগের 6 -> 4
        // ⚡ Impeller-safe wrapper
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState:
          _showSpecs ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Material(
            color: Colors.transparent, // Impeller-safe
            child: Container(
              padding: const EdgeInsets.all(8), // আগের 10 -> 8
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildField("Brand", widget.brandController),
                  _buildField("Material", widget.materialController),
                  _buildField("Warranty", widget.warrantyController),
                  _buildField("Availability", widget.availabilityController),
                  _buildField("Ships From", widget.shipsFromController),
                ],
              ),
            ),
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0), // আগের 4 -> 3
      child: TextFormField(
        controller: controller,
        style: const TextStyle(fontSize: 14), // ছোট font size
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 13),
          contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10), // height কমানো
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
