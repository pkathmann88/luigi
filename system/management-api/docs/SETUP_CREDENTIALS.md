# Setup Script Credential Handling Update

## Summary

The management-api setup script (`setup.sh`) has been updated to **not prompt for credentials** during build or installation. Instead, default credentials are used and can be changed after installation via the configuration file.

## Changes

### Previous Behavior

- Setup script prompted for username and password during build/install
- Credentials were stored in both frontend build-time environment and backend .env
- Changing credentials required rebuilding the frontend

### New Behavior

- No credential prompts during build/install
- Default credentials used: `admin` / `changeme123`
- Credentials can be changed after installation without frontend rebuild
- Frontend validates credentials via backend API (no hardcoded credentials)

## Installation Process

### 1. Build/Install (No Prompts)

```bash
# Build in place
cd system/management-api
sudo ./setup.sh build

# Or full install
sudo ./setup.sh install
```

The script will:
- Use default credentials automatically
- Display warning about changing defaults
- Build frontend without requiring credentials
- Create backend .env with default credentials

### 2. Change Credentials After Installation

**Recommended: Change default credentials immediately after installation!**

```bash
# Edit the configuration file
sudo nano /etc/luigi/system/management-api/.env

# Update these lines:
AUTH_USERNAME=your_username
AUTH_PASSWORD=your_strong_password

# Save and exit (Ctrl+X, Y, Enter)

# Restart the service
sudo systemctl restart management-api
```

**Note:** No frontend rebuild required! The frontend validates credentials via backend API.

## Default Credentials

**Username:** `admin`  
**Password:** `changeme123`

**⚠️ SECURITY WARNING:** These are default credentials visible in documentation. Change them immediately after installation!

## Technical Details

### Backend Configuration

The backend reads credentials from `/etc/luigi/system/management-api/.env`:

```bash
AUTH_USERNAME=admin
AUTH_PASSWORD=changeme123
```

The backend validates every API request using these credentials via HTTP Basic Authentication.

### Frontend Configuration

The frontend **no longer** has hardcoded credentials. Instead:

1. User enters credentials in login form
2. Frontend stores credentials in localStorage
3. Frontend makes authenticated API call (e.g., GET /api/system/status)
4. Backend validates credentials via HTTP Basic Auth
5. Success (200) → Navigate to dashboard
6. Failure (401) → Show error, clear stored credentials

This means credentials can be changed on the backend without rebuilding the frontend.

### setup.sh Changes

**Modified functions:**

1. **`generate_backend_env()`**
   - No longer requires `AUTH_USERNAME`/`AUTH_PASSWORD` to be set
   - Uses defaults if not provided
   - Displays warning when using defaults

2. **`build_frontend_in_source()`**
   - Removed credential requirement check
   - Frontend build doesn't need credentials

3. **`build()`**
   - Removed `prompt_credentials()` call
   - Added informational message about defaults

4. **`.env.example`**
   - Updated documentation
   - Clear instructions for changing credentials

5. **Install success message**
   - Shows default credentials
   - Provides instructions for changing credentials
   - Emphasizes security importance

## Migration from Previous Version

If you have an existing installation with custom credentials:

1. Your existing credentials in `/etc/luigi/system/management-api/.env` are preserved
2. No action needed - existing credentials continue to work
3. Frontend doesn't need rebuild (already updated to validate via backend)

## Security Considerations

### Why Default Credentials?

1. **Simplicity**: No interactive prompts during automated deployments
2. **Flexibility**: Credentials can be changed anytime after installation
3. **No Frontend Rebuild**: Credentials are backend-only configuration

### Security Best Practices

1. **Change Defaults Immediately**: Default credentials are documented and insecure
2. **Use Strong Passwords**: Minimum 12 characters recommended
3. **Regular Rotation**: Change credentials periodically
4. **Audit Logs**: Check `/var/log/luigi/audit.log` for authentication attempts
5. **HTTPS Only**: Always use HTTPS in production (enabled by default)

## Troubleshooting

### Can't Login After Installation

**Symptom:** Login fails with "Invalid username or password"

**Solution:**
1. Check backend .env: `sudo cat /etc/luigi/system/management-api/.env`
2. Verify credentials match what you're entering
3. Check service is running: `sudo systemctl status management-api`
4. Check logs: `sudo journalctl -u management-api -f`

### Changed Credentials But Login Still Fails

**Solution:**
1. Verify you edited the correct file: `/etc/luigi/system/management-api/.env`
2. Ensure no typos or extra spaces in credentials
3. Restart the service: `sudo systemctl restart management-api`
4. Clear browser localStorage (Application tab in DevTools)

### Want to Use Custom Credentials During Install

**Solution:**
Set environment variables before running setup:

```bash
export AUTH_USERNAME="myuser"
export AUTH_PASSWORD="mypassword"
sudo -E ./setup.sh install
```

The script will use these instead of defaults.

## Related Documentation

- [Credential Validation Removal](./CREDENTIAL_VALIDATION_REMOVAL.md) - Why frontend no longer validates credentials
- [API Documentation](./API.md) - Authentication flow and API reference
- [README.md](../README.md) - Main management-api documentation

## Summary

The setup script now provides a smoother installation experience without credential prompts. Default credentials are used initially and can be easily changed after installation without requiring a frontend rebuild. This improves both usability and security by allowing credentials to be managed independently of the build process.
