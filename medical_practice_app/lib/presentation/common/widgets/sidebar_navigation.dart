import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../config/theme.dart';
import '../../../config/constants.dart';
import '../../../config/routes.dart';
import '../../../core/models/user_model.dart';

class SidebarNavigation extends StatefulWidget {
  final User user;
  final String currentRoute;
  final VoidCallback onLogout;
  
  const SidebarNavigation({
    Key? key,
    required this.user,
    required this.currentRoute,
    required this.onLogout,
  }) : super(key: key);

  @override
  _SidebarNavigationState createState() => _SidebarNavigationState();
}

class _SidebarNavigationState extends State<SidebarNavigation> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isExpanded = false;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: AppConstants.mediumAnimationDuration),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    
    // Decide if we should use expanded or collapsed sidebar based on screen width
    final isWideScreen = mediaQuery.size.width > 1200;
    final isTabletScreen = mediaQuery.size.width > 800 && mediaQuery.size.width <= 1200;
    
    // Set expanded state based on screen size
    if (isWideScreen && !_isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isExpanded = true;
          _animationController.forward();
        });
      });
    } else if (!isWideScreen && !isTabletScreen && _isExpanded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _isExpanded = false;
          _animationController.reverse();
        });
      });
    }
    
    // Calculate sidebar width
    final double collapsedWidth = 80.0;
    final double expandedWidth = 260.0;
    
    // Create animation for width
    final widthAnimation = Tween<double>(
      begin: collapsedWidth,
      end: expandedWidth,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    
    // Create animation for content opacity
    final contentOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Interval(0.5, 1.0, curve: Curves.easeInOut),
      ),
    );
    
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          width: widthAnimation.value,
          height: double.infinity,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(3, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // Profile Section
              _buildProfileSection(
                theme: theme,
                isExpanded: _isExpanded,
                widthAnimation: widthAnimation,
                contentOpacityAnimation: contentOpacityAnimation,
              ),
              
              const Divider(),
              
              // Navigation Items
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      _buildNavItem(
                        theme: theme,
                        icon: Icons.home_rounded,
                        label: 'Home',
                        route: AppRoutes.home,
                        widthAnimation: widthAnimation,
                        contentOpacityAnimation: contentOpacityAnimation,
                      ),
                      _buildNavItem(
                        theme: theme,
                        icon: Icons.dashboard_rounded,
                        label: 'Dashboard',
                        route: AppRoutes.dashboard,
                        widthAnimation: widthAnimation,
                        contentOpacityAnimation: contentOpacityAnimation,
                      ),
                      _buildNavItem(
                        theme: theme,
                        icon: Icons.medication_rounded,
                        label: 'Drugs',
                        route: AppRoutes.drugManagement,
                        widthAnimation: widthAnimation,
                        contentOpacityAnimation: contentOpacityAnimation,
                        isDisabled: !widget.user.hasPharmacyAccess,
                      ),
                      _buildNavItem(
                        theme: theme,
                        icon: Icons.science_rounded,
                        label: 'Lab Tests',
                        route: AppRoutes.labTestManagement,
                        widthAnimation: widthAnimation,
                        contentOpacityAnimation: contentOpacityAnimation,
                        isDisabled: !widget.user.hasLabAccess,
                      ),
                      _buildNavItem(
                        theme: theme,
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        route: AppRoutes.settings,
                        widthAnimation: widthAnimation,
                        contentOpacityAnimation: contentOpacityAnimation,
                      ),
                      
                      // Add spacer before logout
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              
              const Divider(),
              
              // Logout Button
              _buildLogoutButton(
                theme: theme,
                widthAnimation: widthAnimation,
                contentOpacityAnimation: contentOpacityAnimation,
              ),
              
              // Toggle Button (only shown on tablet)
              if (isTabletScreen)
                _buildToggleButton(theme),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildProfileSection({
    required ThemeData theme,
    required bool isExpanded,
    required Animation<double> widthAnimation,
    required Animation<double> contentOpacityAnimation,
  }) {
    return Container(
      height: 80,
      width: widthAnimation.value,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          // Profile Picture
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            backgroundImage: widget.user.profilePhotoUrl.isNotEmpty
                ? NetworkImage(widget.user.profilePhotoUrl)
                : null,
            child: widget.user.profilePhotoUrl.isEmpty
                ? Text(
                    widget.user.displayName.isNotEmpty
                        ? widget.user.displayName[0].toUpperCase()
                        : 'U',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppTheme.primaryColor,
                    ),
                  )
                : null,
          ),
          
          // Spacer
          SizedBox(width: isExpanded ? 12 : 0),
          
          // User Info (only shown when expanded)
          if (isExpanded)
            Expanded(
              child: Opacity(
                opacity: contentOpacityAnimation.value,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.user.displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.user.role.toUpperCase(),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildNavItem({
    required ThemeData theme,
    required IconData icon,
    required String label,
    required String route,
    required Animation<double> widthAnimation,
    required Animation<double> contentOpacityAnimation,
    bool isDisabled = false,
  }) {
    final isActive = widget.currentRoute == route;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: isDisabled ? null : () {
            if (widget.currentRoute != route) {
              Navigator.of(context).pushReplacementNamed(route);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Opacity(
            opacity: isDisabled ? 0.5 : 1.0,
            child: Container(
              width: double.infinity,
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: isActive
                    ? Border.all(color: AppTheme.primaryColor.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: Row(
                children: [
                  // Icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primaryColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      icon,
                      color: isActive
                          ? Colors.white
                          : theme.colorScheme.onBackground.withOpacity(0.7),
                      size: 22,
                    ),
                  ),
                  
                  // Spacer
                  SizedBox(width: _isExpanded ? 12 : 0),
                  
                  // Label (only shown when expanded)
                  if (_isExpanded)
                    Expanded(
                      child: Opacity(
                        opacity: contentOpacityAnimation.value,
                        child: Text(
                          label,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: isActive
                                ? AppTheme.primaryColor
                                : theme.colorScheme.onBackground,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                    
                  // Tooltip for disabled items
                  if (_isExpanded && isDisabled)
                    Opacity(
                      opacity: contentOpacityAnimation.value,
                      child: Tooltip(
                        message: 'This feature is not available with your current subscription',
                        child: Icon(
                          Icons.info_outline,
                          color: theme.colorScheme.onBackground.withOpacity(0.5),
                          size: 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildLogoutButton({
    required ThemeData theme,
    required Animation<double> widthAnimation,
    required Animation<double> contentOpacityAnimation,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: widget.onLogout,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                // Icon
                Icon(
                  Icons.logout_rounded,
                  color: AppTheme.error.withOpacity(0.8),
                  size: 22,
                ),
                
                // Spacer
                SizedBox(width: _isExpanded ? 12 : 0),
                
                // Label (only shown when expanded)
                if (_isExpanded)
                  Expanded(
                    child: Opacity(
                      opacity: contentOpacityAnimation.value,
                      child: Text(
                        'Logout',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.error.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildToggleButton(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _toggleExpanded,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: 40,
            child: Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _isExpanded ? math.pi : 0,
                    child: Icon(
                      Icons.keyboard_arrow_left,
                      color: theme.colorScheme.onBackground.withOpacity(0.7),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
