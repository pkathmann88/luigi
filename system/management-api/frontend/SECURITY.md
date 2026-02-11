# Security Considerations

## Overview

The Luigi Management Frontend uses a **simple, static credential-based authentication system** designed for **local network use only**. This document outlines the security model, known limitations, and recommendations for different deployment scenarios.

## Current Security Model

### Authentication Method

**Static Credentials + HTTP Basic Auth**

1. Credentials stored in `credentials.txt` file (username:password format)
2. Credentials hardcoded in client JavaScript (loaded from credentials.txt during build)
3. Client-side validation against hardcoded credentials
4. Successful login stores credentials in browser localStorage
5. API requests use HTTP Basic Authentication with stored credentials

### What This Provides

✓ Basic access control for trusted users
✓ Protection against casual access
✓ Simple setup with no external dependencies
✓ Works offline/air-gapped environments

### What This Does NOT Provide

✗ Protection against determined attackers
✗ Protection against XSS attacks (localStorage access)
✗ Protection against client-side code inspection
✗ Session management or token refresh
✗ Multi-user or role-based access control
✗ Audit logging of authentication events
✗ Account lockout or brute force protection

## Known Security Limitations

### 1. Client-Side Credential Storage

**Issue:** Credentials are hardcoded in the client JavaScript bundle.

**Risk:** Anyone with access to the frontend can extract credentials by:
- Viewing browser DevTools
- Inspecting JavaScript source
- Reading localStorage

**Mitigation:**
- Use HTTPS to prevent network interception
- Deploy only on trusted local networks
- Use firewall rules to restrict access
- Consider VPN for remote access

### 2. localStorage Vulnerability

**Issue:** Credentials stored in localStorage are accessible to JavaScript.

**Risk:** XSS attacks can steal credentials.

**Mitigation:**
- Keep dependencies updated
- Regular security audits
- Use Content Security Policy (CSP)
- Consider httpOnly cookies for production

### 3. No Server-Side Validation

**Issue:** Credential validation happens entirely client-side.

**Risk:** Attacker can bypass validation by modifying client code.

**Mitigation:**
- Backend API still requires authentication
- Use network-level access controls
- Deploy in controlled environments only

### 4. No Session Management

**Issue:** No session expiration or token refresh mechanism.

**Risk:** Long-lived credentials in localStorage.

**Mitigation:**
- Regular password changes
- Logout when done
- Clear browser data regularly

### 5. Content Security Policy

**Issue:** `'unsafe-inline'` required for Vite-generated scripts.

**Risk:** Reduces XSS protection provided by CSP.

**Mitigation:**
- Use nonce-based CSP in production
- Implement strict CSP directives
- Regular dependency updates

## Recommended Security Practices

### For Home/Lab Environments

✓ Change default password immediately
✓ Use strong, unique password
✓ Enable firewall on Raspberry Pi
✓ Use HTTPS (even with self-signed certificate)
✓ Keep system and dependencies updated
✓ Logout after each session

### For Local Network Deployment

✓ All of the above, plus:
✓ Use IP-based access restrictions
✓ Implement network segmentation
✓ Enable audit logging on backend
✓ Regular security monitoring
✓ Document authorized users

### For Production Deployments

⚠️ **DO NOT use this authentication system for production!**

Instead, implement:
- Server-side authentication service
- OAuth 2.0 / OpenID Connect providers
- JWT tokens with refresh mechanism
- httpOnly, secure cookies
- Multi-factor authentication (MFA)
- Role-based access control (RBAC)
- Session management and expiration
- Audit logging and monitoring
- Rate limiting on authentication
- Account lockout policies

## Deployment Scenarios

### ✅ Suitable For:

1. **Personal Raspberry Pi Projects**
   - Single-user home automation
   - Personal IoT dashboard
   - Learning and experimentation

2. **Home Lab Environments**
   - Local network only
   - Trusted users
   - No internet exposure

3. **Development and Testing**
   - Quick prototyping
   - Internal development
   - Non-production testing

### ❌ NOT Suitable For:

1. **Internet-Facing Deployments**
   - Public web hosting
   - Cloud deployments
   - Any internet-accessible service

2. **Multi-User Environments**
   - Shared hosting
   - Multiple tenants
   - Different permission levels

3. **High-Security Requirements**
   - Sensitive data handling
   - Compliance requirements (HIPAA, PCI-DSS, etc.)
   - Corporate/enterprise use

## Security Checklist

Before deployment, verify:

- [ ] Changed default credentials
- [ ] Using strong, unique password
- [ ] HTTPS enabled with valid certificates
- [ ] Firewall configured (allow only necessary ports)
- [ ] IP whitelist configured in backend
- [ ] Network isolated from internet (or behind VPN)
- [ ] Regular backup of credentials file
- [ ] System updates automated
- [ ] Audit logging enabled on backend
- [ ] Monitoring in place
- [ ] Documentation of security model
- [ ] Users trained on logout procedure

## Upgrading Authentication

If you need better security, consider these upgrades:

### Option 1: Add Backend Authentication Endpoint

1. Create `/api/auth/login` endpoint on backend
2. Validate credentials server-side
3. Return session token (JWT)
4. Store token in httpOnly cookie
5. Validate token on all API requests

### Option 2: Integrate External Auth Provider

1. Add OAuth 2.0 provider (Google, GitHub, etc.)
2. Implement OIDC flow in frontend
3. Backend validates OAuth tokens
4. Use provider's user management

### Option 3: Implement Full Auth System

1. Add user database to backend
2. Hash passwords (bcrypt, Argon2)
3. Session management with Redis
4. JWT with refresh tokens
5. MFA support
6. RBAC implementation

## Reporting Security Issues

If you discover a security vulnerability:

1. **Do not** open a public GitHub issue
2. Email the maintainer directly
3. Provide detailed description
4. Include steps to reproduce
5. Allow time for fix before disclosure

## References

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Web Security Cheat Sheet](https://cheatsheetseries.owasp.org/)
- [localStorage Security](https://owasp.org/www-community/vulnerabilities/DOM_Based_XSS)
- [HTTP Basic Auth RFC](https://tools.ietf.org/html/rfc7617)

## Conclusion

This authentication system prioritizes **simplicity and ease of use** over security. It is appropriate for home/lab environments with trusted users on isolated networks, but should **never be used for production, internet-facing, or high-security deployments**.

For production use, implement proper server-side authentication with industry-standard security practices.
