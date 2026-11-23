abstract class EntitlementService {
  const EntitlementService();

  bool get canCloudSync;
  bool get canExportPdf;
  bool get hasProThemes;
}

class FreeEntitlementService extends EntitlementService {
  const FreeEntitlementService();

  @override
  bool get canCloudSync => false;

  @override
  bool get canExportPdf => false;

  @override
  bool get hasProThemes => false;
}
