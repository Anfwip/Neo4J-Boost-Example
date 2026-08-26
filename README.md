# Koel × Neo4j Laravel Boost — Example Repository

[![Frontend Unit Tests](https://github.com/koel/koel/actions/workflows/unit-frontend.yml/badge.svg)](https://github.com/koel/koel/actions/workflows/unit-frontend.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE.md)

![Koel Showcase](https://user-images.githubusercontent.com/8056274/115028055-bc02a280-9ec4-11eb-991c-69cd2a45b69c.png)

---

## What Is This Repo?

This is a **ready-to-run demonstration** of the [`neo4j/laravel-boost`](https://github.com/neo4j-php/neo4j-boost) package integrated into **[Koel](https://github.com/koel/koel)**, a real-world, MIT-licensed, open-source Laravel music-streaming application.

It shows how Neo4j Laravel Boost lets any MCP-compatible AI coding assistant (Cursor, Claude Code, etc.) query your **live Neo4j graph database** and your **Laravel container's dependency graph** — all through a single, already-configured MCP server entry (`php artisan boost:mcp`).

### What Is Koel?

Koel is a free, open-source music-streaming solution built on **Laravel 13** and **Vue 3**. It scans a local music library and serves it through a sleek, modern web interface. It covers playlists, smart playlists, podcasts, radio, Last.fm/Spotify/MusicBrainz integrations, and an AI assistant.

### What Is `neo4j/laravel-boost`?

`neo4j/laravel-boost` is a Composer dev-dependency that **merges the official Neo4j MCP server tools directly into the Laravel Boost MCP server**. Once installed:

- Your AI assistant can call `get-schema` to inspect your live Neo4j graph.
- It can run read-only Cypher with `read-cypher` and write queries with `write-cypher`.
- It can traverse your Laravel application's container dependency graph with `get-class-dependency-graph`.
- All of this works through the **same single MCP server** already used by Laravel Boost — no second server entry required.

---

## Architecture Overview

```
AI Client (Cursor / Claude Code)
        │
        ▼  MCP protocol
php artisan boost:mcp          ← single MCP server entry point
        │
        ├── Laravel Boost tools  (routes, code, docs, …)
        │
        └── Neo4j Boost tools    (driver transport, in-process Bolt)
                │
                ▼  Bolt / 7687
           Neo4j 5 Community
           (Docker container)
```

The default transport is `driver` — the package runs Cypher queries in PHP over Bolt via `laudis/neo4j-php-client`. No `neo4j-mcp` binary is required.

---

## Quick Start (Docker — recommended)

### Prerequisites

- Docker & Docker Compose
- PHP 8.3+ and Composer (for local artisan commands / MCP)
- A Composer `auth.json` at `~/.config/composer/auth.json` (may be empty `{}` if no private packages)

### 1. Clone and enter the repo

```bash
git clone https://github.com/Anfwip/Neo4J-Boost-Example.git
cd Neo4J-Boost-Example
```

### 2. Copy the environment file

```bash
cp .env.example .env
```

> The `.env.example` ships with the correct values for Docker Compose (`DB_HOST=database`, `NEO4J_URI=bolt://neo4j:7687`).
> If you run outside Docker, change `database` → `127.0.0.1` and `neo4j` → `localhost`.

### 3. Install PHP dependencies

```bash
composer install --no-interaction
```

### 4. Generate the app key

```bash
php artisan key:generate
```

### 5. Start all containers

```bash
docker compose up -d --build
```

This starts three containers:

| Container | Role |
|-----------|------|
| `koel-app` | Laravel app, PHP 8.4, serves on `http://localhost:8000` |
| `koel-database` | MariaDB 10.11, Koel's relational data |
| `neo4j-boost-example` | Neo4j 5 Community, graph DB, Browser on `http://localhost:7474` |

### 6. Run migrations

```bash
docker compose exec app php artisan migrate --force
```

### 7. Export Koel's container dependency graph into Neo4j

```bash
docker compose exec app php artisan container:graph
```

This introspects **1 008 classes, 249 routes, 1 620 middleware links, and 304 bindings** from Koel and writes them into Neo4j as a navigable graph. Subsequent runs are idempotent.

> **Note:** If executing directly on your host machine outside Docker, set `NEO4J_URI=bolt://localhost:7687` in your `.env` file first.

### 8. Verify the connection

```bash
docker compose exec app php artisan neo4j-boost:doctor --no-interaction
```

Expected output (transport = `driver`, binary = `installed`, password = `set`).

---

## Connecting Your AI Client

### MCP Configuration (all clients)

The MCP server entry is **already written** to `.mcp.json` (for Cursor/VS Code) and `.cursor/mcp.json`. The entry is:

```json
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"],
      "env": {
        "APP_ENV": "local"
      }
    }
  }
}
```

### Cursor

1. Open this repository folder as your workspace in Cursor.
2. Go to **Settings → MCP** and enable the `laravel-boost` server (it auto-discovers `.cursor/mcp.json`).
3. Reload MCP. You should see tools like `get-schema`, `read-cypher`, `write-cypher`, and `get-class-dependency-graph` in the tool list.

To regenerate the Cursor config at any time:

```bash
php artisan neo4j-boost:cursor-config
```

### Claude Code

Add the entry above to your Claude Code MCP config, or run `claude mcp add` pointing to `php artisan boost:mcp`. Open this repo as the workspace so `artisan` is on the path.

---

## Available Neo4j Boost MCP Tools

| Tool | What it does |
|------|-------------|
| `get-schema` | Returns node labels, relationship types, and property keys from your live Neo4j instance |
| `read-cypher` | Runs a read-only Cypher query and returns results |
| `write-cypher` | Runs a write Cypher query (create/merge/delete) |
| `list-gds-procedures` | Lists Graph Data Science procedures (requires GDS plugin) |
| `get-class-dependency-graph` | Returns the dependency sub-graph for a specific Laravel class |
| `contribute-graph-knowledge` | Lets the assistant annotate graph nodes with AI-generated insights |

---

## Test Prompts

Paste these into your MCP-compatible AI client after the stack is running.

### 1 — Inspect the schema

```
Use get-schema to inspect my Neo4j database. Summarize the labels,
relationship types, and important properties. Call out anything that
looks incomplete or surprising.
```

**What to expect:** A structured summary of every node label and relationship type Koel exported. You'll see labels like `:Route`, `:Instance`, `:Middleware`, `:Identifier`, `:Abstract`, and relationship types like `HANDLED_BY`, `DEPENDS_ON`, `USES_MIDDLEWARE`, `BINDS_TO`, `RESOLVES_TO`.

---

### 2 — Count nodes by label

```
Use read-cypher to count nodes for each label in my Neo4j database.
Return a table of label → count, ordered by count descending.
```

**What to expect:** Something like:

| label | count |
|-------|-------|
| Instance | 1008 |
| Identifier | ~900 |
| Route | 249 |
| Middleware | ~80 |

---

### 3 — Explore Koel's route → middleware wiring

```
Use read-cypher to show me which middleware is attached to the most
routes in this Koel app. Return the middleware class name and the
number of routes it applies to, ordered by route count descending.
Limit to 10 results.
```

**Expected Cypher (the assistant writes this):**

```cypher
MATCH (r:Route)-[:USES_MIDDLEWARE]->(m:Middleware)
RETURN m.class AS middleware, count(r) AS routeCount
ORDER BY routeCount DESC
LIMIT 10
```

---

### 4 — Dependency graph for a specific Koel service

```
Use get-class-dependency-graph to show me the dependency tree for
App\Services\SongService with direction "outbound" and depth 3.
Then explain what each dependency is responsible for.
```

**What to expect:** A graph showing `SongService` → repositories → models, with the assistant explaining each node based on class names and the graph structure.

---

### 5 — Write a test node and clean it up

```
Use write-cypher to create a test node:
  CREATE (:TestNode {name: "neo4j-boost-demo", createdAt: datetime()})
Then use read-cypher to confirm it exists.
Finally, use write-cypher to delete it:
  MATCH (n:TestNode {name: "neo4j-boost-demo"}) DELETE n
```

**What to expect:** Confirms the full write → read → delete cycle works end-to-end.

---

### 6 — Full container dependency audit

```
I want to audit the dependency graph for the Koel music app.
Use get-schema to understand the structure, then use read-cypher to:
1. Find the top 5 most-depended-upon services (nodes with the highest
   number of incoming DEPENDS_ON edges).
2. Find any Route that has more than 5 middleware applied.
3. List all bindings (Abstract nodes) and what they resolve to.
Summarize your findings.
```

---

## Artisan Commands Reference

| Command | Description |
|---------|-------------|
| `php artisan neo4j-boost:setup` | Interactive setup — checks connection, optionally installs binary and writes Cursor config |
| `php artisan neo4j-boost:doctor` | Diagnoses transport, binary, password, and connectivity |
| `php artisan neo4j-boost:cursor-config` | Writes or updates `.cursor/mcp.json` |
| `php artisan neo4j-boost:install-mcp` | Downloads the official `neo4j-mcp` binary (only needed for STDIO transport) |
| `php artisan neo4j-boost:start-neo4j` | Starts a local Neo4j Docker container (if not already running) |
| `php artisan container:graph` | Exports Koel's routes, middleware, and container bindings into Neo4j |
| `php artisan container:graph --dry-run` | Shows what would be exported without writing anything |
| `php artisan container:graph --print-cypher` | Prints the generated Cypher statements to stdout |

---

## Project Structure (Neo4j-relevant files)

```
.
├── .env.example          # Includes NEO4J_URI, NEO4J_USERNAME, NEO4J_PASSWORD, NEO4J_MCP_TRANSPORT
├── .env                  # Your local copy (not committed)
├── .mcp.json             # MCP server entry for VS Code / Claude Code
├── .cursor/
│   └── mcp.json          # MCP server entry for Cursor
├── compose.yaml          # Docker Compose: app + mariadb + neo4j services
├── Dockerfile            # PHP 8.4-cli + Node 22 + pnpm + composer
├── composer.json         # neo4j/laravel-boost listed in require-dev
└── vendor/
    └── neo4j/
        └── laravel-boost/ # The installed package
```

---

## How Neo4j Laravel Boost Was Installed

The following steps were taken to add `neo4j/laravel-boost` to this Koel fork. They are documented here so you can repeat or verify the process.

### Step 1 — Fork and clone Koel

```bash
# Fork https://github.com/koel/koel on GitHub (MIT license)
git clone https://github.com/Anfwip/Neo4J-Boost-Example.git
cd Neo4J-Boost-Example
```

### Step 2 — Install the package

```bash
composer require --dev neo4j/laravel-boost
```

This pulls in `neo4j/laravel-boost` and its dependency `laudis/neo4j-php-client` (the PHP Bolt driver). No binary or Node.js dependency is required for the default `driver` transport.

### Step 3 — Add environment variables

Appended to `.env` (and `.env.example`):

```env
NEO4J_URI=bolt://neo4j:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=password
NEO4J_MCP_TRANSPORT=driver
```

The URI host is `neo4j` (the Docker Compose service name). For non-Docker use, change to `localhost`.

### Step 4 — Add Neo4j to Docker Compose

The `compose.yaml` was updated with a `neo4j` service using `neo4j:5-community` and APOC plugins, a health check, and the correct env vars. The `app` service was updated to `depends_on` the `neo4j` service and to pass `NEO4J_*` vars through.

### Step 5 — Configure the MCP server

`.mcp.json` (already created by `laravel/boost`):

```json
{
  "mcpServers": {
    "laravel-boost": {
      "command": "php",
      "args": ["artisan", "boost:mcp"]
    }
  }
}
```

`neo4j/laravel-boost` registers its tools with the same server at runtime — no second entry needed.

### Step 6 — Run the setup verification

```bash
docker compose exec app php artisan neo4j-boost:setup --no-interaction --skip-mcp --no-cursor-config
docker compose exec app php artisan neo4j-boost:doctor --no-interaction
```

### Step 7 — Export the container graph

```bash
docker compose exec app php artisan container:graph
```

Exports 1 008 classes, 304 bindings, 249 routes, 1 620 middleware links from Koel into Neo4j.

---

## Reproducing This Setup From Scratch

If you want to replicate this on another Laravel app:

```bash
# 1. Install the package
composer require --dev neo4j/laravel-boost

# 2. Add env vars to .env
echo '
NEO4J_URI=bolt://localhost:7687
NEO4J_USERNAME=neo4j
NEO4J_PASSWORD=your-password
NEO4J_MCP_TRANSPORT=driver
' >> .env

# 3. Start a local Neo4j instance (if you don't have one)
php artisan neo4j-boost:start-neo4j

# 4. Verify the connection
php artisan neo4j-boost:doctor

# 5. Export your app's dependency graph
php artisan container:graph

# 6. (Optional) Generate Cursor MCP config
php artisan neo4j-boost:cursor-config
```

---

## License

Koel is open-source software licensed under the [MIT License](LICENSE.md).
`neo4j/laravel-boost` is also MIT licensed.
