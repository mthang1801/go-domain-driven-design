# Security Check Prompt

Use this prompt before committing code or reviewing PRs for security.

## Usage

```
@.claude/prompts/security-check.md

Security check for [file/module/PR]
```

## Prompt Template

---

**Target**: [Files or changes to review]

**Security Checklist**:

### Authentication & Authorization
- [ ] Auth required for protected endpoints
- [ ] Role-based access control implemented
- [ ] Token validation on all requests
- [ ] Session management secure

### Input Validation
- [ ] All user inputs validated
- [ ] DTOs use class-validator decorators
- [ ] File uploads validated (type, size)
- [ ] Query parameters sanitized

### Injection Prevention
- [ ] SQL: Parameterized queries only
- [ ] NoSQL: Input sanitization
- [ ] Command injection: No shell commands with user input
- [ ] XSS: Output encoding

### Secrets & Configuration
- [ ] No hardcoded secrets
- [ ] Environment variables used
- [ ] Secrets not logged
- [ ] Config validation on startup

### Data Protection
- [ ] Sensitive data encrypted
- [ ] PII handled correctly
- [ ] Passwords hashed (bcrypt)
- [ ] Error messages don't leak info

### Dependencies
- [ ] No known vulnerabilities
- [ ] Dependencies up to date
- [ ] Licenses compatible

**Output Format**:
- 🔴 **CRITICAL**: Security vulnerability - must fix immediately
- 🟠 **HIGH**: Security risk - fix before production
- 🟡 **MEDIUM**: Security concern - should address
- 🔵 **INFO**: Security suggestion

---

## Example

```
@.claude/prompts/security-check.md
@.claude/agents/security-reviewer.md

Security review for PR #123 adding user registration feature
Focus on: password handling, input validation, rate limiting
```
