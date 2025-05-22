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