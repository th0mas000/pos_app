import 'package:flutter/material.dart';

// Configuration class for adaptive card layouts
class CardLayoutConfig {
  final bool useCompactLayout;
  final double imageHeight;
  final int titleMaxLines;
  final int descriptionMaxLines;
  final bool showFullDescription;
  final double horizontalPadding;
  final double verticalPadding;
  final int gridColumns;
  
  const CardLayoutConfig({
    required this.useCompactLayout,
    required this.imageHeight,
    required this.titleMaxLines,
    required this.descriptionMaxLines,
    required this.showFullDescription,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.gridColumns,
  });
}

class ResponsiveUtils {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;
  
  // Check device type based on screen width
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }
  
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }
  
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }
  
  // Check orientation
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }
  
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }
  
  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.all(24.0);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(20.0);
    } else {
      return const EdgeInsets.all(16.0);
    }
  }
  
  // Get responsive font size
  static double getResponsiveFontSize(BuildContext context, double baseFontSize) {
    if (isDesktop(context)) {
      return baseFontSize * 1.1;
    } else if (isTablet(context)) {
      return baseFontSize * 1.05;
    } else {
      return baseFontSize;
    }
  }
  
  // Get grid column count based on screen size and orientation
  static int getGridColumns(BuildContext context, {int baseColumns = 2}) {
    final isLandscapeMode = isLandscape(context);
    
    if (isDesktop(context)) {
      return isLandscapeMode ? baseColumns + 3 : baseColumns + 2;
    } else if (isTablet(context)) {
      return isLandscapeMode ? baseColumns + 2 : baseColumns + 1;
    } else {
      return isLandscapeMode ? baseColumns + 1 : baseColumns;
    }
  }
  
  // Check if should use wide layout (suitable for side-by-side content)
  static bool shouldUseWideLayout(BuildContext context) {
    return MediaQuery.of(context).size.width > 768;
  }
  
  // Get optimal navigation position for current screen configuration
  static String getOptimalNavigationPosition(BuildContext context, String currentPosition) {
    final isLandscapeMode = isLandscape(context);
    final width = MediaQuery.of(context).size.width;
    
    // For landscape on larger screens, prefer side navigation
    if (isLandscapeMode && width > 600) {
      if (currentPosition == 'bottom' || currentPosition == 'top') {
        return 'left';
      }
    }
    
    // For portrait on small screens, prefer bottom navigation
    if (!isLandscapeMode && width < 600) {
      if (currentPosition == 'left' || currentPosition == 'right') {
        return 'bottom';
      }
    }
    
    return currentPosition;
  }
  
  // Get responsive card elevation
  static double getCardElevation(BuildContext context) {
    if (isDesktop(context)) {
      return 4.0;
    } else {
      return 2.0;
    }
  }
  
  // Get responsive dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (isDesktop(context)) {
      return screenWidth * 0.4;
    } else if (isTablet(context)) {
      return screenWidth * 0.6;
    } else {
      return screenWidth * 0.9;
    }
  }
  
  // Get navigation rail width based on device type and orientation
  static double getNavigationRailWidth(BuildContext context) {
    final isLandscapeMode = isLandscape(context);
    
    if (isDesktop(context)) {
      return 100.0;
    } else if (isTablet(context)) {
      return 90.0;
    } else {
      // Mobile: Special handling for landscape mode
      if (isLandscapeMode) {
        return 95.0; // Wider in landscape for better usability
      } else {
        return 85.0; // Standard mobile width in portrait
      }
    }
  }
  
  // Calculate available content width when navigation is on the side
  static double getAvailableContentWidth(BuildContext context, String navigationPosition) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (navigationPosition == 'left' || navigationPosition == 'right') {
      return screenWidth - getNavigationRailWidth(context);
    }
    
    return screenWidth;
  }
  
  // Check if content area is constrained (narrow) due to side navigation
  static bool isContentAreaConstrained(BuildContext context, String navigationPosition) {
    final availableWidth = getAvailableContentWidth(context, navigationPosition);
    final isMobileDevice = isMobile(context);
    final isLandscapeMode = isLandscape(context);
    
    // Consider content constrained if:
    // 1. Mobile device in landscape with side navigation and available width < 450px
    // 2. Mobile device in portrait with side navigation and available width < 350px
    if (isMobileDevice && (navigationPosition == 'left' || navigationPosition == 'right')) {
      if (isLandscapeMode && availableWidth < 450) {
        return true;
      }
      if (!isLandscapeMode && availableWidth < 350) {
        return true;
      }
    }
    
    return false;
  }
  
  // Get adaptive card layout configuration for constrained content areas
  static CardLayoutConfig getCardLayoutConfig(BuildContext context, String navigationPosition) {
    final isConstrained = isContentAreaConstrained(context, navigationPosition);
    final isMobileDevice = isMobile(context);
    final isLandscapeMode = isLandscape(context);
    final availableWidth = getAvailableContentWidth(context, navigationPosition);
    
    if (isConstrained) {
      return CardLayoutConfig(
        useCompactLayout: true,
        imageHeight: isMobileDevice && isLandscapeMode ? 80.0 : 100.0,
        titleMaxLines: 1,
        descriptionMaxLines: 1,
        showFullDescription: false,
        horizontalPadding: 8.0,
        verticalPadding: 8.0,
        gridColumns: _getConstrainedGridColumns(availableWidth, isLandscapeMode),
      );
    }
    
    return CardLayoutConfig(
      useCompactLayout: false,
      imageHeight: 120.0,
      titleMaxLines: 2,
      descriptionMaxLines: 2,
      showFullDescription: true,
      horizontalPadding: 12.0,
      verticalPadding: 12.0,
      gridColumns: getGridColumns(context),
    );
  }
  
  // Calculate grid columns for constrained content areas
  static int _getConstrainedGridColumns(double availableWidth, bool isLandscape) {
    if (availableWidth < 300) {
      return 1; // Single column for very narrow spaces
    } else if (availableWidth < 450) {
      return isLandscape ? 2 : 1;
    } else {
      return isLandscape ? 3 : 2;
    }
  }
}

/// A widget that provides different layouts based on screen size
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isDesktop(context) && desktop != null) {
      return desktop!;
    } else if (ResponsiveUtils.isTablet(context) && tablet != null) {
      return tablet!;
    } else {
      return mobile;
    }
  }
}

/// A widget that adapts its layout based on orientation
class OrientationAwareLayout extends StatelessWidget {
  final Widget portrait;
  final Widget? landscape;
  
  const OrientationAwareLayout({
    super.key,
    required this.portrait,
    this.landscape,
  });
  
  @override
  Widget build(BuildContext context) {
    if (ResponsiveUtils.isLandscape(context) && landscape != null) {
      return landscape!;
    } else {
      return portrait;
    }
  }
}
