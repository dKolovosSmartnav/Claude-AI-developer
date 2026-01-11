# Global Project Context

This context applies to ALL projects processed by Claude.

## Server Environment

- **Operating System**: Ubuntu 24.04 LTS
- **Web Server**: OpenLiteSpeed
- **PHP Versions**: LSPHP 8.3 (default), LSPHP 8.4
- **Node.js**: v22.x
- **Java**: GraalVM 24

## Ports

| Service | Port | Protocol |
|---------|------|----------|
| Admin Panel | 9453 | HTTPS |
| Web Projects | 9867 | HTTPS |
| MySQL | 3306 | TCP (localhost only) |
| OLS WebAdmin | 7080 | HTTPS |
| SSH | 22, 9966 | TCP |

## File Locations

- **PHP Projects**: `/var/www/projects/[project-code]/`
- **App Projects**: `/opt/apps/[project-code]/`
- **OLS Config**: `/usr/local/lsws/conf/`
- **PHP Binary**: `/usr/local/lsws/lsphp83/bin/php` or `/usr/local/lsws/lsphp84/bin/php`

## Installed Tools

### System
- Git
- curl, wget
- OpenSSL

### Databases
- MySQL 8.0 (server and client)

### PHP
- LSPHP 8.3 with extensions: mysql, curl, intl, opcache, redis, imagick
- LSPHP 8.4 with extensions: mysql, curl, intl, opcache, redis, imagick
- Composer (if installed separately - check with `which composer`)

### JavaScript
- Node.js 22.x
- npm (comes with Node.js)

### Python
- Python 3 with pip
- Flask, Flask-SocketIO, Flask-CORS
- mysql-connector-python
- bcrypt, eventlet
- Playwright (Python) with Chromium browser

### Java
- GraalVM 24 (JAVA_HOME=/opt/graalvm)
- java, javac available in PATH

## Testing Tools

- **Playwright (Python)**: Already installed with Chromium
  - Use: `from playwright.sync_api import sync_playwright`
  - Browser path: Managed by Playwright
  - To run headless tests, no additional installation needed

## AI Behavior Guidelines

### Ask Questions Before Starting
If the task description is unclear or has multiple possible interpretations:
1. **Ask clarifying questions** before writing any code
2. List what you understand and what you need to know
3. Wait for user response before proceeding
4. This saves time and produces better results

Example: "Before I start, I'd like to clarify a few things: 1) Should the form include email validation? 2) Do you want the data saved to the database or just displayed?"

### Visual Verification with Playwright
You have Playwright with Chromium available for visual testing. **USE IT** when:
1. User says something "doesn't look right" or "isn't displaying correctly"
2. User mentions layout, styling, or visual issues
3. You need to verify your changes visually
4. User explicitly asks you to "see" or "check" the page

**How to use Playwright for screenshots:**
```python
from playwright.sync_api import sync_playwright

with sync_playwright() as p:
    browser = p.chromium.launch(headless=True)
    page = browser.new_page(viewport={'width': 1280, 'height': 720})
    page.goto('https://localhost:9867/project-path/')
    page.screenshot(path='/tmp/screenshot.png')
    browser.close()
```

Then read the screenshot to see what the user sees. This helps you:
- Understand visual bugs without asking the user to describe them
- Verify your CSS/layout changes work correctly
- See exactly what the user is experiencing

### When User Says "It Doesn't Look Right"
1. **Take a screenshot first** with Playwright
2. Analyze the visual issue
3. Fix and take another screenshot to verify
4. Don't ask the user to describe what's wrong - see it yourself

## Important Rules

1. **Check before installing**: Most tools are already installed. Always verify with `which [tool]` or `[tool] --version` before attempting installation
2. **Do NOT run `apt-get install`** for packages that are already installed
3. **PHP version**: Default is 8.3, use 8.4 only if specifically requested
4. **Project isolation**: Each project has its own directory and optionally its own MySQL database
5. SSL certificates are managed by Let's Encrypt or self-signed - do not modify SSL config

## Database Access

Each project may have its own MySQL database. Credentials are provided in the PROJECT DATABASE section.
To connect: `mysql -h [host] -u [user] -p[password] [database]`

## Quick Checks

```bash
# Check Node.js
node --version

# Check PHP
/usr/local/lsws/lsphp83/bin/php --version

# Check Java
java --version

# Check Playwright
python3 -c "from playwright.sync_api import sync_playwright; print('Playwright OK')"

# Check MySQL
mysql --version
```
