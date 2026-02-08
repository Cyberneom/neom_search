### 2.0.0 - Code Cleanup & Stability Improvements

This release focuses on code quality, cleanup, and improved maintainability.

**Code Cleanup:**

* **Removed Deprecated Code:**
    * Removed unused `buildMateTiles()`, `buildMediaTiles()`, and `buildReleaseTiles()` functions from search_widgets.dart.
    * Removed deprecated commented code (~45 lines) for cleaner codebase.

* **Improved Documentation:**
    * Added documentation comments to all widget builder functions explaining their purpose and navigation behavior.

**Bug Fixes:**

* **Memory Leak Prevention:**
    * Added proper `onClose()` implementation to cancel debounce timer and dispose scroll controller.
    * Ensures resources are properly released when search controller is disposed.

**Improvements:**

* **Translation Constants:**
    * Added `favoriteSongs` translation constant for future use.

* **Import Organization:**
    * Alphabetically sorted all import statements across the module for consistency.

---

### 1.0.0 - Initial Release & Decoupling from neom_home
This marks the initial official release (v1.0.0) of neom_search as a new, independent module within the Open Neom ecosystem. Previously, search functionalities were often integrated directly into the neom_home module or scattered across the main application. This decoupling is a crucial step in formalizing the search management layer, enhancing modularity, and strengthening Open Neom's adherence to Clean Architecture principles.

Key Highlights of this Release:

New Module Introduction & Specialization:

neom_search is now a dedicated module for all search processes, ensuring a clear separation of concerns from the main application shell (neom_home).

This allows for specialized development and maintenance of search-specific features.

Decoupling from neom_home:

Search logic and UI components have been entirely extracted and centralized into this module. This ensures that neom_home remains focused on its primary role as the navigation hub and that search responsibilities are clearly defined.

Centralized Search Functionality:

Provides a dedicated and robust interface for searching across various data types, including profiles, media items, and releases.

Supports dynamic filtering, location-based sorting, and integration with external search providers.

Module-Specific Translations:

Introduced SearchTranslationConstants to centralize and manage all UI text strings specific to search functionalities. This ensures improved localization, maintainability, and consistency with Open Neom's global strategy.

Enhanced Maintainability & Future Scalability:

As a dedicated and self-contained module, neom_search is now significantly easier to maintain, test, and extend for future search features (e.g., advanced filtering, search history, trending searches).

Any module requiring search capabilities can simply depend on neom_search and its SearchService.

Leverages Core Open Neom Modules:

Built upon neom_core for foundational services (like UserService, MateService, GoogleBookGatewayService) and neom_commons for reusable UI components and utilities, ensuring seamless integration within the ecosystem.
