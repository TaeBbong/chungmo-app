/// Presented by the system share sheet. Persists the shared text, URL, or
/// image into the app-group container, then redirects into the main app,
/// which starts parsing the invitation right away.
///
/// RSIShareViewController is vendored in this target — see the note in
/// RSIShareViewController.swift.
class ShareViewController: RSIShareViewController {
    // Skip the compose sheet: chungmo has nothing to edit before parsing.
    override func shouldAutoRedirect() -> Bool {
        return true
    }
}
