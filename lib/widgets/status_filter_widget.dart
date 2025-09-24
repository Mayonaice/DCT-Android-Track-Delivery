import 'package:flutter/material.dart';
import '../models/status_master.dart';

class StatusFilterWidget extends StatelessWidget {
  final StatusFilterOption selectedOption;
  final Function(StatusFilterOption) onOptionSelected;

  const StatusFilterWidget({
    Key? key,
    required this.selectedOption,
    required this.onOptionSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Status',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    size: 24,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Colors.grey[200],
          ),
          
          // Options List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: StatusFilterOption.options.length,
              itemBuilder: (context, index) {
                final option = StatusFilterOption.options[index];
                final isSelected = selectedOption.statusId == option.statusId;
                
                return GestureDetector(
                  onTap: () {
                    onOptionSelected(option);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          option.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? const Color(0xFF10B981) : Colors.grey[400]!,
                              width: 2,
                            ),
                            color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(
                                  Icons.check,
                                  size: 12,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Function to show status filter bottom sheet
void showStatusFilter(
  BuildContext context,
  StatusFilterOption currentOption,
  Function(StatusFilterOption) onOptionSelected,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => StatusFilterWidget(
      selectedOption: currentOption,
      onOptionSelected: onOptionSelected,
    ),
  );
}