/// Lightweight values stored in a tab's navigation history.
///
/// Routes contain identifiers rather than view instances, so they remain
/// testable and can later be used by deep links without changing the shell.
enum AppRoute: Hashable {
    case personalizedPlan
}
