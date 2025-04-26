import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../../data/models/doctor_settings_model.dart';

class NavigationSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final DoctorSettings? doctorSettings;

  const NavigationSidebar({
    Key? key,
    required this.selectedIndex,
    required this.onItemSelected,
    this.doctorSettings,
  }) : super(key: key);

  @override
  State<NavigationSidebar> createState() => _NavigationSidebarState();
}

class _NavigationSidebarState extends State<NavigationSidebar> {
  int _hoveredIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: Colors.white,
      child: Column(
        children: [
          const SizedBox(height: 20),
          _buildProfileSection(),
          const SizedBox(height: 40),
          _buildNavigationItems(),
          const Spacer(),
          _buildLogoutButton(),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildProfileSection() {
    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
          backgroundImage: widget.doctorSettings?.profilePicPath != null
              ? AssetImage(widget.doctorSettings!.profilePicPath!)
              : null,
          child: widget.doctorSettings?.profilePicPath == null
              ? const Icon(
                  Icons.person,
                  size: 40,
                  color: AppTheme.primaryColor,
                )
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          widget.doctorSettings?.name ?? 'Doctor Name',
          style: AppTheme.subheadingStyle,
          textAlign: TextAlign.center,
        ),
        if (widget.doctorSettings?.specialty != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.doctorSettings!.specialty!,
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textLightColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
      ],
    );
  }

  Widget _buildNavigationItems() {
    return Column(
      children: [
        _buildNavigationItem(
          0,
          'Home',
          Icons.home_outlined,
          Icons.home,
        ),
        _buildNavigationItem(
          1,
          'Dashboard',
          Icons.dashboard_outlined,
          Icons.dashboard,
        ),
        _buildNavigationItem(
          2,
          'Drugs',
          Icons.medication_outlined,
          Icons.medication,
        ),
        _buildNavigationItem(
          3,
          'Lab Tests',
          Icons.science_outlined,
          Icons.science,
        ),
        _buildNavigationItem(
          4,
          'Settings',
          Icons.settings_outlined,
          Icons.settings,
        ),
      ],
    );
  }

  Widget _buildNavigationItem(
    int index,
    String title,
    IconData normalIcon,
    IconData selectedIcon,
  ) {
    final isSelected = widget.selectedIndex == index;
    final isHovered = _hoveredIndex == index;
    final showSelected = isSelected || isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () => widget.onItemSelected(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: showSelected
                ? AppTheme.primaryColor.withOpacity(isSelected ? 1.0 : 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                showSelected ? selectedIcon : normalIcon,
                color: showSelected
                    ? (isSelected ? Colors.white : AppTheme.primaryColor)
                    : AppTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: showSelected
                      ? (isSelected ? Colors.white : AppTheme.primaryColor)
                      : AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = 999),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: GestureDetector(
        onTap: () {
          // TODO: Implement logout functionality
          Navigator.of(context).pushReplacementNamed('/login');
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 15),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
          decoration: BoxDecoration(
            color: _hoveredIndex == 999
                ? AppTheme.warningColor.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(
                Icons.logout,
                color: _hoveredIndex == 999
                    ? AppTheme.warningColor
                    : AppTheme.textColor,
                size: 24,
              ),
              const SizedBox(width: 15),
              Text(
                'Logout',
                style: AppTheme.bodyStyle.copyWith(
                  fontWeight: FontWeight.w500,
                  color: _hoveredIndex == 999
                      ? AppTheme.warningColor
                      : AppTheme.textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}