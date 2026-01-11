# Authorization Tests

## Test Strategy

We use **Controller Tests** (Integration Tests) for authorization testing because:

1. **Faster execution** - Controller tests run much faster than system tests
2. **Focused on authorization** - Directly test the authorization logic without browser overhead
3. **Easy role testing** - Can quickly test different user roles and scenarios
4. **Better coverage** - Can test edge cases and error conditions more easily

## Test Coverage

### Admin Namespace Tests
- `test/controllers/admin/base_controller_test.rb` - Tests that only super_admin can access /admin routes
- `test/controllers/admin/organizations_controller_test.rb` - Tests organization CRUD for super_admin
- `test/controllers/admin/users_controller_test.rb` - Tests user management for super_admin
- `test/controllers/admin/units_controller_test.rb` - Tests unit management for super_admin
- `test/controllers/admin/bills_controller_test.rb` - Tests bill viewing for super_admin
- `test/controllers/admin/payments_controller_test.rb` - Tests payment viewing for super_admin

### Manage Namespace Tests
- `test/controllers/manage/organizations_controller_test.rb` - Tests organization access for org_admin/org_manager
- `test/controllers/manage/users_controller_test.rb` - Tests user creation restrictions (org_admin only, within their org)
- `test/controllers/manage/units_controller_test.rb` - Tests unit management scoped to organizations

### Permission Model Tests
- `test/models/user/permissions_test.rb` - Tests all permission methods with different user roles

## Running Tests

```bash
# Run all tests
bin/rails test

# Run specific test file
bin/rails test test/controllers/admin/base_controller_test.rb

# Run all authorization tests
bin/rails test test/controllers/admin test/controllers/manage test/models/user/permissions_test.rb

# Run with verbose output
bin/rails test --verbose
```

## Test Fixtures

Test fixtures are defined in:
- `test/fixtures/users.yml` - Users with different roles (super_admin, org_admin, org_manager, resident)
- `test/fixtures/organizations.yml` - Test organizations
- `test/fixtures/organization_memberships.yml` - Organization memberships for testing scoping

## Key Test Scenarios

1. **Super Admin Access**: Can access all /admin routes, all organizations, all resources
2. **Org Admin Restrictions**: Can only access their own organizations, can create users only for their orgs
3. **Org Manager Restrictions**: Cannot access /admin routes, cannot create users, can access /manage routes
4. **Resident Restrictions**: Cannot access /admin or /manage routes
5. **Organization Scoping**: Users can only access resources from organizations they belong to
6. **Cross-Organization Access**: Users cannot access resources from other organizations
