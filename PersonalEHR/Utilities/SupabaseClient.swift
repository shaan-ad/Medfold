import Foundation
import Supabase

enum AppSupabase {
    static let client = SupabaseClient(
        supabaseURL: URL(string: Constants.supabaseURL)!,
        supabaseKey: Constants.supabaseAnonKey
    )
}
