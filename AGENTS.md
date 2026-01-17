# Developer Guidelines & Commands

This repository hosts a Ruby on Rails 8.1 application using Hotwire (Turbo + Stimulus) and Tailwind CSS.

## 🛠 Build, Lint, and Test Commands

### Development Server
Start the full development stack (Web server, CSS watcher, etc.):
```bash
bin/dev
```
*Note: This uses `Procfile.dev` to manage processes including Puma and Tailwind watcher.*

### Testing (Minitest)
The project uses the standard Minitest framework.
Run all tests:
```bash
bin/rails test
```

Run a specific test file:
```bash
bin/rails test test/models/user_test.rb
```

Run a specific test method (by line number):
```bash
bin/rails test test/models/user_test.rb:25
```

Run system tests (using Capybara/Selenium):
```bash
bin/rails test:system
```

### Linting & Formatting
This project uses the `standard` gem for strict Ruby linting and formatting.

Check code style:
```bash
bundle exec standardrb
```

Auto-fix code style issues:
```bash
bundle exec standardrb --fix
```

### Security Checks
Run security vulnerability scans to ensure code safety:
```bash
# Static analysis (Brakeman)
bundle exec brakeman

# Dependency audit
bundle exec bundle-audit
```

## 📐 Code Style & Conventions

### Ruby / Rails
*   **Formatting:** Indentation is 2 spaces. No hard tabs. No trailing commas in multiline arrays, hashes, or method arguments.
*   **Strings:** Use double quotes `"` by default (following `standardrb` preference).
*   **Hash Syntax:** Use Ruby 1.9+ syntax (e.g., `{key: value}`).
*   **Methods:** Omit parentheses for method calls without arguments.
*   **Naming:**
    *   Classes/Modules: `CamelCase` (e.g., `Unit::Importer`).
    *   Variables/Methods: `snake_case`.
    *   Files: `snake_case.rb`.
    *   Controllers: Plural (e.g., `UsersController`, `Admin::UsersController`).
    *   Models: Singular (e.g., `User`, `Organization`).
*   **Organization:**
    *   **Models:** Put macros (`belongs_to`, `validates`, `enum`) at the top.
    *   **Controllers:** Use `before_action` for setup/auth. Use `private` for internal methods like `set_resource` or strong parameters.
    *   **Concerns:** Use `ActiveSupport::Concern` for shared behavior.
    *   **Service Objects:** Place complex business logic in POROs in `app/models/`.
    *   **Structure:** No empty lines after `class` or `module` definitions.
*   **Logic & Style:**
    *   Use `.nil?` for nil checks (avoid `== nil`).
    *   Avoid Yoda conditions (e.g., use `if x == 1` not `if 1 == x`).
    *   Implicit returns are preferred. Use explicit `return` only for guard clauses.
*   **Error Handling:** Use exceptions for exceptional cases (e.g., `ActiveRecord::RecordNotFound`). Use `tap` or `if object.save` for expected flow control.
*   **Database:** Use `bigint` for IDs. Enforce foreign keys. Always include `null: false` and indexes where appropriate in migrations.

### Frontend (Hotwire + Tailwind)
*   **HTML/ERB:** Use semantic HTML. Use Rails helpers (`link_to`, `form_with`) where appropriate. Use `dom_id` for consistent IDs.
*   **CSS:** Use Tailwind utility classes directly in markup. Avoid custom CSS files.
*   **JavaScript:** Use Stimulus controllers in `app/javascript/controllers`. Follow naming convention: `search_controller.js` maps to `data-controller="search"`.
*   **Turbo:** Use `Turbo.visit` for navigation and `turbo_stream` for partial updates. Prefer standard HTML responses unless a dynamic update is required.

### Testing
*   **Framework:** Minitest.
*   **Fixtures:** Use Rails fixtures (`test/fixtures/*.yml`) for test data.
*   **Parallelization:** Tests run in parallel by default.
*   **Integration:** Use `ActionDispatch::IntegrationTest` for controller/request specs. Ensure tests are idempotent.

## 🏗 Project Structure & Architecture

### Key Directories
*   `app/models`: Business logic. Includes namespaced models (e.g., `Unit::Importer`).
*   `app/controllers`: Request handling. Organized by namespace (`Admin::`, `Manage::`).
*   `app/javascript`: Stimulus controllers and JS entry points.
*   `app/views`: ERB templates and partials.
*   `db`: Database schema (`schema.rb`) and migrations.
*   `test`: Minitest files (`models`, `controllers`, `system`, `fixtures`).

### Key Architectural Decisions
*   **Authentication:** Custom implementation using `has_secure_password` and `Current.user`.
    *   Routes: `login`, `signup`, `logout`.
    *   Uses `ActiveSupport::CurrentAttributes` for thread-safe user access.
*   **Authorization/Roles:** Enum-based roles on models (e.g., `User#role` with `super_admin`, `org_admin`, etc.).
*   **Background Jobs:** `Solid Queue` (DB-backed) is used for job processing.
*   **Caching:** `Solid Cache` (DB-backed) is used.
*   **Deployment:** `Kamal` is used for deployment (`config/deploy.yml`).

## 📝 Workflow for Agents
1.  **Read:** Understand the context (models, schema, existing tests).
2.  **Plan:** Outline changes, migrations, and UI updates.
3.  **Test:** Write/Update tests (`test/`). Use `bin/rails test` frequently.
4.  **Implement:** Write code in `app/`. Strictly follow `standardrb`.
5.  **Verify:** Run `bin/rails test`, `bundle exec standardrb`, and `bundle exec brakeman`.
6.  **Refactor:** Ensure code is DRY and follows Rails conventions.
