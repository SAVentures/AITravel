/*
 Route value for the wallet booking detail. Carries only the id the destination needs to look the
 booking up on the store graph — never the model itself (06-screens §5). One Route per file, `Hashable`,
 registered with `.navigationDestination(for:)` at the Trip tab root (RootView, Task 3.0 / 3.1); pushed
 via `store.push(BookingDetailRoute(id:))` onto the Trip tab's path.
*/
import Foundation

struct BookingDetailRoute: Hashable {
    let id: BookingModel.ID
}
