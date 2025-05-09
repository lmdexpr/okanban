# OKanban
Simple Kanban app written in OCaml

## Requirements
- OCaml 5.3
- Dream 
- ReScript
- React

## Features
- Kanban board with drag-and-drop functionality
- Reminder using webhook

## Project Structure
```
okanban/
├── bin/                # OCaml executable
├── lib/                # OCaml library code
├── client/             # ReScript/React frontend
├── public/             # Static assets
├── dune-project        # Dune configuration
├── flake.nix           # Nix flake configuration
└── shell.nix           # Nix shell configuration
```

## Setup and Running

### Using Nix (Recommended)

If you have Nix with flakes enabled:

1. Enter the development shell:
```
nix develop
```

2. Build and run the application:
```
dune build
cd client && npm install
cd client && npm run build
cd client && npm run webpack
dune exec okanban
```

Alternatively, you can build and run in one step:
```
nix run
```

If you have direnv installed, you can simply run:
```
direnv allow
```

### Manual Setup (without Nix)

#### Backend (OCaml)
1. Install OCaml dependencies:
```
opam install . --deps-only
```

2. Build the project:
```
dune build
```

#### Frontend (ReScript/React)
1. Navigate to the client directory:
```
cd client
```

2. Install npm dependencies:
```
npm install
```

3. Build the ReScript code:
```
npm run build
```

4. Build the webpack bundle:
```
npm run webpack
```

#### Running the Application
Start the server:
```
dune exec okanban
```

Then open your browser to http://localhost:8080

## Development
For development, you can run these commands:

### With Nix
```
nix develop
```

### Without Nix
1. Watch OCaml changes:
```
dune build --watch
```

2. Watch ReScript changes:
```
cd client && npm start
```

3. Watch webpack changes:
```
cd client && npm run webpack:dev
```

## Webhook Reminders
The application supports setting reminders via webhooks. When a card's due date is reached, the system will send a POST request to the specified webhook URL with the card data in JSON format.
