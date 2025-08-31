import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

class AdaptiveNavigationLayout extends StatelessWidget {
  final Widget body;
  final int currentIndex;
  final Function(int) onDestinationSelected;
  final List<NavigationDestination> destinations;
  final String position;

  const AdaptiveNavigationLayout({
    super.key,
    required this.body,
    required this.currentIndex,
    required this.onDestinationSelected,
    required this.destinations,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    // Check if the current navigation position causes content area to be too constrained
    final isConstrained = ResponsiveUtils.isContentAreaConstrained(context, position);
    final isMobile = ResponsiveUtils.isMobile(context);
    
    // For mobile devices, show a warning overlay when content is too constrained
    Widget bodyWithOptionalWarning = body;
    if (isMobile && isConstrained) {
      bodyWithOptionalWarning = Stack(
        children: [
          body,
          _buildConstrainedWarning(context),
        ],
      );
    }

    // Use the user's preferred position directly, without auto-adaptation
    // The user should have full control over navigation position
    switch (position) {
      case 'top':
        return _buildTopNavigation(context, bodyWithOptionalWarning);
      case 'left':
        return _buildSideNavigation(context, bodyWithOptionalWarning, isLeft: true);
      case 'right':
        return _buildSideNavigation(context, bodyWithOptionalWarning, isLeft: false);
      case 'bottom':
      default:
        return _buildBottomNavigation(context, bodyWithOptionalWarning);
    }
  }

  Widget _buildConstrainedWarning(BuildContext context) {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.amber.withOpacity(0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 16,
              color: Colors.amber[800],
            ),
            const SizedBox(width: 4),
            Text(
              'พื้นที่แสดงผลถูกบีบอัด',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.amber[800],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, [Widget? customBody]) {
    return Scaffold(
      body: customBody ?? body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: onDestinationSelected,
        destinations: destinations,
      ),
    );
  }

  Widget _buildTopNavigation(BuildContext context, [Widget? customBody]) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: SafeArea(
              bottom: false,
              child: NavigationBar(
                selectedIndex: currentIndex,
                onDestinationSelected: onDestinationSelected,
                destinations: destinations,
                backgroundColor: Colors.transparent,
                elevation: 0,
              ),
            ),
          ),
          Expanded(child: customBody ?? body),
        ],
      ),
    );
  }

  Widget _buildSideNavigation(BuildContext context, Widget? customBody, {required bool isLeft}) {
    return Scaffold(
      body: Row(
        children: [
          if (isLeft) _buildNavigationRail(context),
          Expanded(child: customBody ?? body),
          if (!isLeft) _buildNavigationRail(context),
        ],
      ),
    );
  }

  Widget _buildNavigationRail(BuildContext context) {
    // Improved sizing for mobile devices
    final isMobile = ResponsiveUtils.isMobile(context);
    final isLandscapeMode = ResponsiveUtils.isLandscape(context);
    
    double railWidth;
    if (ResponsiveUtils.isDesktop(context)) {
      railWidth = 100.0;
    } else if (ResponsiveUtils.isTablet(context)) {
      railWidth = 90.0;
    } else {
      // Mobile: Special handling for landscape mode
      // In landscape mode, we have more horizontal space but less vertical space
      // So make the rail wider but optimize for touch targets
      if (isLandscapeMode) {
        railWidth = 95.0; // Wider in landscape for better usability
      } else {
        railWidth = 85.0; // Standard mobile width in portrait
      }
    }
    
    return Container(
      width: railWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isMobile ? 0.15 : 0.1), // Stronger shadow on mobile
            blurRadius: isMobile ? 8 : 4, // More blur on mobile for better definition
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            // พื้นที่ว่างด้านบน
            const SizedBox(height: 16),
            
            // ปุ่มเมนูที่กระจายเท่าๆ กัน
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: destinations.asMap().entries.map((entry) {
                  final index = entry.key;
                  final destination = entry.value;
                  final isSelected = index == currentIndex;
                  
                  return _buildRailButton(
                    context: context,
                    destination: destination,
                    isSelected: isSelected,
                    onTap: () => onDestinationSelected(index),
                    railWidth: railWidth,
                  );
                }).toList(),
              ),
            ),
            
            // พื้นที่ว่างด้านล่าง
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildRailButton({
    required BuildContext context,
    required NavigationDestination destination,
    required bool isSelected,
    required VoidCallback onTap,
    required double railWidth,
  }) {
    final isMobile = ResponsiveUtils.isMobile(context);
    final isLandscape = ResponsiveUtils.isLandscape(context);
    
    return Flexible(
      child: Container(
        constraints: BoxConstraints(
          // In landscape mode on mobile, optimize for smaller heights
          minHeight: isMobile 
            ? (isLandscape ? 60 : 70) // Smaller height in landscape
            : 60, 
          maxHeight: isMobile 
            ? (isLandscape ? 80 : 90) // Smaller max height in landscape
            : railWidth + 20,
        ),
        margin: EdgeInsets.symmetric(
          vertical: isMobile 
            ? (isLandscape ? 3 : 6) // Less vertical margin in landscape
            : 4, 
          horizontal: isMobile ? 6 : 8,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              vertical: isMobile 
                ? (isLandscape ? 6 : 10) // Less vertical padding in landscape
                : 8, 
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.8)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                      width: 1,
                    )
                  : null,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(
                    isMobile 
                      ? (isLandscape ? 6 : 8) // Smaller icon padding in landscape
                      : (railWidth > 85 ? 10 : 8)
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: isSelected
                      ? (destination.selectedIcon ?? destination.icon)
                      : destination.icon,
                ),
                SizedBox(
                  height: isMobile 
                    ? (isLandscape ? 4 : 8) // Less spacing in landscape
                    : 6
                ), 
                Flexible(
                  child: Text(
                    destination.label,
                    style: TextStyle(
                      fontSize: isMobile 
                        ? (isLandscape ? 10 : 11) // Smaller font in landscape
                        : (railWidth > 85 ? 12 : 11),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: isLandscape && isMobile ? 1 : 2, // Single line in mobile landscape
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
