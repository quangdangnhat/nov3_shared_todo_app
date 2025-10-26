import 'package:flutter/widgets.dart';

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget desktop;


  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    required this.desktop,
  });

  // imposto le diverse larghezze per distinguere il dispositivo che si sta usando 
  // break point width of the devices
  static const double mobileBreakpoint = 904;
  static const double desktopBreakpoint = 1280;

// funzioni per facilitare l'utilizzo quando devo modificare l'UI in base al dispositivo
// functions to make the code easier to read and use depending the device.   
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width < desktopBreakpoint &&
      MediaQuery.sizeOf(context).width >= mobileBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  // Helper per ottenere il tipo di dispositivo
  //Helpr to get the device type 
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return DeviceType.desktop;
    if (width >= mobileBreakpoint) return DeviceType.tablet;
    return DeviceType.mobile;
  }

  // Helper Responsive Values
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    required T desktop,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= desktopBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet ?? mobile;
    return mobile;
  }
// WHY IS IT USEFULL ? :
/*
 
WITHOUT THE HELPER:
double getFontSize(BuildContext context) {
  if (ResponsiveLayout.isDesktop(context)) {
    return 32.0;
  } else if (ResponsiveLayout.isTablet(context)) {
    return 24.0;
  } else {
    return 16.0;
  }
}
Text(
  'Ciao',
  style: TextStyle(fontSize: getFontSize(context)),
)

WITH THE HELPER: 
Text(
  'Ciao',
  style: TextStyle(
    fontSize: ResponsiveLayout.responsive<double>(
      context,
      mobile: 16,
      tablet: 24,
      desktop: 32,
    ),
  ),
)
*/

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;

    if (width >= desktopBreakpoint) return desktop;
    if (width >= mobileBreakpoint && tablet != null) return tablet!;
    return mobile;
  }
}

enum DeviceType { mobile, tablet, desktop } // to avoid the use of ( if/else )  


