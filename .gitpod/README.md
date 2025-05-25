# Gitpod Configuration Directory

This directory contains the organized Gitpod configuration files for the Lago development environment. The configuration has been refactored to be modular and maintainable.

## Directory Structure

```
.gitpod/
├── tasks/              # Task scripts for different operations
│   ├── prebuild.sh     # Prebuild initialization (NO Docker commands)
│   ├── startup.sh      # Runtime startup with Docker initialization
│   ├── logs.sh         # View container logs
│   ├── status.sh       # Check container status and health
│   ├── restart.sh      # Restart all services
│   ├── test.sh         # Run tests
│   └── db-reset.sh     # Reset database
├── extensions/         # IDE extension configurations
│   ├── vscode.yml      # VS Code extensions
│   ├── jetbrains.yml   # JetBrains IntelliJ plugins
│   └── load-extensions.py  # Extension loader utility
├── env/               # Environment setup scripts
└── README.md          # This file
```

## Key Features

### 🔧 **Modular Task Scripts**
- Each task is a separate, executable script
- Clear separation between prebuild and runtime operations
- Consistent error handling and environment setup

### 🎯 **Clean Main Configuration**
- `.gitpod.yml` reduced from **265 lines** to **189 lines**
- All complex logic moved to separate scripts
- Easy to read and maintain

### 🛡️ **Prebuild Safety**
- `prebuild.sh` contains NO Docker commands
- Only file creation and environment setup
- Safe for workspace image creation

### ⚡ **Runtime Efficiency**
- `startup.sh` uses the robust `lago_health_check.sh` script
- Fast-fail detection for missing services
- Comprehensive health validation

## Usage

### Running Individual Tasks
```bash
# Check status
bash .gitpod/tasks/status.sh

# View logs
bash .gitpod/tasks/logs.sh

# Restart services
bash .gitpod/tasks/restart.sh

# Run tests
bash .gitpod/tasks/test.sh

# Reset database
bash .gitpod/tasks/db-reset.sh
```

### Extension Management
```bash
# Verify extension configurations
python3 .gitpod/extensions/load-extensions.py
```

## Environment Variables

All scripts properly handle:
- `LAGO_PATH="/workspace/lago"`
- `GITPOD_WORKSPACE_ID` and `GITPOD_WORKSPACE_CLUSTER_HOST`
- Docker environment variables
- Gitpod environment variables via `gp env -e`

## Maintenance

When adding new tasks:
1. Create a new script in `.gitpod/tasks/`
2. Make it executable: `chmod +x .gitpod/tasks/new-script.sh`
3. Add the task to `.gitpod.yml` tasks section
4. Follow the existing pattern for error handling and environment setup

When modifying extensions:
1. Edit `.gitpod/extensions/vscode.yml` for VS Code extensions
2. Edit `.gitpod/extensions/jetbrains.yml` for JetBrains plugins
3. The main `.gitpod.yml` will automatically include them

## Migration Notes

The original `.gitpod.yml` has been backed up as `.gitpod.yml.deprecated`. All functionality has been preserved while improving organization and maintainability.

# Lago Gitpod Development Environment

## 🚀 Features

### 1. Instant Development Environment
- **Prebuilt Workspaces**: Start coding in seconds with prebuilt environments
- **Automatic Setup**: Environment variables, Docker, and dependencies are automatically configured
- **Port Forwarding**: Automatic port forwarding with descriptive names and previews

### 2. Development Tools
- **VS Code Extensions**:
  - ESLint & Prettier for code quality
  - Docker integration
  - TypeScript support
  - Ruby LSP
  - GitHub Copilot
  - YAML support

### 3. Common Development Tasks
```bash
# Start the development environment
docker compose up -d

# View logs
docker compose logs -f

# Run tests
docker compose run --rm api bundle exec rspec

# Reset database
docker compose run --rm api bundle exec rails db:reset
```

### 4. Browser Integration
- **Automatic Previews**: Open previews in your browser automatically
- **Port Forwarding**: Access services through descriptive URLs
- **External Browser Support**: Configure to open in external browser

### 5. Environment Management
- **Environment Variables**: Automatically configured
- **Docker Integration**: Full Docker support with socket access
- **Database Management**: Easy database operations

## 🔧 Configuration

The development environment is configured through:
- `.gitpod.yml`: Main configuration file
- `.gitpod.Dockerfile`: Base image configuration
- `.gitpod.docker-init.sh`: Docker initialization script

## 🎯 Best Practices

1. **Workspace Management**:
   - Use prebuilds for faster startup
   - Take advantage of workspace snapshots
   - Use the provided VS Code extensions

2. **Development Workflow**:
   - Start with `docker compose up -d`
   - Use the provided commands for common tasks
   - Take advantage of automatic port forwarding

3. **Troubleshooting**:
   - Check logs with `docker compose logs -f`
   - Reset environment if needed
   - Use workspace snapshots for state recovery

## 🔍 Additional Resources

- [Gitpod Documentation](https://www.gitpod.io/docs)
- [Lago Documentation](https://doc.getlago.com)
- [VS Code Extensions](https://code.visualstudio.com/docs/editor/extension-marketplace) 