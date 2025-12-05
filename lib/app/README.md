# App Architecture

## Navigation and Transitions

### Route Classification

The app uses two distinct navigation patterns:

1. **Tab Routes** (`/`, `/progress`, `/profile`, `/discover`, `/resources`, `/demo`):
   - Managed by `AppShell` with a stable AppBar and bottom navigation bar
   - Use **tab fade transitions** (via `TabFadeSwitcher`) when switching between tabs
   - Content-only fade (AppBar remains stable)
   - Defined in `TabPageRegistry` and rendered via `TabPageDescriptor`

2. **Detail Routes** (e.g., `/profile/settings`, `/progress/weight`):
   - Full-screen pages with their own `Scaffold` and `AppBar`
   - Use **horizontal slide transitions** (via `AppPageTransitions.bidirectionalSlide`)
   - Do **not** use `AppShell` or the bottom navigation bar (they are top-level routes, outside the `ShellRoute`)

### Adding New Routes

**For tab routes:**
- Add route classification in `TabPageRegistry._isHomeRoute`, `_isProgressRoute`, etc.
- Add tab page builder in `TabPageRegistry` (e.g., `_buildHomeTabPage`)
- In `router.dart`, register them as children of the `ShellRoute` using `NoTransitionPage` (tab fade is handled inside `AppShell` via `TabFadeSwitcher`)

**For detail routes:**
- Declare them as **top-level `GoRoute`s outside the `ShellRoute`** (e.g., `/profile/settings`, `/progress/weight`)
- (Optional but recommended) Add the path to `TabPageRegistry._isNonTabRoute` for consistent classification
- Use `AppPageTransitions.bidirectionalSlide` in the route `pageBuilder`
- Navigate with `context.push()` or `context.pushNamed()` (not `go()`) so push/pop slide transitions can run

### Transition Implementation

- **Tab fade**: `TabFadeSwitcher` in `app_page_transitions.dart` (150ms, easeInOut)
- **Page slide**: `SlideTransitionPage` with centralized constants (`AppAnimations.pageSlideDuration`, `AppAnimations.pageSlideCurve`; configured in `app_animations.dart`)
- Both respect system "Reduce Motion" settings automatically
