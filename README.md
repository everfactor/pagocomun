# Pagocomun

## Tech Stack

- **Ruby**: 3.4.7
- **Rails**: 8.1.1
- **Database**: PostgreSQL
- **Frontend**: Tailwind CSS, Hotwire (Turbo + Stimulus)
- **Asset Pipeline**: Propshaft
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable
- **Server**: Puma with Thruster

## Prerequisites

- Ruby 3.4.7 (use [rbenv](https://github.com/rbenv/rbenv) or [rvm](https://rvm.io/))
- PostgreSQL 12+
- Node.js 18+ (for Tailwind CSS)
- Bundler gem

## Getting Started

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd pagocomun
   ```

2. Install dependencies:
   ```bash
   bundle install
   ```

3. Set up the database:
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   ```

4. (Optional) Seed the database:
   ```bash
   bin/rails db:seed
   ```

### Quick Setup

Run the setup script to install dependencies and prepare the database:

```bash
bin/setup
```

This will:
- Install gem dependencies
- Prepare the database
- Clear old logs and temp files
- Start the development server

To reset the database during setup:

```bash
bin/setup --reset
```

To skip starting the server:

```bash
bin/setup --skip-server
```

## Development

### Running the Server

Start the development server:

```bash
bin/dev
```

Or use Rails directly:

```bash
bin/rails server
```

The application will be available at `http://localhost:3000`.

### Running Tests

Run the test suite:

```bash
bin/rails test
```

Run system tests:

```bash
bin/rails test:system
```


## Configuration

### Database

Database configuration is in `config/database.yml`. Make sure PostgreSQL is running and update the credentials if needed.

### Environment Variables

The application uses Rails encrypted credentials. To edit them:

```bash
EDITOR="code --wait" bin/rails credentials:edit
```

### Master Key

For production, ensure `config/master.key` is set or provide `RAILS_MASTER_KEY` as an environment variable.

## Docker

### Development with Dev Containers

This project includes Dev Container configuration. Open the project in VS Code and use the "Reopen in Container" option.

### Prerequisites

- Docker installed on the deployment server

## Services

This application uses database-backed adapters for:

- **Cache**: Solid Cache (stored in PostgreSQL)
- **Background Jobs**: Solid Queue (stored in PostgreSQL)
- **WebSockets**: Solid Cable (stored in PostgreSQL)

